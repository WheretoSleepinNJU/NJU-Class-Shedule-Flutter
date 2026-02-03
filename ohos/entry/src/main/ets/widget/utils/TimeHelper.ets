function parseTime(timeStr: string): number {
  const parts = timeStr.split(':');
  return parseInt(parts[0]) * 60 + parseInt(parts[1]);
}

/**
 * 判断课程是否处于“活跃状态”
 * @param startTimeStr 开始时间 "08:00"
 * @param endTimeStr 结束时间 "09:50"
 * @param currentTimeStr 当前模拟时间 "08:00"
 * @param bufferMinutes 提前多久开始高亮 (默认30分钟)
 */
export function isCourseActive(startTimeStr: string, endTimeStr: string, currentTimeStr: string, bufferMinutes: number = 30): boolean {
  const start = parseTime(startTimeStr);
  const end = parseTime(endTimeStr);
  const now = parseTime(currentTimeStr);

  // 判定区间：[开始前30分钟] ~ [课程结束]
  return now >= (start - bufferMinutes) && now <= end;
}