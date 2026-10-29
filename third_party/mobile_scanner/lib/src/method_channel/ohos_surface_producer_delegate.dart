import 'package:flutter/services.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/method_channel/surface_producer_delegate.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/utils/parse_device_orientation_extension.dart';

/// This class will manage the orientation corrections for textures
/// that are provided by the OHOS platform.
class OhosSurfaceProducerDelegate implements SurfaceProducerDelegate {
  /// Construct a new [OhosSurfaceProducerDelegate].
  OhosSurfaceProducerDelegate({
    required this.cameraFacingDirection,
    required this.handlesCropAndRotation,
    required this.initialDeviceOrientation,
    required this.sensorOrientationDegrees,
  });

  /// Construct a new [OhosSurfaceProducerDelegate]
  /// from the given [config] and [cameraDirection].
  ///
  /// Throws a [MobileScannerException] if the configuration is invalid.
  factory OhosSurfaceProducerDelegate.fromConfiguration(
    Map<String, Object?> config,
    CameraFacing cameraDirection,
  ) {
    // For OHOS platform, use Flutter's RotatedPreview to handle rotation
    const bool handlesCropAndRotation = false;
    // Get sensor orientation from config or use default value
    final int sensorOrientation = config['sensorOrientation'] as int? ?? 90;

    // Try to get initial device orientation from config
    final String naturalDeviceOrientation = config['naturalDeviceOrientation'] as String? ?? 'PORTRAIT_UP';
    final naturalOrientation = naturalDeviceOrientation.parseDeviceOrientation();

    return OhosSurfaceProducerDelegate(
      cameraFacingDirection: cameraDirection,
      handlesCropAndRotation: handlesCropAndRotation,
      initialDeviceOrientation: naturalOrientation,
      sensorOrientationDegrees: sensorOrientation.toDouble(),
    );
  }

  /// The facing direction of the active camera.
  final CameraFacing cameraFacingDirection;

  /// Whether the underlying surface producer handles crop and rotation.
  ///
  /// If this is false, the preview needs to be manually rotated.
  final bool handlesCropAndRotation;

  /// The initial device orientation when this [OhosSurfaceProducerDelegate]
  /// is created.
  final DeviceOrientation initialDeviceOrientation;

  /// The orientation of the camera sensor on the device, in degrees.
  final double sensorOrientationDegrees;
}
