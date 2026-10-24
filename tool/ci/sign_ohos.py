#!/usr/bin/env python3
"""Sign and verify a HAP with the SDK tool, without DevEco's machine-local password encryption."""
import json
import os
from pathlib import Path
import re
import subprocess

from configure_signing import decode_secret, required

root = Path(__file__).resolve().parents[2]
temp = Path(required("RUNNER_TEMP")) / "nju-signing"
temp.mkdir(parents=True, exist_ok=True)
certificate = decode_secret("OHOS_CERT_BASE64", temp / "ohos.cer")
profile = decode_secret("OHOS_PROFILE_BASE64", temp / "ohos.p7b")
store = decode_secret("OHOS_KEYSTORE_BASE64", temp / "ohos.p12")
tool = Path(required("DEVECO_SDK_HOME")) / "default/openharmony/toolchains/lib/hap-sign-tool.jar"
if not tool.is_file():
    raise SystemExit("SDK hap-sign-tool.jar not found")
config = json.loads((root / "ohos/build-profile.json5").read_text())
compatible = config["app"]["products"][0]["compatibleSdkVersion"]
api = re.fullmatch(r".*\((\d+)\)", compatible)
if not api:
    raise SystemExit("Cannot determine compatible SDK API from build-profile.json5")
source = root / "artifacts/ohos-unsigned.hap"
destination = root / "artifacts/ohos-signed.hap"
destination.parent.mkdir(exist_ok=True)
base = ["java", "-jar", str(tool)]
commands = [
    base + ["sign-app", "-mode", "localSign", "-keyAlias", required("OHOS_KEY_ALIAS"),
            "-keyPwd", required("OHOS_KEY_PASSWORD"), "-appCertFile", str(certificate),
            "-profileFile", str(profile), "-inFile", str(source),
            "-signAlg", "SHA256withECDSA", "-keystoreFile", str(store),
            "-keystorePwd", required("OHOS_STORE_PASSWORD"), "-outFile", str(destination),
            "-compatibleVersion", api[1], "-signCode", "1"],
    base + ["verify-app", "-inFile", str(destination),
            "-outCertChain", str(temp / "verified.cer"), "-outProfile", str(temp / "verified.p7b")],
]
for command in commands:
    # Never expose an exception containing a password-bearing command line.
    result = subprocess.run(command, capture_output=True)
    if result.returncode:
        message = (result.stdout + result.stderr).decode(errors="replace")
        for name, value in os.environ.items():
            if name.startswith("OHOS_") and value:
                message = message.replace(value, "[redacted]")
        print(message)
        raise SystemExit("HAP signing or verification failed")
source.unlink()
print("HAP signing and signature verification passed")
