import { CourseWidgetVO } from './CourseModel';

// 1. 对应 "2x4 今日列表" 组件
export interface TodayWidgetData {
  date: string;         // "2024-01-12" (用于UI显示标题)
  courses: CourseWidgetVO[];
}

// 2. 对应 "多日/未来日程" 组件
interface DayInfo {
  dateStr: string; // "1月12日"
  dayOfWeek: number; // 1 (周一)
  courses: CourseWidgetVO[];
}

export interface FewDaysWidgetData {
  days: DayInfo[];
}