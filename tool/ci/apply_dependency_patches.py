#!/usr/bin/env python3
"""Prepare the two small local patches without modifying the global Pub cache."""
from pathlib import Path
import hashlib
import os
import subprocess
import tarfile
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
PATCHES = ROOT / 'third_party/patches'
UMENG_URL = 'https://pub.dev/api/archives/umeng_common_sdk-1.3.0.tar.gz'
UMENG_SHA256 = '8374ced1ab1d89f596ff71c0eff044d5395337145c9a69a6be02f5d8a678e42c'


def apply_patch(destination: Path, patch: Path) -> None:
    # Archive packages have no .git; don't discover the application's repository.
    env = dict(os.environ, GIT_CEILING_DIRECTORIES=str(destination.parent))
    command = ['git', 'apply', '--check']
    already = subprocess.run(command + ['--reverse', str(patch)], cwd=destination,
                             env=env, capture_output=True)
    if already.returncode == 0:
        return
    check = subprocess.run(command + [str(patch)], cwd=destination,
                           env=env, capture_output=True, text=True)
    if check.returncode:
        raise SystemExit(f'{destination}: patch does not match this checkout. '
                         f'Preserve local changes before recreating it.\n{check.stderr}')
    subprocess.run(['git', 'apply', str(patch)], cwd=destination, env=env, check=True)


def main() -> None:
    apply_patch(ROOT / 'external/adaptive_platform_ui', PATCHES / 'adaptive_platform_ui.patch')
    umeng = ROOT / 'external/umeng_common_sdk'
    if not umeng.exists():
        archive = ROOT / '.fvm/downloads/umeng_common_sdk-1.3.0.tar.gz'
        archive.parent.mkdir(parents=True, exist_ok=True)
        if not archive.exists():
            archive.write_bytes(urllib.request.urlopen(UMENG_URL, timeout=60).read())
        if hashlib.sha256(archive.read_bytes()).hexdigest() != UMENG_SHA256:
            raise SystemExit('umeng_common_sdk archive checksum mismatch')
        umeng.mkdir()
        with tarfile.open(archive) as source:
            source.extractall(umeng, filter='data')
    apply_patch(umeng, PATCHES / 'umeng_common_sdk.patch')
    print('Patched external dependencies ready: adaptive_platform_ui, umeng_common_sdk')


if __name__ == '__main__':
    main()
