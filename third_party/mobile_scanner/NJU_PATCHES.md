# mobile_scanner privacy compatibility patch

Source: https://gitcode.com/CPF-Flutter/fluttertpc_mobile_scanner.git
Commit: 789adb2638ce9063376baeacc9909aad003db48b
Version: 7.1.4-ohos-1.0.0-beta.1
License: BSD-3-Clause (see LICENSE).

This source snapshot retains the existing Dart, OHOS, and Apple Vision code.
Examples, upstream tests, build outputs, and repository metadata are omitted.

The vivo engine-two report traces startup sensor access to
`DeviceOrientationListener -> MobileScannerHandler -> MobileScannerPlugin`,
during generated plugin registration. The Android `OrientationEventListener`
constructor itself queries SensorManager, even before `enable()` is called.

The Android listener now uses composition and creates the underlying listener
only in `start()`, after the scanner has started the camera. `stop()` does not
create a listener. Direction mapping and the Flutter event channel are retained.
This follows the same fix as upstream commit
https://github.com/juliansteenbakker/mobile_scanner/commit/f9c81ea0b573d9146889fc70b599bf1f3920e35c
without replacing the OHOS implementation with an unsupported upstream version.

The only runtime source change is DeviceOrientationListener.kt. A factory seam
allows JVM tests to verify no sensor construction at registration/disposal,
one construction across camera restarts, and missing-sensor behavior. The
Android test dependencies use JUnit 4 / Mockito 5.18.0; these are not packaged
in the app. The package stays in the repository so CI and clean checkouts use
the same patch without editing a global Pub cache.
