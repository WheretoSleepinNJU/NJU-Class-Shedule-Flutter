# Environment Setup Issues & Resolution

**Date:** 2026-02-03  
**Branch:** `fix/widget-conflicts-review`

## 🔴 Critical Issues Found

### 1. Missing HarmonyOS Dependencies
**Status:** ❌ Blocking `flutter pub get`

The `external/` directory is missing required HarmonyOS-specific Flutter packages:

```bash
external/
├── flutter_packages/          # ❌ MISSING (partially exists)
├── flutter_sqflite/           # ❌ MISSING (critical - blocks pub get)
└── flutter_plus_plugins/      # ❌ MISSING (partially exists)
```

**Required Actions:**
```bash
cd external
git clone https://gitcode.com/openharmony-tpc/flutter_packages.git
git clone https://gitcode.com/openharmony-sig/flutter_sqflite.git
git clone https://gitcode.com/openharmony-sig/flutter_plus_plugins.git
```

### 2. Flutter Version Mismatch
**Status:** ⚠️ Warning - Will prevent HarmonyOS builds

- **Current:** Flutter 3.22.3 (standard stable channel from flutter/flutter)
- **Required:** Flutter oh-3.27.0 (HarmonyOS-patched fork from openharmony-tpc/flutter_flutter)

**Impact:**
- ✅ iOS development: OK
- ✅ Android development: OK  
- ❌ HarmonyOS development: NOT POSSIBLE

**Resolution for HarmonyOS Development:**
Follow the setup guide in [flutter_flutter oh-3.27.0](https://gitcode.com/openharmony-tpc/flutter_flutter/tree/oh-3.27.0-release) to install the HarmonyOS-patched Flutter SDK.

**Resolution for iOS/Android Only Development:**
If you're only working on iOS/Android (as is the case for the current widget compatibility fixes), you can:
1. Comment out HarmonyOS-specific dependencies in `pubspec.yaml`
2. Use the standard Flutter 3.22.3
3. Skip the `external/` dependencies

### 3. Missing OpenHarmony SDK
**Status:** ⚠️ Expected if not doing HarmonyOS development

`flutter doctor -v` shows no OpenHarmony SDK configuration. This is only required for building HarmonyOS apps.

## 📋 Current Working Status

| Platform | Build Capability | Widget Support |
|----------|------------------|----------------|
| **iOS** | ✅ Ready | ✅ Fully functional (new architecture) |
| **Android** | ✅ Ready | ⚠️ Legacy implementation (not tested) |
| **HarmonyOS** | ❌ Blocked | ✅ Code ready (cannot compile) |

## 🛠 Recommended Setup Per Use Case

### Case A: iOS/Android Development Only
**Current State:** ✅ Ready to use

No action needed for the compatibility fixes. The standard Flutter 3.22.3 + Xcode + Android SDK setup is sufficient.

### Case B: Full Platform Development (Including HarmonyOS)
**Required Steps:**

1. **Install HarmonyOS Flutter SDK:**
   ```bash
   # Follow instructions from:
   # https://gitcode.com/openharmony-tpc/flutter_flutter/tree/oh-3.27.0-release
   ```

2. **Clone Missing Dependencies:**
   ```bash
   cd external
   git clone https://gitcode.com/openharmony-tpc/flutter_packages.git
   git clone https://gitcode.com/openharmony-sig/flutter_sqflite.git
   git clone https://gitcode.com/openharmony-sig/flutter_plus_plugins.git
   ```

3. **Verify Setup:**
   ```bash
   flutter doctor -v
   # Should show both Flutter and OpenHarmony as [✓]
   ```

4. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

## 📝 Notes

- The widget compatibility fixes in this branch focus on iOS/HarmonyOS coexistence at the **code level**
- They do not require HarmonyOS compilation to be verified
- iOS widget testing can proceed immediately with current setup
- HarmonyOS testing requires completing the setup steps above
