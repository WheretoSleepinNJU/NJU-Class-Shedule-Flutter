import { HdsChromeBridge } from '../adaptive/HdsChromeBridge';
import { FlutterAbility, FlutterEngine, FlutterShellArgs, MethodCall, MethodChannel, MethodResult } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import { BusinessError } from '@kit.BasicServicesKit';
import dataPreferences from '@ohos.data.preferences';
import { formBindingData, formProvider, formInfo } from '@kit.FormKit'; // 确保引入 formInfo
import { MOCK_DATA } from '../widget/mock/MockData';
import { TodayWidgetData } from '../widget/models/WidgetDataModel';
import { DEFAULT_WIDGET_DATA, WidgetFormData, DATA_PREFERENCES_NAME, WIDGET_DATA_KEY, FORM_IDS_KEY, CHANNEL_NAME } from '../widget/models/FormData';


export default class EntryAbility extends FlutterAbility {
  private widgetUpdateQueue: Promise<void> = Promise.resolve();

  getFlutterShellArgs(): FlutterShellArgs {
    const args = super.getFlutterShellArgs();
    // Keep the UI isolate on its own engine thread to avoid the startup stack
    // overflow observed with Flutter 3.35's merged platform/UI thread.
    args.add('--no-enable-merged-platform-ui-thread');
    return args;
  }

  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)

    HdsChromeBridge.shared.attach(flutterEngine, this.context);
    this.setupWidgetChannel(flutterEngine)
  }

  cleanUpFlutterEngine(flutterEngine: FlutterEngine): void {
    HdsChromeBridge.shared.detachEngine(flutterEngine);
    super.cleanUpFlutterEngine(flutterEngine);
  }

  onForeground(): void {
    super.onForeground();
    HdsChromeBridge.shared.setResumed(true);
  }

  onBackground(): void {
    HdsChromeBridge.shared.setResumed(false);
    super.onBackground();
  }

  private setupWidgetChannel(flutterEngine: FlutterEngine) {
    const messenger = flutterEngine.dartExecutor.getBinaryMessenger();
    const channel = new MethodChannel(messenger, CHANNEL_NAME);

    channel.setMethodCallHandler({
      onMethodCall: (call: MethodCall, result: MethodResult): void => {
        this.widgetUpdateQueue = this.widgetUpdateQueue.then((): Promise<void> => this.handleWidgetUpdate(call, result));
      }
    });
  }

  private async handleWidgetUpdate(call: MethodCall, result: MethodResult): Promise<void> {
    if (call.method === 'updateWidget') {
      const jsonStr = call.args as string;
      console.info(`[EntryAbility] Received widget data length: ${jsonStr.length}`);

      try {
        await this.saveDataToPreferences(jsonStr);
        await this.refreshAllWidgets(jsonStr);
        result.success(true);
      } catch (err) {
        console.error(`[EntryAbility] Update failed: ${JSON.stringify(err)}`);
        result.error('UPDATE_ERROR', JSON.stringify(err), null);
      }
    } else {
      result.notImplemented();
    }
  }

  private async saveDataToPreferences(jsonStr: string) {
    try {
      // The form extension writes active IDs in a separate process. Reload
      // before writing so this process cannot flush an old cached ID list.
      await dataPreferences.removePreferencesFromCache(this.context, DATA_PREFERENCES_NAME);
      let preferences = await dataPreferences.getPreferences(this.context, DATA_PREFERENCES_NAME);
      await preferences.put(WIDGET_DATA_KEY, jsonStr);
      await preferences.flush();
      console.info('[EntryAbility] Data saved to preferences.');
    } catch (err) {
      console.error(`[EntryAbility] Save prefs failed: ${err}`);
    }
  }

  // 【核心修改】这里需要使用 WidgetFormData 类
  private async refreshAllWidgets(jsonStr: string) {
    try {
      const currentTime = this.getCurrentTimeStr();
      let rawData: TodayWidgetData;

      try {
        // 1. 解析 JSON 并强制转换为 TodayWidgetData 类型
        rawData = JSON.parse(jsonStr) as TodayWidgetData;
      } catch (e) {
        console.error(`[EntryAbility] JSON parse error, using default.`);
        rawData = DEFAULT_WIDGET_DATA;
      }

      // 2. 【关键】使用 new WidgetFormData(...) 代替原来的 {} 对象字面量
      // 这样就消除了 arkts-no-untyped-obj-literals 报错
      let formBindingObj = new WidgetFormData(rawData, currentTime);

      let formData = formBindingData.createFormBindingData(formBindingObj);

      await dataPreferences.removePreferencesFromCache(this.context, DATA_PREFERENCES_NAME);
      let preferences = await dataPreferences.getPreferences(this.context, DATA_PREFERENCES_NAME);
      let formIds = await preferences.get(FORM_IDS_KEY, []) as Array<string>;

      console.info(`[EntryAbility] Updating ${formIds.length} active widgets...`);

      for (const formId of formIds) {
        formProvider.updateForm(formId, formData).then(() => {
          // Re-arm existing cards when the selected timetable or its times change.
          return formProvider.setFormNextRefreshTime(formId, 5);
        }).catch((err: BusinessError) => {
          console.error(`[EntryAbility] Failed to update form ${formId}: ${err.code}`);
        });
      }
    } catch (err) {
      console.error(`[EntryAbility] refreshAllWidgets failed: ${JSON.stringify(err)}`);
    }
  }

  private getCurrentTimeStr(): string {
    const now = new Date();
    const hours = now.getHours().toString().padStart(2, '0');
    const minutes = now.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }
}
