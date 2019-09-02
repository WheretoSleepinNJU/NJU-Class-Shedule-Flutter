import 'package:flutter/material.dart';
import '../../Resources/Strings.dart';
import 'ImportPresenter.dart';

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
//              onEditingComplete: () =>
//                  FocusScope.of(context).requestFocus(cidTextFieldNode),
            ),
//                  Image.network(
//                    'http://elite.nju.edu.cn/jiaowu/ValidateCode.jsp',
//                  ),
            FutureBuilder(
                future: _presenter.getCaptcha(),
//                      builder: (BuildContext context, AsyncSnapshot<Uint8List> image){
                builder: (BuildContext context, AsyncSnapshot<Image> image) {
//                    print("QAQ");
//                        return Image.memory(image);
                  if (image.hasData) {
                    return image.data;
                  } else {
                    return new Container();
                  }
                }),
//                ],
//              ),
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(10),
              child: FlatButton(
                  color: Theme.of(context).primaryColor,
                  child: Text('导入'),
                  textColor: Colors.white,
                  onPressed: () async {
//                  save();
                    await _presenter.login(
                        _usrController.value.text.toString(),
                        _pwdController.value.text.toString(),
                        _captchaController.value.text.toString());
                    await _presenter.getClasses();
                    Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text("数据存储成功"),
                      backgroundColor: Theme.of(context).primaryColor,
                    ));
                  }),
            )
          ]);
        }));
  }
}
