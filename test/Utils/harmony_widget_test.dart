import 'package:flutter_test/flutter_test.dart';
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Utils/WidgetHelper.dart';

void main() {
  test('Harmony single-period and multi-period courses retain their end time', () {
    final data=WidgetHelper.buildHarmonyWidgetData([
      Course(1,'single','[1]',6,1,0,0,classroom:'QA-101'),
      Course(1,'double','[1]',6,1,1,0,classroom:'QA-102'),
    ],'周六',[
      {'start':'08:00','end':'08:50'},
      {'start':'09:00','end':'09:50'},
    ],[]);
    final rows=data['courses'] as List;
    expect(rows[0]['endTimeStr'],'08:50');
    expect(rows[0]['step'],1);
    expect(rows[1]['endTimeStr'],'09:50');
    expect(rows[1]['step'],2);
  });
}
