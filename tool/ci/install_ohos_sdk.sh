#!/usr/bin/env bash
set -euo pipefail
# Huawei's 26.0.0.851 Linux bundle, mirrored as Git volumes because the official
# download URL is signed and expires. Verify the original archive before use.
sdk_version=26.0.0.851
sdk_commit=73941bbcbc9783fca65761de79dad738987dff12
sdk_remote=https://gitcode.com/rustzhang/harmonyos-sdk.git
sdk_root="${RUNNER_TEMP:?}/harmonyos/command-line-tools"
archive="${RUNNER_TEMP}/harmonyos-tools.zip"
sdk_git_dir="${RUNNER_TEMP}/harmonyos-tools.git"
printf 'Installing HarmonyOS Command Line Tools %s\n' "$sdk_version"
git init --bare --quiet "$sdk_git_dir"
git --git-dir="$sdk_git_dir" fetch --depth 1 "$sdk_remote" "$sdk_commit"
test "$(git --git-dir="$sdk_git_dir" rev-parse FETCH_HEAD)" = "$sdk_commit"
for number in {0..22}; do
  printf -v part 'part-%03d' "$number"
  git --git-dir="$sdk_git_dir" show "$sdk_commit:$part"
done > "$archive"
# Checksum is pinned alongside the SDK version; update both on SDK upgrades.
# Also recorded by the v26.0.0 devecostudio-linux PKGBUILD for Huawei's archive.
echo "ab604bd92721d5cbcafd154e6461d46b9f1b105e7b89eab04a9d046681198082  $archive" | sha256sum --check
rm -rf "$sdk_git_dir"
mkdir -p "${RUNNER_TEMP}/harmonyos"
unzip -q "$archive" -d "${RUNNER_TEMP}/harmonyos"
rm "$archive"
test -x "$sdk_root/tool/node/bin/node"
test -d "$sdk_root/sdk"
python3 - "$sdk_root/sdk/default/sdk-pkg.json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))['data']
if int(data['apiVersion']) < 26:
    raise SystemExit('The pinned Flutter engine requires HarmonyOS SDK API 26 or newer')
print(f"HarmonyOS SDK {data['platformVersion']} (API {data['apiVersion']})")
PY
printf 'DEVECO_SDK_HOME=%s\nNODE_HOME=%s\n' "$sdk_root/sdk" "$sdk_root/tool/node" >> "$GITHUB_ENV"
printf '%s\n' "$sdk_root/tool/node/bin" "$sdk_root/ohpm/bin" \
  "$sdk_root/hvigor/bin" "$sdk_root/bin" >> "$GITHUB_PATH"
