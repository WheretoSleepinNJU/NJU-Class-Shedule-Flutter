// Import the test package and Counter class
import 'package:flutter_test/flutter_test.dart';
import 'package:wheretosleepinnju/Utils/CourseParser.dart';

void main() {
  test('test week number', () {
    CourseParser cp = CourseParser('');
    String rst = '';
    // 最正常的
    rst = cp.getWeekSeriesString('周四 第5-7节 4-17周 仙Ⅱ-405');
    expect(rst, '[4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]');
    // 加个带11的
    rst = cp.getWeekSeriesString('周四 第9-11节  3-17周 ');
    expect(rst, '[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]');
    // 只有单周的
    rst = cp.getWeekSeriesString('周二 第3-4节 单周 逸B-101');
    expect(rst, '[1, 3, 5, 7, 9, 11, 13, 15, 17]');
    // 指定周数的
    rst = cp.getWeekSeriesString('周二 第9-10节 仙Ⅰ-207 第9周 第11周 第13周 第15周 ');
    expect(rst, '[9, 11, 13, 15]');
    // 从第X周开始 单双周 2021数理科学类 思想道德与法治
    rst = cp.getWeekSeriesString('周二 第9-10节 双周（从第4周开始） 逸B-104');
    expect(rst, '[4, 6, 8, 10, 12, 14, 16]');
    // 又有指定又有连续的 2021工科实验班 大学化学
    rst = cp.getWeekSeriesString('周三 第9-10节 第9周 第11周 第13周 15-17周 仙Ⅰ-107');
    expect(rst, '[9, 11, 13, 15, 16, 17]');
    // 断断续续的 2020信息管理学院 信息论基础
    rst = cp.getWeekSeriesString('周四 第5-7节 1-2周 4-5周 7-8周 10-11周 13-14周 16-17周 ');
    expect(rst, '[1, 2, 4, 5, 7, 8, 10, 11, 13, 14, 16, 17]');
    // 又有连续又有从单周指定的 2021物理学院 走进物理大世界
    rst = cp.getWeekSeriesString('周五 第9-10节 4-5周 单周（从第7周开始）');
    expect(rst, '[4, 5, 7, 9, 11, 13, 15, 17]');
    // 又又中断又有从单周指定的
    rst = cp.getWeekSeriesString('周五 第9-10节 第4周 单周（从第7周开始）');
    expect(rst, '[4, 7, 9, 11, 13, 15, 17]');
    // 他妈的没有周 线性代数
    rst = cp.getWeekSeriesString('周三 第3-4节');
    expect(rst, '[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]');
  });
}
