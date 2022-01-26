import '../../generated/l10n.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import '../../Resources/Constant.dart';
import '../../Components/Toast.dart';
import '../../Resources/Url.dart';

import 'ImportFromJWPresenter.dart';
import 'dart:math';

class ImportFromJWView extends StatefulWidget {
  const ImportFromJWView({Key? key}) : super(key: key);


  @override
  _ImportFromJWViewState createState() => _ImportFromJWViewState();
}

class _ImportFromJWViewState extends State<ImportFromJWView> {
  final ImportFromJWPresenter _presenter = ImportFromJWPresenter();

  final TextEditingController _usrController = TextEditingController();
  final TextEditingController _pwdController = TextEditingController();
  final TextEditingController _captchaController = TextEditingController();
  final FocusNode usrTextFieldNode = FocusNode();
  final FocusNode pwdTextFieldNode = FocusNode();
  final FocusNode captchaTextFieldNode = FocusNode();

  bool _checkboxSelected = false;
  double randomNumForCaptcha = Random().nextDouble();

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  _getUserInfo() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? username = sp.getString('username');
    String? password = sp.getString('password');
    if (username == null || password == null) {
      _checkboxSelected = false;
    } else {
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
          title: Text(S.of(context).import_from_JW_title),
        ),
        body: Builder(builder: (BuildContext context) {
          return Container(
              width: double.infinity,
              margin: const EdgeInsets.all(10),
              child: Column(children: <Widget>[
                MaterialBanner(
                  forceActionsBelow: true,
                  content: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(S.of(context).import_banner,
                          style: const TextStyle(color: Colors.white))),
                  backgroundColor: Theme.of(context).primaryColor,
                  actions: [
                    TextButton(
                        style: TextButton.styleFrom(primary: Colors.white),
                        child: Text(S.of(context).import_banner_action),
                        onPressed: () => launch(Url.URL_NJU_VPN))
                  ],
                ),
                TextField(
                  controller: _usrController,
                  decoration: InputDecoration(
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor),
                    ),
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
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor),
                    ),
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
                      focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                      ),
                      icon: Icon(Icons.code,
                          color: Theme.of(context).primaryColor),
                      hintText: S.of(context).captcha,
                    ),
                  )),
                  Container(
                    padding: const EdgeInsets.all(5),
                    child: InkWell(
                      child: FutureBuilder(
                          future: _presenter.getCaptcha(randomNumForCaptcha),
                          builder: (BuildContext context,
                              AsyncSnapshot<Image> image) {
                            if (image.hasData) {
                              return image.data!;
                            } else {
                              return Container();
                            }
                          }),
                      onTap: () => setState(() {
                        randomNumForCaptcha = Random().nextDouble();
                      }),
                    ),
                  ),
                  Container(
                      padding: const EdgeInsets.all(5),
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
                          _checkboxSelected = value!;
                        });
                      },
                    ),
                    Text(S.of(context).remember_password),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                      child: Text(S.of(context).import),
                      onPressed: () async {
                        // 这里没必要同步，异步处理即可
                        if (_checkboxSelected) {
                          _saveUserInfo();
                        } else {
                          _clearUserInfo();
                        }
                        if (_usrController.value.text.toString() == 'admin' &&
                            _pwdController.value.text.toString() == 'admin') {
                          await _presenter.getDemoClasses(context);
                          UmengCommonSdk.onEvent("class_import",
                              {"type": "jw", "action": "success"});
                          Toast.showToast(
                              S.of(context).class_parse_toast_success, context);
                          Navigator.of(context).pop(true);
                          return;
                        }
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
                          if (!isSuccess) {
                            Toast.showToast(
                                S.of(context).class_parse_error_toast, context);
                          } else {
                            Toast.showToast(
                                S.of(context).class_parse_toast_success,
                                context);
                          }
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
