import { FormExtensionAbility, formBindingData, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import dataPreferences from '@ohos.data.preferences';
import { BusinessError } from '@kit.BasicServicesKit';
import { DEFAULT_WIDGET_DATA, WidgetFormData, DATA_PREFERENCES_NAME, WIDGET_DATA_KEY, FORM_IDS_KEY } from '../widget/models/FormData';
import { TodayWidgetData } from '../widget/models/WidgetDataModel';

export default class EntryFormAbility extends FormExtensionAbility {

  onAddForm(want: Want): formBindingData.FormBindingData {
    let formId = want.parameters![formInfo.FormParam.IDENTITY_KEY] as string;
    console.info(`[EntryFormAbility] onAddForm: ${formId}`);

    this.initFormAsync(formId);

    // 【修复 3】使用强类型的类实例
    let formData = new WidgetFormData(DEFAULT_WIDGET_DATA, '00:00');
    return formBindingData.createFormBindingData(formData);
  }

  onRemoveForm(formId: string) {
    console.info(`[EntryFormAbility] onRemoveForm: ${formId}`);
    this.removeFormId(formId);
  }

  onCastToNormalForm(formId: string) {
  }

  onUpdateForm(formId: string) {
    console.info(`[EntryFormAbility] onUpdateForm: ${formId}`);
    this.updateForm(formId);
  }

  // --- 异步逻辑 ---

  async initFormAsync(formId: string) {
    await this.addFormId(formId);
    await this.updateForm(formId);
  }

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

  // 【核心修改】获取并解析数据
  async getLatestFormData(): Promise<formBindingData.FormBindingData> {
    try {
      let preferences = await dataPreferences.getPreferences(this.context, DATA_PREFERENCES_NAME);
      let jsonStr = await preferences.get(WIDGET_DATA_KEY, '') as string;
      let currentTime = this.getCurrentTimeStr();

      // 【修复 4】初始化为默认对象，而不是 {}
      let parsedWidgetData: TodayWidgetData = DEFAULT_WIDGET_DATA;

      if (jsonStr && jsonStr.length > 0) {
        try {
          // 【修复 5】JSON.parse 需要断言类型
          parsedWidgetData = JSON.parse(jsonStr) as TodayWidgetData;
        } catch (e) {
          console.error(`[EntryFormAbility] JSON parse failed`);
        }
      }

      // 【修复 6】使用类构建数据
      let dataObj = new WidgetFormData(parsedWidgetData, currentTime);

      return formBindingData.createFormBindingData(dataObj);

    } catch (err) {
      console.error(`[EntryFormAbility] Failed to get preferences: ${JSON.stringify(err)}`);
      // 出错时也返回符合结构的默认数据
      let errData = new WidgetFormData(DEFAULT_WIDGET_DATA, '00:00');
      return formBindingData.createFormBindingData(errData);
    }
  }

  async updateForm(formId: string) {
    let bindingData = await this.getLatestFormData();

    formProvider.updateForm(formId, bindingData).then(() => {
      // 这里的 bindingData.data 是 Object，需要转为我们的类型
      // 由于我们上面是用 WidgetFormData 创建的，所以可以直接取 .widgetData
      // 但 formBindingData 内部会被序列化，取出来时可能需要强转
      let dataMap = bindingData.data as Record<string, Object>;
      let widgetData = dataMap['widgetData'] as TodayWidgetData;

      this.scheduleNextRefresh(formId, widgetData);
    }).catch((err: BusinessError) => {
      console.error(`[EntryFormAbility] updateForm failed: ${JSON.stringify(err)}`);
    });
  }

  async scheduleNextRefresh(formId: string, widgetData: TodayWidgetData) {
    try {
      if (!widgetData) return;

      const courses = widgetData.courses || [];

      if (courses.length === 0) {
        this.setNextRefreshDelay(formId, 60);
        return;
      }

      const now = new Date();
      const currentHour = now.getHours();
      const currentMin = now.getMinutes();
      const currentTotalMin = currentHour * 60 + currentMin;

      let nextRefeshMin = 9999;

      for (let course of courses) {
        const startMin = this.parseTimeStr(course.startTimeStr);
        const endMin = this.parseTimeStr(course.endTimeStr);

        if (startMin > currentTotalMin && startMin < nextRefeshMin) {
          nextRefeshMin = startMin;
        }

        if (endMin > currentTotalMin && endMin < nextRefeshMin) {
          nextRefeshMin = endMin;
        }
      }

      if (nextRefeshMin !== 9999) {
        let delayMinutes = nextRefeshMin - currentTotalMin;
        this.setNextRefreshDelay(formId, delayMinutes + 1);
        console.info(`[EntryFormAbility] Scheduled next refresh in ${delayMinutes + 1} minutes`);
      } else {
        console.info(`[EntryFormAbility] All courses finished.`);
        this.setNextRefreshDelay(formId, 60);
      }

    } catch (e) {
      console.error(`[EntryFormAbility] Schedule failed: ${e}`);
    }
  }

  setNextRefreshDelay(formId: string, minutes: number) {
    if (minutes < 5) minutes = 5;

    let time = new Date().getTime() + minutes * 60 * 1000;

    formProvider.setFormNextRefreshTime(formId, time / 1000)
      .catch((err: BusinessError) => {
        console.error(`[EntryFormAbility] Failed to setNextRefreshTime: ${JSON.stringify(err)}`);
      });
  }

  parseTimeStr(timeStr: string): number {
    if (!timeStr) return 0;
    const parts = timeStr.split(':');
    return parseInt(parts[0]) * 60 + parseInt(parts[1]);
  }

  private getCurrentTimeStr(): string {
    const now = new Date();
    const hours = now.getHours().toString().padStart(2, '0');
    const minutes = now.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }
};