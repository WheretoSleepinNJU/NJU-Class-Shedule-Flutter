import '../../Models/CourseModel.dart';
import '../../Models/ScheduleModel.dart';

class CourseTablePresenter {
  CourseProvider courseProvider = new CourseProvider();
  List<Course> activeCourses = [];
  List<Course> hideCourses = [];

  refreshClasses(int tableId, int nowWeek) async {
    //TODO：finish classes to shedule
    List<Map> allCoursesMap = await courseProvider.getAllCourses(tableId);
    List<Course> allCourses = [];
    for (Map courseMap in allCoursesMap) {
      allCourses.add(new Course.fromMap(courseMap));
    }
    ScheduleModel scheduleModel = new ScheduleModel(allCourses, nowWeek);
    activeCourses = scheduleModel.activeCourses;
    hideCourses = scheduleModel.hideCourses;
  }

  Future insertMockData() async {
    await courseProvider.insert(new Course(
        0, "微积分", "[1,2,3,4,5,6,7]", 3, 5, 2, 0,
        color: '#8AD297', classroom: 'QAQ'));
    await courseProvider.insert(new Course(
        0, "线性代数", "[1,2,3,4,5,6,7]", 4, 2, 3, 0,
        color: '#F9A883', classroom: '仙林校区不知道哪个教室'));
    await courseProvider.insert(new Course(
        1, "并不是线性代数", "[1,2,3,4,5,6,7]", 4, 2, 3, 0,
        color: '#F9A883', classroom: 'QAQ'));
  }
}
