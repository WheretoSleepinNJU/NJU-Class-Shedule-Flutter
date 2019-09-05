import 'package:flutter/material.dart';
import 'package:flutter_picker/flutter_picker.dart';
import '../../Resources/Constant.dart';

//import 'ImportPresenter.dart';
import 'dart:convert';
import 'dart:math';

class AddView extends StatefulWidget {
  AddView() : super();
  final String title = '添加课程';

  @override
  _AddViewState createState() => _AddViewState();
}

class _AddViewState extends State<AddView> {
//  AddPresenter _presenter = new AddPresenter();

  TextEditingController _nameController = new TextEditingController();
  TextEditingController _teacherController = new TextEditingController();
  TextEditingController _captchaController = new TextEditingController();
  final FocusNode nameTextFieldNode = FocusNode();
  final FocusNode teacherTextFieldNode = FocusNode();
  final FocusNode captchaTextFieldNode = FocusNode();

  double randomNumForCaptcha = 0;

  @override
  Widget build(BuildContext context) {

    const PickerData2 = '''
[
    [
        1,
        2,
        3,
        4
    ],
    [
        11,
        22,
        33,
        44
    ],
    [
        "aaa",
        "bbb",
        "ccc"
    ]
]
    ''';

    showPickerArray(BuildContext context) {
      new Picker(
          adapter: PickerDataAdapter<String>(pickerdata: new JsonDecoder().convert(PickerData2), isArray: true),
          hideHeader: true,
          title: new Text("Please Select"),
          onConfirm: (Picker picker, List value) {
            print(value.toString());
            print(picker.getSelectedValues());
          }
      ).showDialog(context);
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Builder(builder: (BuildContext context) {
          return Column(children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.only(top: 10.0),
                icon: Icon(Icons.account_circle,
                    color: Theme.of(context).primaryColor),
                hintText: '课程名称',
              ),
              onEditingComplete: () =>
                  FocusScope.of(context).requestFocus(teacherTextFieldNode),
            ),
            TextField(
              controller: _teacherController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.only(top: 10.0),
                icon: Icon(Icons.lock, color: Theme.of(context).primaryColor),
                hintText: '上课老师',
              ),
              obscureText: true,
              onEditingComplete: () =>
                  FocusScope.of(context).requestFocus(captchaTextFieldNode),
            ),

//            TextField(
//              controller: _captchaController,
//              decoration: InputDecoration(
//                contentPadding: const EdgeInsets.only(top: 10.0),
////                  icon: Icon(Icons.beenhere, color: Theme.of(context).primaryColor),
//                icon: Icon(Icons.code, color: Theme.of(context).primaryColor),
//                hintText: '验证码',
//              ),
////              onEditingComplete: () =>
////                  FocusScope.of(context).requestFocus(cidTextFieldNode),
//            ),
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(10),
              child: FlatButton(
                  color: Theme.of(context).primaryColor,
                  child: Text('导入'),
                  textColor: Colors.white,
                  onPressed: () {
                    showPickerArray(context);
                  }),
            )
          ]);
        }));
  }
}
