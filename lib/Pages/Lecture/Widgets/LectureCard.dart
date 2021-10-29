import '../../../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../Models/CourseModel.dart';
import '../../../Models/LectureModel.dart';
import '../../../Utils/States/MainState.dart';
import '../../../Components/Toast.dart';

class LectureCard extends StatefulWidget {
  final Lecture lecture;

  LectureCard({Key? key, required this.lecture}) : super(key: key);

  @override
  _LectureCardState createState() => _LectureCardState();
}

class _LectureCardState extends State<LectureCard> {
  bool added = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    String subtitle = ('2021年10月27日 16:00-17:30') +
        '\n' +
        (widget.lecture.teacher ?? S.of(context).lecture_no_teacher) +
        ' ' +
        (widget.lecture.classroom ?? S.of(context).lecture_no_classroom);

    return Padding(
        padding: const EdgeInsets.only(top: 15, left: 5, right: 5),
        child: Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                // leading: Icon(Icons.album),
                title:
                    Text(widget.lecture.name ?? S.of(context).lecture_no_name),
                subtitle: Text(subtitle),
              ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child:
                    Text(widget.lecture.info ?? S.of(context).lecture_no_info),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  added
                      ? TextButton(
                          style: TextButton.styleFrom(primary: Colors.grey),
                          child: Text(S.of(context).lecture_added(95)),
                          onPressed: () {
                            Toast.showToast(
                                S.of(context).lecture_added_toast, context);
                          },
                        )
                      : TextButton(
                          style: TextButton.styleFrom(
                              primary: Theme.of(context).primaryColor),
                          child: Text(S.of(context).lecture_add(95)),
                          onPressed: () async {
                            widget.lecture.tableId =
                                await ScopedModel.of<MainStateModel>(context)
                                    .getClassTable();
                            CourseProvider courseProvider =
                                new CourseProvider();
                            courseProvider.insert(widget.lecture);
                            Toast.showToast(
                                S.of(context).lecture_add_success_toast,
                                context);
                            setState(() {
                              added = true;
                            });
                          },
                        ),
                ],
              ),
            ],
          ),
        ));
  }
}
