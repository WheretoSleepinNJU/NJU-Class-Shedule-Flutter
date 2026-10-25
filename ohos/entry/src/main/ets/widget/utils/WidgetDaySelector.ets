import { TodayWidgetData } from '../models/WidgetDataModel';

function dateKey(date: Date): string {
  return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`;
}

// Select by calendar date on each native refresh, including across midnight.
export function selectWidgetDay(data: TodayWidgetData, now: Date = new Date()): TodayWidgetData {
  if (!data.days || data.days.length === 0) return data;
  const key = dateKey(now);
  const today = data.days.find(day => day.dateKey === key);
  if (!today) return { date: '请打开课表同步', courses: [], stale: true };
  const minute = now.getHours() * 60 + now.getMinutes();
  const remaining = today.courses.filter(course => {
    const parts = course.endTimeStr.split(':');
    return Number(parts[0]) * 60 + Number(parts[1]) > minute;
  });
  if (remaining.length === 0 && now.getHours() >= (data.tomorrowPreviewHour ?? 21)) {
    const next = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
    const tomorrow = data.days.find(day => day.dateKey === dateKey(next));
    if (tomorrow) return { date: tomorrow.date, dateKey: tomorrow.dateKey, week: tomorrow.week,
      courses: tomorrow.courses, scheduleName: data.scheduleName, tomorrow: true };
  }
  return { date: today.date, dateKey: today.dateKey, week: today.week,
    courses: today.courses, scheduleName: data.scheduleName };
}
