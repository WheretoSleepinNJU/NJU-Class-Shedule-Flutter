import { selectWidgetDay } from '../utils/WidgetDaySelector';
import { TodayWidgetData } from './WidgetDataModel';

export class WidgetFormData {
  widgetData: TodayWidgetData;
  currentTime: string;

  constructor(widgetData: TodayWidgetData, currentTime: string) {
    this.widgetData = selectWidgetDay(widgetData);
    this.currentTime = currentTime;
  }
}

export const DEFAULT_WIDGET_DATA: TodayWidgetData = {
  date: '南哪课表',
  stale: true,
  courses: []
};



export const DATA_PREFERENCES_NAME = 'WidgetDataPrefs';
export const WIDGET_DATA_KEY = 'current_day_courses';
export const FORM_IDS_KEY = 'active_form_ids';
export const CHANNEL_NAME = 'wheretosleepinnju/widget';