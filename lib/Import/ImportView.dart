import 'package:flutter/material.dart';
import '../Resources/Strings.dart';
import 'ImportPresenter.dart';
import 'dart:typed_data';


class ImportView extends StatefulWidget {
  ImportView() : super();
  final String title = 'Import';

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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Builder(builder: (BuildContext context) {
          return Column(
            children: <Widget>[
              TextField(
                controller: _usrController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(top: 10.0),
                  icon: Icon(Icons.perm_identity),
                  hintText: '用户名',
                ),
                onEditingComplete: () =>
                    FocusScope.of(context).requestFocus(pwdTextFieldNode),
              ),
              TextField(
                controller: _pwdController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(top: 10.0),
                  icon: Icon(Icons.lock),
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
                      icon: Icon(Icons.lock),
                      hintText: '验证码',
                    ),
//              onEditingComplete: () =>
//                  FocusScope.of(context).requestFocus(cidTextFieldNode),
                  ),
//                  Image.network(
//                    'http://elite.nju.edu.cn/jiaowu/ValidateCode.jsp',
//                  ),
                    FutureBuilder(
                      future: _presenter.getCaptcha(),
//                      builder: (BuildContext context, AsyncSnapshot<Uint8List> image){
                      builder: (BuildContext context, AsyncSnapshot<Image> image){
//                        return Image.memory(image);
                        if (image.hasData) {
                          return image.data;
                        } else {
                          return new Container();
                        }
                      }
                    ),
//                ],
//              ),
              RaisedButton(
                  child: Text('导入'),
                  onPressed: () {
//                  save();
                    _presenter.login(
                        _usrController.value.text.toString(),
                        _pwdController.value.text.toString(),
                        _captchaController.value.text.toString());
                    Scaffold.of(context)
                        .showSnackBar(SnackBar(content: Text("数据存储成功")));
                  }),
            ],
          );
        }));
  }
}
