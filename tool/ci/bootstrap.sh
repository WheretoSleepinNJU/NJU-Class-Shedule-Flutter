#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."

# Keep one OHOS Flutter SDK for Android, iOS, HarmonyOS and host tests.
flutter_ref=3.47.7+ohos-0.0.1-pre
flutter_commit=650641656fef1d0578f0bc1ed8f7a35087fc99f3
flutter_repo=https://gitcode.com/openharmony-sig/flutter_flutter.git
flutter_dir=.fvm/flutter_sdk
checkout_dependency() {
  local destination=$1 remote=$2 commit=$3 tag=${4:-}
  local ref=$commit tag_commit=$commit
  if [[ ! -d "$destination/.git" ]]; then
    mkdir -p "$destination"
    git -C "$destination" init --quiet
    git -C "$destination" remote add origin "$remote"
  fi
  if [[ -n "$tag" ]]; then
    # Flutter discovers its version from local tags, not FETCH_HEAD.
    ref="refs/tags/$tag:refs/tags/$tag"
    tag_commit=$(git -C "$destination" rev-parse --verify "refs/tags/$tag^{commit}" 2>/dev/null || true)
  fi
  if [[ "$(git -C "$destination" rev-parse HEAD 2>/dev/null || true)" != "$commit" || "$tag_commit" != "$commit" ]]; then
    git -C "$destination" fetch --depth 1 origin "$ref"
    git -C "$destination" checkout --detach "$commit"
    if [[ -n "$tag" ]]; then
      # Recompute version metadata after repairing an incomplete SDK cache.
      rm -f "$destination/bin/cache/flutter.version.json" "$destination/version"
    fi
  fi
  test "$(git -C "$destination" rev-parse HEAD)" = "$commit"
  if [[ -n "$tag" ]]; then
    test "$(git -C "$destination" rev-parse "refs/tags/$tag^{commit}")" = "$commit"
  fi
}

checkout_dependency "$flutter_dir" "$flutter_repo" "$flutter_commit" "$flutter_ref"
checkout_dependency external/flutter_packages \
  https://gitcode.com/openharmony-tpc/flutter_packages.git \
  9c8d592e7d68bc5f1fbe169969111f54347130e7
checkout_dependency external/flutter_plus_plugins_package_info_plus \
  https://gitcode.com/nutpi/flutter_plus_plugins_package_info_plus.git \
  d2f3666aa9767d11756edb78e9cc6bd130e6a4e0
checkout_dependency external/fluttertpc_device_calendar \
  https://gitcode.com/openharmony-sig/fluttertpc_device_calendar.git \
  2b81c4dd8025f1c497104edf3b049e431feac88a

checkout_dependency external/adaptive_platform_ui \
  https://github.com/berkaycatak/adaptive_platform_ui.git \
  04f81286f7a1b8fbb67c489aa8d0cd663b5cd3ed
python3 tool/ci/apply_dependency_patches.py

export FLUTTER_ROOT="$PWD/$flutter_dir"
export PUB_CACHE="$PWD/.fvm/pub-cache"
export PATH="$FLUTTER_ROOT/bin:$PATH"
if [[ -n "${GITHUB_ENV:-}" ]]; then
  printf 'FLUTTER_ROOT=%s\nPUB_CACHE=%s\n' "$FLUTTER_ROOT" "$PUB_CACHE" >> "$GITHUB_ENV"
  printf '%s\n' "$FLUTTER_ROOT/bin" >> "$GITHUB_PATH"
fi
flutter --version
# Pub regenerates tooling for every enabled platform. The OHOS job enables
# HarmonyOS support after installing its SDK; tests, Android and iOS do not need it.
flutter config --no-analytics
flutter config --no-enable-ohos
flutter pub get --enforce-lockfile
