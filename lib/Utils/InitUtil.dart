import 'package:shared_preferences/shared_preferences.dart';
import '../Models/CourseTableModel.dart';

Future<int> Initialize() async{
  int themeIndex = await getTheme();
  await setWeek();
  await checkDataBase();
  return themeIndex;
}

Future<int> getTheme() async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  int themeIndex = sp.getInt("themeIndex");
  if (themeIndex != null) {
    return themeIndex;
  }
  return 0;
}

setWeek() async{

}

checkDataBase() async{
  CourseTableProvider courseTableProvider = new CourseTableProvider();
  List c = await courseTableProvider.getAllCourseTable();
  if(c.isEmpty) courseTableProvider.insert(new CourseTable('默认课表'));
}