import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../Resources/Constant.dart';
import '../../Utils/ToastUtil.dart';
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

  bool _checkboxSelected = false;
  double randomNumForCaptcha = 0;

  @override
  void initState() {
    // TODO: implement initState
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
          title: Text(widget.title),
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
                    hintText: '用户名',
                  ),
                  onEditingComplete: () =>
                      FocusScope.of(context).requestFocus(pwdTextFieldNode),
                ),
                TextField(
                  controller: _pwdController,
                  decoration: InputDecoration(
                    icon:
                        Icon(Icons.lock, color: Theme.of(context).primaryColor),
                    hintText: '密码',
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
                      hintText: '验证码',
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
                          '点击刷新',
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
                    Text('记住密码'),
                  ],
                ),
                Container(
                  width: double.infinity,
                  child: FlatButton(
                      color: Theme.of(context).primaryColor,
                      child: Text('导入'),
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
                          ToastUtil.showToast("密码错误 = =||", context);
                          setState(() {
                            _pwdController.clear();
                            randomNumForCaptcha = Random().nextDouble();
                          });
                        } else if (status == Constant.CAPTCHA_ERROR) {
                          ToastUtil.showToast("验证码错误 > <", context);

                          setState(() {
                            randomNumForCaptcha = Random().nextDouble();
                          });
                        } else if (status == Constant.LOGIN_CORRECT) {
                          bool isSuccess = await _presenter.getClasses(context);
                          if (!isSuccess)
                            ToastUtil.showToast(
                                "课程解析失败 = =|| 可将课表反馈至翠翠", context);
                          ToastUtil.showToast("数据存储成功 >v<", context);
                          Navigator.of(context).pop();
                        } else {
                          ToastUtil.showToast("出现异常，建议提交反馈", context);
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
