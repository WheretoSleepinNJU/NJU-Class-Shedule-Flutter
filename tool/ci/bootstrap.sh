#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."

# Keep these commits aligned with .fvmrc and the path dependencies in pubspec.yaml.
flutter_ref=3.35.8-ohos-1.0.4
flutter_commit=8320f6ded3f0bdc5409545e26dcd2596bf054203
checkout_dependency() {
  local destination=$1 remote=$2 commit=$3 ref=${4:-$3}
  if [[ ! -d "$destination/.git" ]]; then
    mkdir -p "$destination"
    git -C "$destination" init --quiet
    git -C "$destination" remote add origin "$remote"
  fi
  if [[ "$(git -C "$destination" rev-parse HEAD 2>/dev/null || true)" != "$commit" ]]; then
    git -C "$destination" fetch --depth 1 origin "$ref"
    git -C "$destination" checkout --detach "$commit"
  fi
  test "$(git -C "$destination" rev-parse HEAD)" = "$commit"
}

checkout_dependency .fvm/flutter_sdk \
  https://gitcode.com/CPF-Flutter/flutter_flutter.git "$flutter_commit" "$flutter_ref"
checkout_dependency external/flutter_packages \
  https://gitcode.com/openharmony-tpc/flutter_packages.git \
  9c8d592e7d68bc5f1fbe169969111f54347130e7
checkout_dependency external/flutter_plus_plugins_package_info_plus \
  https://gitcode.com/nutpi/flutter_plus_plugins_package_info_plus.git \
  d2f3666aa9767d11756edb78e9cc6bd130e6a4e0
checkout_dependency external/fluttertpc_device_calendar \
  https://gitcode.com/openharmony-sig/fluttertpc_device_calendar.git \
  2b81c4dd8025f1c497104edf3b049e431feac88a

export FLUTTER_ROOT="$PWD/.fvm/flutter_sdk"
export PUB_CACHE="$PWD/.fvm/pub-cache"
export PATH="$FLUTTER_ROOT/bin:$PATH"
if [[ -n "${GITHUB_ENV:-}" ]]; then
  printf 'FLUTTER_ROOT=%s\nPUB_CACHE=%s\n' "$FLUTTER_ROOT" "$PUB_CACHE" >> "$GITHUB_ENV"
  printf '%s\n' "$FLUTTER_ROOT/bin" >> "$GITHUB_PATH"
fi
flutter --version
flutter config --no-analytics --enable-ohos
flutter pub get --enforce-lockfile
