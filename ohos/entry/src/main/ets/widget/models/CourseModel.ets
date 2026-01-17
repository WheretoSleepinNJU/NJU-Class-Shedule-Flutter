export interface CourseWidgetVO { // VO: View Object
  name: string;
  classroom: string;
  color: string;      // 对应 .dart 中的 hex 颜色字符串

  // 用于显示的字符串
  startTimeStr: string; // "08:00"
  endTimeStr: string;   // "09:50"

  // 用于逻辑判断的数字 (建议新增)
  startNode: number;    // 例如: 1 (第1节)
  step: number;         // 例如: 2 (连上2节)
  dayOfWeek?: number;   // 1-7 (如果传多天数据，这个字段能防止数组乱序)
}