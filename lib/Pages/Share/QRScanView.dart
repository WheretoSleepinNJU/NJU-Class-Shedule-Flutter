import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:zxing2/qrcode.dart';

import '../../Components/Toast.dart';
import 'qr_payload_codec.dart';

class QRScanView extends StatefulWidget {
  const QRScanView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRScanViewState();
}

class _QRScanViewState extends State<QRScanView> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;

  final Map<String, _MultiGroupBuffer> _groups = <String, _MultiGroupBuffer>{};
  bool _isCompleting = false;

  @override
  void reassemble() {
    super.reassemble();
    if (_controller == null) {
      return;
    }
    if (Platform.isAndroid) {
      _controller!.pauseCamera();
    } else if (Platform.isIOS) {
      _controller!.resumeCamera();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).import_from_qrcode_title),
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
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _pickFromGallery,
                      child: Text(S.of(context).qr_scan_from_gallery_button),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _importFromClipboard,
                      child: Text(S.of(context).qr_scan_from_clipboard_button),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = (data?.text ?? '').trim();
    if (text.isEmpty) {
      Toast.showToast(S.of(context).qrcode_url_error_toast, context);
      return;
    }

    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    try {
      if (lines.length <= 1) {
        await _handleRaw(text);
      } else {
        for (final line in lines) {
          await _handleRaw(line);
          if (_isCompleting) {
            break;
          }
        }
      }
    } catch (_) {
      if (!mounted) return;
      Toast.showToast(S.of(context).qrcode_url_error_toast, context);
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    _controller = controller;
    controller.scannedDataStream.listen((scanData) {
      final raw = scanData.code;
      if (raw == null || raw.isEmpty) {
        return;
      }
      _handleRaw(raw);
    });
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        Toast.showToast(S.of(context).qrcode_url_error_toast, context);
        return;
      }

      final pixels = Int32List(decoded.width * decoded.height);
      int i = 0;
      for (int y = 0; y < decoded.height; y++) {
        for (int x = 0; x < decoded.width; x++) {
          final p = decoded.getPixel(x, y);
          final r = p.r.toInt();
          final g = p.g.toInt();
          final b = p.b.toInt();
          pixels[i++] = (0xFF << 24) | (r << 16) | (g << 8) | b;
        }
      }

      final source = RGBLuminanceSource(decoded.width, decoded.height, pixels);
      final bitmap = BinaryBitmap(HybridBinarizer(source));
      final result = QRCodeReader().decode(bitmap);
      final text = result.text;
      if (text.isEmpty) {
        Toast.showToast(S.of(context).qrcode_url_error_toast, context);
        return;
      }
      await _handleRaw(text);
    } catch (_) {
      Toast.showToast(S.of(context).qrcode_url_error_toast, context);
    }
  }

  Future<void> _handleRaw(String raw) async {
    if (_isCompleting) {
      return;
    }

    if (!QrPayloadCodec.isNcsQrPayload(raw)) {
      Toast.showToast(S.of(context).qrcode_url_error_toast, context);
      return;
    }

    final parsed = QrPayloadCodec.parseFrame(raw);
    if (parsed == null) {
      Toast.showToast(S.of(context).qrcode_url_error_toast, context);
      return;
    }

    if (parsed.kind == QrFrameKind.single) {
      await _decodeAndFinish(parsed.payload);
      return;
    }

    final groupId = parsed.groupId!;
    final buffer = _groups.putIfAbsent(
      groupId,
      () => _MultiGroupBuffer(total: parsed.total!),
    );
    buffer.touch();
    buffer.parts[parsed.index!] = parsed.payload;
    _cleanupExpiredGroups();

    final merged = QrPayloadCodec.mergeEncodedPayloadParts(buffer.parts, buffer.total);
    if (merged == null) {
      Toast.showToast(
          S.of(context).qr_scan_parts_received_toast(buffer.parts.length, buffer.total), context);
      return;
    }

    await _decodeAndFinish(merged);
  }

  Future<void> _decodeAndFinish(String encodedPayload) async {
    try {
      _isCompleting = true;
      final decoded = QrPayloadCodec.decodeEncodedPayload(encodedPayload);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(decoded);
    } catch (e) {
      _isCompleting = false;
      Toast.showToast(_readableError(e), context);
    }
  }

  void _cleanupExpiredGroups() {
    final now = DateTime.now();
    final expired = <String>[];
    _groups.forEach((key, value) {
      if (now.difference(value.updatedAt).inMinutes >= 2) {
        expired.add(key);
      }
    });
    for (final key in expired) {
      _groups.remove(key);
    }
  }

  String _readableError(Object error) {
    if (error is FormatException) {
      final code = error.message;
      if (code == 'unsupported_payload_type' ||
          code == 'unsupported_payload_version' ||
          code == 'unsupported_payload_algorithm') {
        return S.of(context).qr_error_unsupported_protocol;
      }
      if (code == 'checksum_mismatch') {
        return S.of(context).qr_error_checksum_mismatch;
      }
      if (code == 'base64_decode_failed' || code == 'gzip_decode_failed') {
        return S.of(context).qr_error_payload_corrupted;
      }
    }
    return S.of(context).qrcode_read_error_toast;
  }
}

class _MultiGroupBuffer {
  final int total;
  final Map<int, String> parts = <int, String>{};
  DateTime updatedAt = DateTime.now();

  _MultiGroupBuffer({required this.total});

  void touch() {
    updatedAt = DateTime.now();
  }
}
