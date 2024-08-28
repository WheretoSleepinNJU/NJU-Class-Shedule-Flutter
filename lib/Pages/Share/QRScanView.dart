import 'dart:io';
import '../../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScanView extends StatefulWidget {
  const QRScanView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRScanViewState();
}

class _QRScanViewState extends State<QRScanView> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).import_qr_title),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
              child: QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Theme.of(context).brightness == Brightness.light
                  ? Theme.of(context).primaryColor
                  : Colors.white,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 300,
            ),
          )),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    // ignore: prefer_typing_uninitialized_variables
    var scannedDataStream;
    scannedDataStream = controller.scannedDataStream.listen((scanData) {
      controller.pauseCamera();
      scannedDataStream.cancel();
      if (scanData.code != '') Navigator.of(context).pop(scanData.code);
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
