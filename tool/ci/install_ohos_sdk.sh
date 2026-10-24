#!/usr/bin/env bash
set -euo pipefail
# The pinned Linux bundle used by SDL's official HarmonyOS build action:
# https://github.com/libsdl-org/SDL/blob/main/.github/actions/setup-harmonyos-toolchain/action.yml
sdk_version=6.1.1.280
sdk_root="${RUNNER_TEMP:?}/harmonyos/command-line-tools"
archive="${RUNNER_TEMP}/harmonyos-tools.zip"
curl --fail --location --retry 3 \
  "https://libsdl.org/harmonyos-devtools/commandline-tools-linux-x64-${sdk_version}.zip" \
  --output "$archive"
# Checksum is pinned alongside the SDK version; update both on SDK upgrades.
echo "b9caf7b73c541b90e6c8f3c7c3de7f2bea9b35e41e80cd3525f2f759ebf16cf4  $archive" | sha256sum --check
mkdir -p "${RUNNER_TEMP}/harmonyos"
unzip -q "$archive" -d "${RUNNER_TEMP}/harmonyos"
rm "$archive"
test -x "$sdk_root/tool/node/bin/node"
test -d "$sdk_root/sdk"
printf 'DEVECO_SDK_HOME=%s\n' "$sdk_root/sdk" >> "$GITHUB_ENV"
printf '%s\n' "$sdk_root/tool/node/bin" "$sdk_root/ohpm/bin" \
  "$sdk_root/hvigor/bin" "$sdk_root/bin" >> "$GITHUB_PATH"
