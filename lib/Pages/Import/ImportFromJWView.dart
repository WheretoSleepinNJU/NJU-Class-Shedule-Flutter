import 'dart:io';
import 'package:flutter/services.dart';
import '../../Components/Dialog.dart';
import '../../Components/TransBgTextButton.dart';
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
                // MaterialBanner(
                //   forceActionsBelow: true,
                //   content: FittedBox(
                //       fit: BoxFit.scaleDown,
                //       alignment: Alignment.centerLeft,
                //       child: Text(S.of(context).import_banner,
                //           style: const TextStyle(color: Colors.white))),
                //   backgroundColor: Theme.of(context).primaryColor,
                //   actions: [
                //     TextButton(
                //         style: TextButton.styleFrom(
                //             foregroundColor: Colors.white,
                //             backgroundColor: Theme.of(context).primaryColor),
                //         child: Text(S.of(context).import_banner_action),
                //         onPressed: () => launch(Url.URL_NJU_VPN))
                //   ],
                // ),
                Container(
                  padding: const EdgeInsets.all(5),
                ),
                TextField(
                  controller: _usrController,
                  decoration: InputDecoration(
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    icon: const Icon(Icons.account_circle),
                    hintText: S.of(context).username,
                  ),
                  onEditingComplete: () =>
                      FocusScope.of(context).requestFocus(pwdTextFieldNode),
                ),
                Container(
                  padding: const EdgeInsets.all(5),
                ),
                TextField(
                  controller: _pwdController,
                  decoration: InputDecoration(
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    icon: const Icon(Icons.lock),
                    hintText: S.of(context).password,
                  ),
                  obscureText: true,
                  onEditingComplete: () =>
                      FocusScope.of(context).requestFocus(captchaTextFieldNode),
                ),
                Container(
                  padding: const EdgeInsets.all(5),
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
                      icon: const Icon(Icons.code),
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
                          style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Theme.of(context).primaryColor
                                  : Colors.white),
                        ),
                        onTap: () => setState(() {
                          randomNumForCaptcha = Random().nextDouble();
                        }),
                      ))
                ]),
                // CheckboxListTile(
                //   contentPadding: EdgeInsets.zero,
                //   title: Text("title text"),
                //   value: _checkboxSelected,
                //   onChanged: (newValue) {},
                //   controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
                // ),
                // Row(
                //   children: <Widget>[
                //     SizedBox(
                //         height: 44.0,
                //         width: 24.0,
                //         child: Checkbox(
                //           value: _checkboxSelected,
                //           checkColor:
                //               Theme.of(context).brightness == Brightness.light
                //                   ? Colors.white
                //                   : Colors.black,
                //           onChanged: (value) {
                //             setState(() {
                //               _checkboxSelected = value!;
                //             });
                //           },
                //         )),
                //     const Padding(
                //       padding: EdgeInsets.only(left: 10),
                //     ),
                //     Text(S.of(context).remember_password),
                //   ],
                // ),
                Container(
                  padding: const EdgeInsets.all(5),
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
                            UmengCommonSdk.onEvent("class_import",
                                {"type": "jw", "action": "success"});
                            Toast.showToast(
                                S.of(context).class_parse_toast_success,
                                context);
                          }
                          Navigator.of(context).pop(true);
                        } else {
                          UmengCommonSdk.onEvent(
                              "class_import", {"type": "jw", "action": "fail"});
                          // Toast.showToast(
                          //     S.of(context).class_parse_toast_fail, context);
                          showDialog<String>(
                              barrierDismissible: false,
                              context: context,
                              builder: (BuildContext context) {
                                return MDialog(
                                  S.of(context).parse_error_dialog_title,
                                  Text(S
                                      .of(context)
                                      .parse_error_dialog_content("102")),
                                  overrideActions: <Widget>[
                                    Container(
                                        alignment: Alignment.centerRight,
                                        child: TransBgTextButton(
                                            color: Theme.of(context)
                                                        .brightness ==
                                                    Brightness.light
                                                ? Theme.of(context).primaryColor
                                                : Colors.white,
                                            child: Text(S
                                                .of(context)
                                                .parse_error_dialog_add_group),
                                            onPressed: () async {
                                              await Clipboard.setData(
                                                  const ClipboardData(
                                                      text: "102"));
                                              if (Platform.isIOS) {
                                                launch(Url.QQ_GROUP_APPLE_URL);
                                              } else if (Platform.isAndroid) {
                                                launch(
                                                    Url.QQ_GROUP_ANDROID_URL);
                                              }
                                              Navigator.of(context).pop();
                                            })),
                                    Container(
                                        alignment: Alignment.centerRight,
                                        child: TransBgTextButton(
                                            color: Colors.grey,
                                            child: Text(
                                                S
                                                    .of(context)
                                                    .parse_error_dialog_other_ways,
                                                style: const TextStyle(
                                                    color: Colors.grey)),
                                            onPressed: () async {
                                              Navigator.of(context).pop();
                                              Navigator.of(context).pop();
                                            }))
                                  ],
                                );
                              });
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
