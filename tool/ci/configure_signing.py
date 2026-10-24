#!/usr/bin/env python3
"""Prepare ephemeral CI signing files. Never print secret values."""
import argparse
import base64
import json
import os
from pathlib import Path
import plistlib
import secrets
import subprocess


def required(name):
    value = os.environ.get(name, "")
    if not value:
        raise SystemExit(f"Missing GitHub secret: {name}")
    return value


def write_private(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.touch(mode=0o600, exist_ok=True)
    path.chmod(0o600)
    path.write_bytes(content)
    return path


def decode_secret(name, path):
    data = base64.b64decode("".join(required(name).split()), validate=True)
    if not data:
        raise SystemExit(f"Empty signing file: {name}")
    return write_private(path, data)


def java_property(value):
    # Properties.load(InputStream) uses Latin-1 and backslash escapes.
    escaped = []
    controls = {"\\": r"\\", "\n": r"\n", "\r": r"\r", "\t": r"\t", "\f": r"\f"}
    for char in value:
        if char in controls:
            escaped.append(controls[char])
        elif char in " =:#!":
            escaped.append("\\" + char)
        elif 32 <= ord(char) < 127:
            escaped.append(char)
        else:
            encoded = char.encode("utf-16-be")
            escaped.extend(f"\\u{int.from_bytes(encoded[i:i+2], 'big'):04x}"
                           for i in range(0, len(encoded), 2))
    return "".join(escaped)


def android(root, temp):
    keystore = decode_secret("ANDROID_KEYSTORE_BASE64", temp / "android.jks")
    values = {
        "storeFile": str(keystore),
        "storePassword": required("ANDROID_STORE_PASSWORD"),
        "keyAlias": required("ANDROID_KEY_ALIAS"),
        "keyPassword": required("ANDROID_KEY_PASSWORD"),
    }
    write_private(root / "android/key.properties", "".join(
        f"{key}={java_property(value)}\n" for key, value in values.items()
    ).encode("ascii"))


def ohos(root):
    import json5  # CI installs the pinned version before calling this command.
    path = root / "ohos/build-profile.json5"
    config = json5.loads(path.read_text())
    config["app"]["signingConfigs"] = []
    for product in config["app"]["products"]:
        product.pop("signingConfig", None)
    write_private(path, (json.dumps(config, ensure_ascii=False, indent=2) + "\n").encode())


def ios(root, temp):
    p12 = decode_secret("IOS_P12_BASE64", temp / "ios.p12")
    keychain = temp / "ci-signing.keychain-db"
    password = secrets.token_urlsafe(32)
    # The generated keychain password is never logged or persisted in the repo.
    subprocess.run(["security", "create-keychain", "-p", password, str(keychain)], check=True)
    subprocess.run(["security", "set-keychain-settings", "-lut", "21600", str(keychain)], check=True)
    subprocess.run(["security", "unlock-keychain", "-p", password, str(keychain)], check=True)
    subprocess.run(["security", "import", str(p12), "-P", required("IOS_P12_PASSWORD"),
                    "-A", "-t", "cert", "-f", "pkcs12", "-k", str(keychain)],
                   check=True, stdout=subprocess.DEVNULL)
    subprocess.run(["security", "set-key-partition-list", "-S", "apple-tool:,apple:,codesign:",
                    "-s", "-k", password, str(keychain)], check=True, stdout=subprocess.DEVNULL)
    subprocess.run(["security", "list-keychains", "-d", "user", "-s", str(keychain),
                    str(Path.home() / "Library/Keychains/login.keychain-db")], check=True)

    bundle_ids = {
        "Runner": "top.idealclover.wheretosleepinnju",
        "ScheduleWidgetExtension": "top.idealclover.wheretosleepinnju.ScheduleWidgetExtension",
    }
    profiles = {}
    team = required("IOS_TEAM_ID")
    for target, secret in [("Runner", "IOS_APP_PROFILE_BASE64"),
                           ("ScheduleWidgetExtension", "IOS_WIDGET_PROFILE_BASE64")]:
        profile = decode_secret(secret, temp / f"{target}.mobileprovision")
        result = subprocess.run(["security", "cms", "-D", "-i", str(profile)],
                                check=True, capture_output=True)
        data = plistlib.loads(result.stdout)
        app_id = data["Entitlements"]["application-identifier"]
        if app_id != f"{team}.{bundle_ids[target]}" or team not in data["TeamIdentifier"]:
            raise SystemExit(f"Wrong team or bundle ID in {secret}")
        destination = Path.home() / "Library/MobileDevice/Provisioning Profiles" / f"{data['UUID']}.mobileprovision"
        write_private(destination, profile.read_bytes())
        profiles[target] = data["UUID"]
    # A separate profile is required for the Widget extension.
    metadata = {"team": team, "profiles": profiles}
    write_private(temp / "ios-signing.json", json.dumps(metadata).encode())
    export = {
        "method": "app-store-connect", "teamID": team, "signingStyle": "manual",
        "signingCertificate": "Apple Distribution", "uploadSymbols": True,
        "provisioningProfiles": {bundle_ids[target]: uuid for target, uuid in profiles.items()},
    }
    write_private(temp / "ExportOptions.plist", plistlib.dumps(export))
    subprocess.run(["ruby", str(root / "tool/ci/configure_ios_signing.rb"),
                    str(root / "ios/Runner.xcodeproj"), str(temp / "ios-signing.json")], check=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("platform", choices=["android", "ios", "ohos"])
    parser.add_argument("--signed", action="store_true")
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[2]
    temporary = Path(required("RUNNER_TEMP")) / "nju-signing"
    temporary.mkdir(parents=True, exist_ok=True)
    if args.platform == "ohos":
        ohos(project)
    elif args.signed:
        try:
            {"android": android, "ios": ios}[args.platform](project, temporary)
        except subprocess.CalledProcessError:
            raise SystemExit("Native signing setup failed; command arguments omitted to protect credentials") from None
