import '../../AdaptiveUI/adaptive_ui.dart';
import 'dart:async';

import '../../generated/l10n.dart';
import '../../Components/Toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRShareView extends StatefulWidget {
  final List<String> frames;
  final String singleShareText;

  const QRShareView({
    Key? key,
    required this.frames,
    required this.singleShareText,
  }) : super(key: key);

  @override
  State<QRShareView> createState() => _QRShareViewState();
}

class _QRShareViewState extends State<QRShareView> with WidgetsBindingObserver {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startAnimation();
  }

  void _startAnimation() {
    _timer?.cancel();
    if (widget.frames.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _index = (_index + 1) % widget.frames.length);
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startAnimation();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.frames[_index];
    final progress = widget.frames.length > 1
        ? '${_index + 1}/${widget.frames.length}'
        : '1/1';

    return AdaptiveScaffold(
      appBar: AdaptiveTopAppBar(title: Text(S.of(context).export_title)),
      body: SafeArea(
        child: AdaptivePageScroll(
          child: AdaptiveSection(
            padding: const EdgeInsets.all(16),
            separated: false,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: QrImageView(
                  data: current,
                  version: QrVersions.auto,
                  size: 260.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const Padding(padding: EdgeInsets.all(8)),
              Text(
                'QR $progress',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const Padding(padding: EdgeInsets.all(8)),
              Text(
                S.of(context).import_from_qrcode_content,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const Padding(padding: EdgeInsets.all(6)),
              AdaptiveButton.elevated(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: widget.singleShareText),
                  );
                  if (!mounted) {
                    return;
                  }
                  Toast.showToast(
                    S.of(context).qr_share_copy_success_toast,
                    context,
                  );
                },
                child: Text(S.of(context).qr_share_copy_button),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
