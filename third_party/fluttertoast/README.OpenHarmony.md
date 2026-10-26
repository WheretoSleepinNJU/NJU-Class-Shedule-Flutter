# fluttertoast

This project is based on [fluttertoast](https://github.com/PonnamKarthik/FlutterToast).

## Table of Contents

- [Introduction](#introduction)
- [Installation](#installation)
- [Constraints](#constraints)
- [OHOS Development Environment](#ohos-development-environment)
- [Example](#example)
- [Usage](#usage)
- [API Reference](#api-reference)
- [FAQ](#faq)
- [Known Issues](#known-issues)
- [Directory Structure](#directory-structure)
- [Contributing](#contributing)
- [License](#license)

## Introduction

A Flutter Toast library that displays toast messages with a single line of code. Two usage modes are supported:

- **Without BuildContext**: Use `Fluttertoast.showToast()` to invoke native platform toast
- **With BuildContext**: Use `FToast` class to display custom Widget as toast content, with queue management and animations

## Installation

Add the dependency to your project's `pubspec.yaml`:

```yaml
dependencies:
  fluttertoast:
    git:
      url: https://gitcode.com/CPF-Flutter/flutter_fluttertoast.git
      # ref: Select the TAG version that matches your Flutter framework version from the table below
      ref: TAG # 请根据下方版本对应表选择分支
```

Run:

```bash
flutter pub get
```

| Library Version | Flutter Version | TAG | Branch |
|---|---|---|---|
| 9.0.0 | 3.22 | 9.0.0-ohos-1.0.0 | br_v9.0.0_ohos |
| 9.0.0 | 3.27 | 9.0.0-ohos-1.0.0 | br_v9.0.0_ohos |
| 9.0.0 | 3.35 | 9.0.0-ohos-1.0.0 | br_v9.0.0_ohos |

### Version Upgrade & Migration

- Upgrading from upstream `fluttertoast@8.x` to this library `9.0.0`: APIs are largely compatible; `Fluttertoast.showToast` / `FToast` usage remains unchanged. Select the TAG that matches your Flutter framework from the table above.
- Cross Flutter framework upgrade (e.g. 3.7 → 3.22 / 3.27 / 3.35): Only change the `ref` in `pubspec.yaml` to the matching TAG, then run `flutter pub get` again.
- OHOS custom fonts: Use `fontAssetOhosPath` (HarmonyOS-specific parameter). Do not confuse it with the cross-platform `fontAsset` parameter.

## Constraints

### Compatibility

Verified on the following versions:

| Library Version | Flutter (OHOS) | DevEco Studio | SDK | ROM |
|---|---|---|---|---|
| 9.0.0 | 3.22.3-ohos-1.0.1 | 6.1.0.860 | 6.1.0(23) | 6.0.0.120 SP6 |
| 9.0.0 | 3.27.5-ohos-1.0.1 | 6.1.0.860 | 6.1.0(23) | 6.0.0.120 SP6 |
| 9.0.0 | 3.35.7-ohos-0.0.1 | 6.1.0.860 | 6.1.0(23) | 6.0.0.120 SP6 |

### Permissions

None.

## OHOS Development Environment

1. **Install DevEco Studio**: Download and install a DevEco Studio version matching the compatibility table above.
2. **Configure HarmonyOS SDK**: Install the corresponding API-level SDK in DevEco Studio (e.g. API 12 / API 21).
3. **Configure Flutter OHOS SDK**: Install the Flutter OHOS engine matching your target Flutter version (e.g. `3.22.3-ohos-1.0.1`).
4. **Fetch dependencies**: Run `flutter pub get` in the project root.
5. **Build and run**: Enter the `example` directory and run `flutter build hap`, or open `example/ohos` in DevEco Studio for device/emulator debugging.

> A complete runnable sample is available under [example](./example/).

## Example

### Toast Without BuildContext

```dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Show a short toast
Fluttertoast.showToast(
  msg: "This is Short Toast",
  toastLength: Toast.LENGTH_SHORT,
  gravity: ToastGravity.BOTTOM,
  backgroundColor: Colors.black,
  textColor: Colors.white,
  fontSize: 16.0,
);

// Cancel current toast
Fluttertoast.cancel();
```

### Toast With BuildContext

```dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Configure builder in MaterialApp (required, otherwise Overlay is unavailable)
MaterialApp(
  builder: FToastBuilder(),
  home: MyApp(),
  navigatorKey: navigatorKey,
);

// Initialize FToast
FToast fToast = FToast();
fToast.init(context);

// Show custom toast
Widget toast = Container(
  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(25.0),
    color: Colors.greenAccent,
  ),
  child: Text("This is a Custom Toast"),
);

fToast.showToast(
  child: toast,
  gravity: ToastGravity.BOTTOM,
  toastDuration: Duration(seconds: 2),
);

// Remove current toast
fToast.removeCustomToast();

// Clear toast queue
fToast.removeQueuedCustomToasts();
```

### OHOS Custom Font (fontAssetOhosPath)

The `example` project already includes `assets/HarmonyOS_Sans_Black_Italic.ttf`. You can run it directly.

```dart
import 'package:fluttertoast/fluttertoast.dart';

Fluttertoast.showToast(
  msg: "This is Short Toast",
  toastLength: Toast.LENGTH_SHORT,
  // fontAsset: cross-platform font asset id (Android/iOS, etc.)
  fontAsset: 'font style test',
  // fontAssetOhosPath: HarmonyOS-only parameter; path to a font file in Flutter assets.
  // When set, OHOS shows toast via a custom dialog (supports cancel) instead of system toast.
  fontAssetOhosPath: 'assets/HarmonyOS_Sans_Black_Italic.ttf',
);
```

## Usage

### Without BuildContext

`Fluttertoast.showToast()` displays toast messages via native platform toast, suitable for simple text prompts. This method communicates with the platform through MethodChannel and returns `Future<bool?>`.

> **OpenHarmony**: When using custom fonts, specify the font path via `fontAssetOhosPath`. The OHOS side will display the toast using a custom dialog. System toast mode does not support cancel (HarmonyOS platform limitation).

### With BuildContext

`FToast` uses Flutter Overlay to display custom Widgets, supporting queue management, fade animations, custom positioning, and other advanced features.

> When using `FToast`, you must add `FToastBuilder()` to `MaterialApp.builder`, otherwise the Overlay will not be available.

## API Reference

### Fluttertoast

| Name | Return Type | Description | OHOS Support |
|------|-------------|-------------|--------------|
| `showToast({required String msg, ...})` | `Future<bool?>` | Show native toast | Yes |
| `cancel()` | `Future<bool?>` | Cancel current toast | Yes (custom font only) |

**showToast Parameters** (`Fluttertoast.showToast`, native platform toast):

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| msg | String | Required | Toast message content |
| toastLength | Toast? | Toast.LENGTH_SHORT | Display duration |
| gravity | ToastGravity? | ToastGravity.BOTTOM | Display position |
| backgroundColor | Color? | Colors.black | Background color |
| textColor | Color? | Colors.white | Text color |
| fontSize | double? | null | Font size; when null, system default is kept |
| fontAsset | String? | null | Font file path (Flutter asset, cross-platform) |
| fontAssetOhosPath | String? | null | OHOS-only font path; when set, uses custom dialog |
| timeInSecForIosWeb | int | 1 | Display duration for iOS/Web |

### FToast

| Name | Return Type | Description | OHOS Support |
|------|-------------|-------------|--------------|
| `FToast()` | `FToast` | Factory constructor | Yes |
| `FToastBuilder()` | `TransitionBuilder` | Builder required by MaterialApp.builder | Yes |
| `init(BuildContext context)` | `FToast` | Initialize and save context | Yes |
| `showToast({required Widget child, ...})` | `void` | Show custom Widget toast | Yes |
| `removeCustomToast()` | `void` | Remove current toast | Yes |
| `removeQueuedCustomToasts()` | `void` | Clear queue | Yes |
| `context` | `BuildContext?` | Stored context | Yes |

**showToast Parameters** (`FToast.showToast`, custom Widget toast; different from `Fluttertoast.showToast`):

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| child | Widget | Required | Toast content |
| toastDuration | Duration | Duration(seconds: 2) | Display duration |
| gravity | ToastGravity? | null | Display position |
| positionedToastBuilder | PositionedToastBuilder? | null | Custom position builder |
| fadeDuration | Duration | Duration(milliseconds: 350) | Fade animation duration |
| ignorePointer | bool | false | Whether to ignore pointer events |
| isDismissible | bool | false | Whether toast can be dismissed by tap |

### Enums

**Toast**:

| Value | Description |
|-------|-------------|
| LENGTH_SHORT | Short duration (~2 seconds) |
| LENGTH_LONG | Long duration (~3.5 seconds) |

**ToastGravity**:

| Value | Description |
|-------|-------------|
| TOP | Top |
| BOTTOM | Bottom |
| CENTER | Center |

## FAQ

### Cancel does not work for system toast

`Fluttertoast.cancel()` only works when custom fonts are used (with `fontAssetOhosPath` parameter and font already loaded). Without custom fonts, the system `promptAction.showToast()` is used, and HarmonyOS does not provide a cancel API for system toast. This is a HarmonyOS platform API limitation.

### Platform.isOhos error on Android after upgrading to 9.0.0

v9.0.0 added `Platform.isOhos` check in `lib/fluttertoast.dart`, which imports `dart:io` at compile time. Ensure you are using Flutter >= 3.7.x and do not use this library on Web (Web does not support `dart:io`).

### Custom font toast uses dialog

On OHOS, custom font scenarios use `promptAction.openCustomDialog` instead of native toast, which differs from Android/iOS Toast behavior. Position and style differences are expected.

## Known Issues

- **System toast does not support cancel**: `promptAction.showToast()` has no cancel API. `Fluttertoast.cancel()` cannot immediately dismiss a system toast when no custom font is used. This is a HarmonyOS platform API limitation.

## Directory Structure

```
├── lib/                  # Dart public API
│   └── fluttertoast.dart
├── ohos/                 # OHOS platform implementation
│   ├── index.ets
│   └── src/main/ets/toast/
│       ├── FlutterToastPlugin.ets  # Plugin main class
│       ├── CustomToastDialog.ets   # Custom dialog utility
│       └── CustomToastView.ets     # Custom dialog view component
├── android/              # Android platform implementation
├── ios/                  # iOS platform implementation
├── example/              # Example app
│   └── lib/
│       ├── main.dart
│       ├── toast_no_context.dart   # No BuildContext example
│       └── toast_context.dart      # With BuildContext example
└── assets/               # Static assets
```

## Contributing

If you encounter any issues, please submit them at [GitCode Issues](https://gitcode.com/CPF-Flutter/flutter_fluttertoast/issues).

## License

This project is open sourced under [Apache License 2.0](LICENSE).
