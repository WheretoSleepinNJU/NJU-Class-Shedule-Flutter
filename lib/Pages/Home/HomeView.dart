import 'package:flutter/material.dart';
import '../../AdaptiveUI/adaptive_ui.dart';
import '../../generated/l10n.dart';
import '../CourseTable/CourseTableView.dart';
import '../Settings/SettingsView.dart';
import 'CoursesView.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _timetable = GlobalKey<CourseTableViewState>();
  final _courses = GlobalKey<CoursesViewState>();
  int _selected = 0;
  void _select(int index) {
    if (index == _selected) return;
    setState(() => _selected = index);
    if (index == 0) _timetable.currentState?.refreshForVisit();
    if (index == 1) _courses.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AdaptiveNavigationShell(
      selectedIndex: _selected,
      onSelected: _select,
      items: [
        AdaptiveNavigationItem(
          label: s.home_timetable,
          icon: Icons.calendar_month_rounded,
          selectedIcon: Icons.calendar_month_rounded,
          androidIcon: 'Months',
          iosSymbol: 'calendar',
          iosSelectedSymbol: 'calendar',
        ),
        AdaptiveNavigationItem(
          label: s.home_courses,
          icon: Icons.menu_book_rounded,
          selectedIcon: Icons.menu_book_rounded,
          androidIcon: 'NotesFill',
          iosSymbol: 'books.vertical',
          iosSelectedSymbol: 'books.vertical.fill',
        ),
        AdaptiveNavigationItem(
          label: s.home_profile,
          icon: Icons.person_rounded,
          selectedIcon: Icons.person_rounded,
          androidIcon: 'ContactsCircle',
          iosSymbol: 'person',
          iosSelectedSymbol: 'person.fill',
        ),
      ],
      pages: [
        CourseTableView(key: _timetable),
        CoursesView(key: _courses),
        const SettingsView(profile: true),
      ],
    );
  }
}
