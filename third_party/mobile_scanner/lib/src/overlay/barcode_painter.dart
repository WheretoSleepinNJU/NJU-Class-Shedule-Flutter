import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A [CustomPainter] that draws the barcode as an outlined barcode box with
/// rounded corners and a displayed value.
class BarcodePainter extends CustomPainter {
  /// Construct a new [BarcodePainter] instance.
  const BarcodePainter({
    required this.barcodeCorners,
    required this.barcodeSize,
    required this.barcodeValue,
    required this.boxFit,
    required this.cameraPreviewSize,
    required this.color,
    required this.style,
    required this.textPainter,
    required this.deviceOrientation,
    this.strokeWidth = 4.0,
  });

  /// The corners of the barcode.
  final List<Offset> barcodeCorners;

  /// The size of the barcode.
  final Size barcodeSize;

  /// The barcode value to display inside the overlay.
  final String barcodeValue;

  /// The BoxFit mode for scaling the barcode bounding box.
  final BoxFit boxFit;

  /// The camera preview size.
  final Size cameraPreviewSize;

  /// The color of the outline.
  final Color color;

  /// The drawing style (stroke/fill).
  final PaintingStyle style;

  /// The painter which paints the text object in the overlay.
  final TextPainter textPainter;

  /// The width of the border.
  final double strokeWidth;

  /// The orientation of the device.
  final DeviceOrientation deviceOrientation;

  @override
  void paint(Canvas canvas, Size size) {
    if (barcodeCorners.length < 4 ||
        barcodeSize.isEmpty ||
        cameraPreviewSize.isEmpty) {
      return;
    }

    final isLandscape =
        deviceOrientation == DeviceOrientation.landscapeLeft ||
        deviceOrientation == DeviceOrientation.landscapeRight;

    final adjustedCameraPreviewSize =
        isLandscape ? cameraPreviewSize.flipped : cameraPreviewSize;

    final ratios = calculateBoxFitRatio(
      boxFit,
      adjustedCameraPreviewSize,
      size,
    );

    final horizontalPadding =
        (adjustedCameraPreviewSize.width * ratios.widthRatio - size.width) / 2;
    final verticalPadding =
        (adjustedCameraPreviewSize.height * ratios.heightRatio - size.height) /
        2;

    final adjustedOffset = <Offset>[
      for (final offset in barcodeCorners)
        Offset(
          offset.dx * ratios.widthRatio - horizontalPadding,
          offset.dy * ratios.heightRatio - verticalPadding,
        ),
    ];

    if (adjustedOffset.length < 4) return;

    // Draw the rotated rectangle
    final path = Path()..addPolygon(adjustedOffset, true);

    final paint =
        Paint()
          ..color = color
          ..style = style
          ..strokeWidth = strokeWidth;

    canvas.drawPath(path, paint);

    // Find center point of the barcode
    final centerX = (adjustedOffset[0].dx + adjustedOffset[2].dx) / 2;
    final centerY = (adjustedOffset[0].dy + adjustedOffset[2].dy) / 2;
    final center = Offset(centerX, centerY);

    // Calculate rotation angle
    final angle = math.atan2(
      adjustedOffset[1].dy - adjustedOffset[0].dy,
      adjustedOffset[1].dx - adjustedOffset[0].dx,
    );

    // Set a smaller font size with auto-resizing logic
    final textSize =
        (barcodeSize.width * ratios.widthRatio) *
        0.08; // Scales with barcode size
    const double minTextSize = 6; // Minimum readable size
    const double maxTextSize = 12; // Maximum size
    final finalTextSize = textSize.clamp(minTextSize, maxTextSize);

    // Draw barcode value inside the overlay with rotation
    final textSpan = TextSpan(
      text: barcodeValue,
      style: TextStyle(
        color: Colors.black, // Ensuring black text
        fontSize: finalTextSize,
        fontWeight: FontWeight.bold,
      ),
    );

    textPainter.text = textSpan;
    textPainter.layout(maxWidth: barcodeSize.width * ratios.widthRatio * 0.6);

    final textWidth = textPainter.width;
    final textHeight = textPainter.height;

    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(angle) // Rotate the text to match the barcode
      ..translate(-center.dx, -center.dy);

    final textRect = Rect.fromCenter(
      center: center,
      width: textWidth * 1.1,
      height: textHeight * 1.1,
    );

    final textBackground = RRect.fromRectAndRadius(
      textRect,
      const Radius.circular(6),
    );

    final textBgPaint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    canvas.drawRRect(textBackground, textBgPaint);

    textPainter.paint(
      canvas,
      Offset(center.dx - textWidth / 2, center.dy - textHeight / 2),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(BarcodePainter oldDelegate) {
    const listEquality = ListEquality<Offset>();

    return !listEquality.equals(oldDelegate.barcodeCorners, barcodeCorners) ||
        oldDelegate.barcodeSize != barcodeSize ||
        oldDelegate.boxFit != boxFit ||
        oldDelegate.cameraPreviewSize != cameraPreviewSize ||
        oldDelegate.color != color ||
        oldDelegate.style != style ||
        oldDelegate.barcodeValue != barcodeValue ||
        oldDelegate.deviceOrientation != deviceOrientation;
  }
}

/// Calculate the scaling ratios for width and height to fit the small box
/// (cameraPreviewSize) into the large box (size) based on the specified BoxFit
/// mode. Returns a record containing the width and height scaling ratios.
({double widthRatio, double heightRatio}) calculateBoxFitRatio(
  BoxFit boxFit,
  Size cameraPreviewSize,
  Size size,
) {
  // If the width or height of cameraPreviewSize or size is 0, return (1.0, 1.0)
  // (no scaling)
  if (cameraPreviewSize.width <= 0 ||
      cameraPreviewSize.height <= 0 ||
      size.width <= 0 ||
      size.height <= 0) {
    return (widthRatio: 1.0, heightRatio: 1.0);
  }

  // Calculate the scaling ratios for width and height
  final widthRatio = size.width / cameraPreviewSize.width;
  final heightRatio = size.height / cameraPreviewSize.height;

  switch (boxFit) {
    case BoxFit.fill:
      // Stretch to fill the large box without maintaining aspect ratio
      return (widthRatio: widthRatio, heightRatio: heightRatio);

    case BoxFit.contain:
      // Maintain aspect ratio, ensure the content fits entirely within the
      // large box
      final double ratio = math.min(widthRatio, heightRatio);
      return (widthRatio: ratio, heightRatio: ratio);

    case BoxFit.cover:
      // Maintain aspect ratio, ensure the content fully covers the large box
      final double ratio = math.max(widthRatio, heightRatio);
      return (widthRatio: ratio, heightRatio: ratio);

    case BoxFit.fitWidth:
      // Maintain aspect ratio, ensure the width matches the large box
      return (widthRatio: widthRatio, heightRatio: widthRatio);

    case BoxFit.fitHeight:
      // Maintain aspect ratio, ensure the height matches the large box
      return (widthRatio: heightRatio, heightRatio: heightRatio);

    case BoxFit.none:
      // No scaling
      return (widthRatio: 1.0, heightRatio: 1.0);

    case BoxFit.scaleDown:
      // If the content is larger than the large box, scale down to fit;
      // otherwise, no scaling
      final ratio = math.min(1, math.min(widthRatio, heightRatio)).toDouble();
      return (widthRatio: ratio, heightRatio: ratio);
  }
}
