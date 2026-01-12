import { FormExtensionAbility, formBindingData, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import dataPreferences from '@ohos.data.preferences';
import { BusinessError } from '@kit.BasicServicesKit';

const DATA_PREFERENCES_NAME = 'WidgetDataPrefs';
const WIDGET_DATA_KEY = 'current_day_courses';
const FORM_IDS_KEY = 'active_form_ids';

export default class EntryFormAbility extends FormExtensionAbility {

  onAddForm(want: Want): formBindingData.FormBindingData {
    let formId = want.parameters![formInfo.FormParam.IDENTITY_KEY] as string;
    console.info(`[EntryFormAbility] onAddForm: ${formId}`);

    // 1. 启动异步任务：存 ID + 读取数据刷新
    // 这是一个 Fire-and-Forget 调用，不需要 await
    this.initFormAsync(formId);

    // 2. 必须立刻返回一个默认数据，防止卡死
    // 这里返回空数据，UI 侧会显示我们在 Widget2x2 里定义的默认值或 EmptyView
    class FormData {
      widgetDataString: string = '';
      currentTime: string = '00:00';
    }
    let data = new FormData();
    return formBindingData.createFormBindingData(data);
  }

  onRemoveForm(formId: string) {
    console.info(`[EntryFormAbility] onRemoveForm: ${formId}`);
    // 异步移除 ID
    this.removeFormId(formId);
  }

  onCastToNormalForm(formId: string) {
  }

  onUpdateForm(formId: string) {
    console.info(`[EntryFormAbility] onUpdateForm: ${formId}`);
    this.updateForm(formId);
  }

  // --- 异步逻辑封装 ---

  // 专门处理 onAddForm 的后续异步操作
  async initFormAsync(formId: string) {
    // A. 保存 ID
    await this.addFormId(formId);
    // B. 读取 Preferences 并刷新卡片
    await this.updateForm(formId);
  }

  // 保存新的 Form ID
  async addFormId(formId: string) {
    try {
      let preferences = await dataPreferences.getPreferences(this.context, DATA_PREFERENCES_NAME);
      let ids = await preferences.get(FORM_IDS_KEY, []) as Array<string>;

      if (!ids.includes(formId)) {
        ids.push(formId);
        await preferences.put(FORM_IDS_KEY, ids);
        await preferences.flush();
        console.info(`[EntryFormAbility] Saved new formId: ${formId}`);
      }
    } catch (err) {
      console.error(`[EntryFormAbility] Failed to save formId: ${JSON.stringify(err)}`);
    }
  }

  // 移除 Form ID
  async removeFormId(formId: string) {
    try {
      let preferences = await dataPreferences.getPreferences(this.context, DATA_PREFERENCES_NAME);
      let ids = await preferences.get(FORM_IDS_KEY, []) as Array<string>;

      const index = ids.indexOf(formId);
      if (index > -1) {
        ids.splice(index, 1);
        await preferences.put(FORM_IDS_KEY, ids);
        await preferences.flush();
        console.info(`[EntryFormAbility] Removed formId: ${formId}`);
      }
    } catch (err) {
      console.error(`[EntryFormAbility] Failed to remove formId: ${JSON.stringify(err)}`);
    }
  }

  // 获取最新数据 (供 updateForm 使用)
  async getLatestFormData(): Promise<formBindingData.FormBindingData> {
    try {
      let preferences = await dataPreferences.getPreferences(this.context, DATA_PREFERENCES_NAME);
      let jsonStr = await preferences.get(WIDGET_DATA_KEY, '') as string;

      let currentTime = this.getCurrentTimeStr();

      class FormData {
        widgetDataString: string = '';
        currentTime: string = '00:00';
      }

      let data = new FormData();
      data.widgetDataString = jsonStr;
      data.currentTime = currentTime;

      return formBindingData.createFormBindingData(data);

    } catch (err) {
      console.error(`[EntryFormAbility] Failed to get preferences: ${JSON.stringify(err)}`);
      return formBindingData.createFormBindingData({});
    }
  }

  // 主动推送刷新
  async updateForm(formId: string) {
    let bindingData = await this.getLatestFormData();
    formProvider.updateForm(formId, bindingData).catch((err: BusinessError) => {
      console.error(`[EntryFormAbility] updateForm failed: ${JSON.stringify(err)}`);
    });
  }

  private getCurrentTimeStr(): string {
    const now = new Date();
    const hours = now.getHours().toString().padStart(2, '0');
    const minutes = now.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }
};