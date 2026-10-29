import 'package:flutter/services.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';

/// Base interface for surface producer delegates that manage orientation corrections.
abstract class SurfaceProducerDelegate {
  /// The facing direction of the active camera.
  CameraFacing get cameraFacingDirection;

  /// Whether the underlying surface producer handles crop and rotation.
  bool get handlesCropAndRotation;

  /// The initial device orientation when this delegate is created.
  DeviceOrientation get initialDeviceOrientation;

  /// The orientation of the camera sensor on the device, in degrees.
  double get sensorOrientationDegrees;
}
