import '../../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRShareView extends StatelessWidget {
  final String url;

  const QRShareView(this.url, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).export_title),
        ),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            QrImageView(
              data: url,
              version: QrVersions.auto,
              size: 200.0,
            ),
            const Padding(padding: EdgeInsets.all(10)),
            Text(
              S.of(context).import_from_qrcode_content,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            )
          ],
        )));
  }
}
