import { CourseWidgetVO } from './CourseModel';

export interface DayWidgetData {
  date: string;
  dateKey?: string;
  week?: number;
  courses: CourseWidgetVO[];
}
export interface TodayWidgetData extends DayWidgetData {
  scheduleName?: string;
  tomorrowPreviewHour?: number;
  days?: DayWidgetData[];
  tomorrow?: boolean;
  stale?: boolean;
}
