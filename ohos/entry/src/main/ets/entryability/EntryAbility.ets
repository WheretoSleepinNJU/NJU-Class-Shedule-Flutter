import { FlutterAbility, FlutterEngine, MethodCall, MethodChannel, MethodResult } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import { BusinessError } from '@kit.BasicServicesKit';
import dataPreferences from '@ohos.data.preferences';
import { formBindingData, formProvider, formInfo } from '@kit.FormKit'; // 确保引入 formInfo
import { MOCK_DATA } from '../widget/mock/MockData';
import { TodayWidgetData } from '../widget/models/WidgetDataModel';

const DATA_PREFERENCES_NAME = 'WidgetDataPrefs';
const WIDGET_DATA_KEY = 'current_day_courses';
const FORM_IDS_KEY = 'active_form_ids';
const CHANNEL_NAME = 'wheretosleepinnju/widget';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)

    this.setupWidgetChannel(flutterEngine)
  }

  private setupWidgetChannel(flutterEngine: FlutterEngine) {
    const messenger = flutterEngine.dartExecutor.getBinaryMessenger();
    const channel = new MethodChannel(messenger, CHANNEL_NAME);

    channel.setMethodCallHandler({
      onMethodCall: (call: MethodCall, result: MethodResult): void => {
        this.handleWidgetUpdate(call, result);
      }
    });
  }

  private async handleWidgetUpdate(call: MethodCall, result: MethodResult) {
    if (call.method === 'updateWidget') {
      const jsonStr = call.args as string;
      console.info(`[EntryAbility] Received widget data length: ${jsonStr.length}`);

      try {
        await this.saveDataToPreferences(jsonStr);
        await this.refreshAllWidgets(jsonStr);
        result.success(true);
      } catch (err) {
        console.error(`[EntryAbility] Update failed: ${JSON.stringify(err)}`);
        // JSON.stringify(err) 确保传递给 Flutter 的是字符串
        result.error('UPDATE_ERROR', JSON.stringify(err), null);
      }
    } else {
      result.notImplemented();
    }
  }

  private async saveDataToPreferences(jsonStr: string) {
    try {
      let preferences = await dataPreferences.getPreferences(this.context, DATA_PREFERENCES_NAME);
      await preferences.put(WIDGET_DATA_KEY, jsonStr);
      await preferences.flush();
      console.info('[EntryAbility] Data saved to preferences.');
    } catch (err) {
      console.error(`[EntryAbility] Save prefs failed: ${err}`);
    }
  }

  private async refreshAllWidgets(jsonStr: string) {
    try {
      const currentTime = this.getCurrentTimeStr();

      let rawData: TodayWidgetData = JSON.parse(jsonStr);

      let formData = formBindingData.createFormBindingData({
        'widgetData': rawData,
        'currentTime': currentTime
      });

      // 读取 EntryFormAbility 保存的 active_form_ids
      let preferences = await dataPreferences.getPreferences(this.context, DATA_PREFERENCES_NAME);
      let formIds = await preferences.get(FORM_IDS_KEY, []) as Array<string>;

      console.info(`[EntryAbility] Updating ${formIds.length} active widgets...`);

      // 遍历 ID 进行更新
      for (const formId of formIds) {
        formProvider.updateForm(formId, formData).catch((err: BusinessError) => {
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