import 'package:flutter/material.dart';
import '../../Resources/Constant.dart';
import 'ImportPresenter.dart';
import 'dart:math';

class ImportView extends StatefulWidget {
  ImportView() : super();
  final String title = '导入课程表';

  @override
  _ImportViewState createState() => _ImportViewState();
}

class _ImportViewState extends State<ImportView> {
  ImportPresenter _presenter = new ImportPresenter();

  TextEditingController _usrController = new TextEditingController();
  TextEditingController _pwdController = new TextEditingController();
  TextEditingController _captchaController = new TextEditingController();
  final FocusNode usrTextFieldNode = FocusNode();
  final FocusNode pwdTextFieldNode = FocusNode();
  final FocusNode captchaTextFieldNode = FocusNode();

  double randomNumForCaptcha = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Builder(builder: (BuildContext context) {
          return Column(children: <Widget>[
            TextField(
              controller: _usrController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.only(top: 10.0),
                icon: Icon(Icons.account_circle,
                    color: Theme.of(context).primaryColor),
                hintText: '用户名',
              ),
              onEditingComplete: () =>
                  FocusScope.of(context).requestFocus(pwdTextFieldNode),
            ),
            TextField(
              controller: _pwdController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.only(top: 10.0),
                icon: Icon(Icons.lock, color: Theme.of(context).primaryColor),
                hintText: '密码',
              ),
              obscureText: true,
              onEditingComplete: () =>
                  FocusScope.of(context).requestFocus(captchaTextFieldNode),
            ),
//              Row(
//                children: <Widget>[
            TextField(
              controller: _captchaController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.only(top: 10.0),
//                  icon: Icon(Icons.beenhere, color: Theme.of(context).primaryColor),
                icon: Icon(Icons.code, color: Theme.of(context).primaryColor),
                hintText: '验证码',
              ),
            ),
            InkWell(
              child: FutureBuilder(
                  future: _presenter.getCaptcha(randomNumForCaptcha),
//                      builder: (BuildContext context, AsyncSnapshot<Uint8List> image){
                  builder: (BuildContext context, AsyncSnapshot<Image> image) {
                    if (image.hasData) {
                      return image.data;
                    } else {
                      return new Container();
                    }
                  }),
              onTap: () => setState(() {
                randomNumForCaptcha = Random().nextDouble();
              }),
            ),
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(10),
              child: FlatButton(
                  color: Theme.of(context).primaryColor,
                  child: Text('导入'),
                  textColor: Colors.white,
                  onPressed: () async {
//                  save();
                    int status = await _presenter.login(
                        _usrController.value.text.toString(),
                        _pwdController.value.text.toString(),
                        _captchaController.value.text.toString());
                    if (status == Constant.PASSWORD_ERROR) {
                      Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text("密码错误 = =||"),
                        backgroundColor: Theme.of(context).primaryColor,
                      ));
                      setState(() {
                        _pwdController.clear();
                        randomNumForCaptcha = Random().nextDouble();
                      });
                    } else if (status == Constant.CAPTCHA_ERROR) {
                      Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text("验证码错误 > <"),
                        backgroundColor: Theme.of(context).primaryColor,
                      ));
                      setState(() {
                        randomNumForCaptcha = Random().nextDouble();
                      });
                    } else if (status == Constant.LOGIN_CORRECT) {
                      bool isSuccess = await _presenter.getClasses(context);
                      if(!isSuccess) Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text('课程解析失败 = =|| 可将课表反馈至翠翠'),
                        backgroundColor: Theme.of(context).primaryColor,
                      ));
                      Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text("数据存储成功 >v<"),
                        backgroundColor: Theme.of(context).primaryColor,
                      ));
                    } else {
                      Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text("出现异常，建议提交反馈"),
                        backgroundColor: Theme.of(context).primaryColor,
                      ));
                      setState(() {
                        randomNumForCaptcha = Random().nextDouble();
                      });
                    }
                  }),
            )
          ]);
        }));
  }
}
