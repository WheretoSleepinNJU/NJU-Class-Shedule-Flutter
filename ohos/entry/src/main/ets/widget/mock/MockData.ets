import { TodayWidgetData } from "../models/WidgetDataModel";

// --- Mock 数据 (直接按照你的类结构构造) ---
export const MOCK_DATA: TodayWidgetData = {
  date: '周一',
  courses: [
    {
      name: '操作系统原理与Linux实践', // 长文本测试
      classroom: '仙I-105',
      color: '#FF9800', // 橙色
      startTimeStr: '08:00',
      endTimeStr: '09:50',
      startNode: 1,
      step: 2
    },
    {
      name: '毛泽东思想概论',
      classroom: '仙II-203',
      color: '#8BC34A', // 绿色
      startTimeStr: '10:10',
      endTimeStr: '12:00',
      startNode: 3,
      step: 2
    },
    {
      name: '大学物理',
      classroom: '潘楼-101',
      color: '#2196F3',
      startTimeStr: '14:00',
      endTimeStr: '15:50',
      startNode: 5,
      step: 2
    }
  ]
};