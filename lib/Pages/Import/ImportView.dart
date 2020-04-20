import '../../generated/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../Resources/Constant.dart';
import '../../Components/Toast.dart';
import 'ImportPresenter.dart';
import 'dart:math';

class ImportView extends StatefulWidget {
  ImportView() : super();

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

  bool _checkboxSelected = false;
  double randomNumForCaptcha = 0;

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  _getUserInfo() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String username = sp.getString('username');
    String password = sp.getString('password');
    if (username == null || password == null)
      _checkboxSelected = false;
    else {
      setState(() {
        _checkboxSelected = true;
        _usrController.text = username;
        _pwdController.text = password;
      });
    }
  }

  _saveUserInfo() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString("username", _usrController.value.text.toString());
    sp.setString("password", _pwdController.value.text.toString());
  }

  _clearUserInfo() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.remove('username');
    sp.remove('password');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).import_title),
        ),
        body: Builder(builder: (BuildContext context) {
          return Container(
              width: double.infinity,
              margin: EdgeInsets.all(10),
              child: Column(children: <Widget>[
                TextField(
                  controller: _usrController,
                  decoration: InputDecoration(
                    icon: Icon(Icons.account_circle,
                        color: Theme.of(context).primaryColor),
                    hintText: S.of(context).username,
                  ),
                  onEditingComplete: () =>
                      FocusScope.of(context).requestFocus(pwdTextFieldNode),
                ),
                TextField(
                  controller: _pwdController,
                  decoration: InputDecoration(
                    icon:
                        Icon(Icons.lock, color: Theme.of(context).primaryColor),
                    hintText: S.of(context).password,
                  ),
                  obscureText: true,
                  onEditingComplete: () =>
                      FocusScope.of(context).requestFocus(captchaTextFieldNode),
                ),
                Row(children: <Widget>[
                  Flexible(
                      child: TextField(
                    controller: _captchaController,
                    decoration: InputDecoration(
                      icon: Icon(Icons.code,
                          color: Theme.of(context).primaryColor),
                      hintText: S.of(context).captcha,
                    ),
                  )),
                  Container(
                    padding: EdgeInsets.all(5),
                    child: InkWell(
                      child: FutureBuilder(
                          future: _presenter.getCaptcha(randomNumForCaptcha),
                          builder: (BuildContext context,
                              AsyncSnapshot<Image> image) {
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
                  ),
                  Container(
                      padding: EdgeInsets.all(5),
                      child: InkWell(
                        child: Text(
                          S.of(context).tap_to_refresh,
                          style:
                              TextStyle(color: Theme.of(context).primaryColor),
                        ),
                        onTap: () => setState(() {
                          randomNumForCaptcha = Random().nextDouble();
                        }),
                      ))
                ]),
                Row(
                  children: <Widget>[
                    Checkbox(
                      value: _checkboxSelected,
                      activeColor: Theme.of(context).primaryColor, //选中时的颜色
                      onChanged: (value) {
                        setState(() {
                          _checkboxSelected = value;
                        });
                      },
                    ),
                    Text(S.of(context).remember_password),
                  ],
                ),
                Container(
                  width: double.infinity,
                  child: FlatButton(
                      color: Theme.of(context).primaryColor,
                      child: Text(S.of(context).import),
                      textColor: Colors.white,
                      onPressed: () async {
                        // 这里没必要同步，异步处理即可
                        if (_checkboxSelected)
                          _saveUserInfo();
                        else
                          _clearUserInfo();
                        int status = await _presenter.login(
                            _usrController.value.text.toString(),
                            _pwdController.value.text.toString(),
                            _captchaController.value.text.toString());
                        if (status == Constant.PASSWORD_ERROR) {
                          Toast.showToast(
                              S.of(context).password_error_toast, context);
                          setState(() {
                            _pwdController.clear();
                            randomNumForCaptcha = Random().nextDouble();
                          });
                        } else if (status == Constant.CAPTCHA_ERROR) {
                          Toast.showToast(
                              S.of(context).captcha_error_toast, context);

                          setState(() {
                            randomNumForCaptcha = Random().nextDouble();
                          });
                        } else if (status == Constant.USERNAME_ERROR) {
                          Toast.showToast(
                              S.of(context).username_error_toast, context);
                        } else if (status == Constant.LOGIN_CORRECT) {
                          bool isSuccess = await _presenter.getClasses(context);
                          if (!isSuccess)
                            Toast.showToast(
                                S.of(context).class_parse_error_toast, context);
                          else Toast.showToast(
                              S.of(context).class_parse_toast_success, context);
                          Navigator.of(context).pop(true);
                        } else {
                          Toast.showToast(
                              S.of(context).class_parse_toast_fail, context);
                          setState(() {
                            randomNumForCaptcha = Random().nextDouble();
                          });
                        }
                      }),
                )
              ]));
        }));
  }
}
