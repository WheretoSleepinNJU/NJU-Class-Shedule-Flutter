// Import the test package and Counter class
import 'package:flutter_test/flutter_test.dart';
import 'package:wheretosleepinnju/Utils/CourseParserXK.dart';

void main() {
  test('test week number', () {
    CourseParser cp = CourseParser('');
    String rst = '';
    // 最正常的
    rst = cp.getWeekSeriesString('周二 5-6节 4-17周 仙Ⅰ-308');
    expect(rst, '[4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]');
    // 加个带11的
    rst = cp.getWeekSeriesString('周四 9-11节 4-17周 物理楼201/204/206/220/303/515');
    expect(rst, '[4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]');
    // 只有单周的
    rst = cp.getWeekSeriesString('周四 3-4节 1-17周(单) 教103');
    expect(rst, '[1, 3, 5, 7, 9, 11, 13, 15, 17]');
    // 指定周数的
    rst = cp.getWeekSeriesString('周四 5-7节 3周,6周,9周,12周,15周 基础实验楼乙110');
    expect(rst, '[3, 6, 9, 12, 15]');
    // 从第X周开始 单双周 2021数理科学类 思想道德与法治
    rst = cp.getWeekSeriesString('周三 9-10节 9-13周(单) 仙Ⅰ-107');
    expect(rst, '[9, 11, 13]');
    // 又有指定又有连续的 2021工科实验班 大学化学
    rst = cp.getWeekSeriesString('周三 9-10节 9-13周(单),15-17周 仙Ⅰ-107');
    expect(rst, '[9, 11, 13, 15, 16, 17]');
    // 断断续续的 2020信息管理学院 信息论基础
    rst = cp.getWeekSeriesString('周四 5-7节 1-2周,4-5周,7-8周,10-11周,13-14周,16-17周 逸B-306');
    expect(rst, '[1, 2, 4, 5, 7, 8, 10, 11, 13, 14, 16, 17]');
    // 又有连续又有从单周指定的 2021物理学院 走进物理大世界
    rst = cp.getWeekSeriesString('周五 9-10节 4-5周,7-17周(单) 仙Ⅰ-207');
    expect(rst, '[4, 5, 7, 9, 11, 13, 15, 17]');
    // 又又中断又有从单周指定的
    rst = cp.getWeekSeriesString('周五 9-10节 4周,7-17周(单) 仙Ⅰ-207');
    expect(rst, '[4, 7, 9, 11, 13, 15, 17]');
    // 新教务系统没有这种情况了，直接返回空就好了
    rst = cp.getWeekSeriesString('周三 第3-4节');
    expect(rst, '[]');
  });
}
