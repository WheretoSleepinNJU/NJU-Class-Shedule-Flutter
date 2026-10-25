#!/usr/bin/env python3
"""Verify the exported IPA, including the launch contract required by UIKit."""
import argparse, hashlib, json, plistlib, subprocess, tempfile, zipfile
from datetime import datetime, timezone
from pathlib import Path


def run(*args):
    return subprocess.check_output(args, stderr=subprocess.STDOUT)


def verify(ipa, expected_build=None):
    with tempfile.TemporaryDirectory(prefix='nju-ios-verify-') as temporary:
        root = Path(temporary)
        with zipfile.ZipFile(ipa) as archive:
            archive.extractall(root)
        app = next((root / 'Payload').glob('*.app'))
        info = plistlib.loads((app / 'Info.plist').read_bytes())
        if expected_build is not None:
            assert info['CFBundleVersion'] == str(expected_build), 'Wrong build number'
        scenes = info.get('UIApplicationSceneManifest', {}).get('UISceneConfigurations', {})
        configs = scenes.get('UIWindowSceneSessionRoleApplication', [])
        assert any(c.get('UISceneDelegateClassName', '').endswith('.SceneDelegate')
                   and c.get('UISceneStoryboardFile') == 'Main' for c in configs), 'Missing scene launch configuration'
        assert 'UIMainStoryboardFile' not in info, 'Legacy application storyboard still used'
        assert list(app.rglob('Main.storyboardc')), 'Missing scene storyboard'
        executable = app / info['CFBundleExecutable']
        assert b'SceneDelegate' in executable.read_bytes(), 'Scene delegate class was not linked'
        run('codesign', '--verify', '--deep', '--strict', str(app))
        aot = app / 'Frameworks/App.framework/App'
        assert aot.exists(), 'Missing AOT framework'
        assert not list(app.rglob('kernel_blob.bin')), 'Debug kernel in release IPA'
        symbols = run('xcrun', 'nm', '-g', str(aot))
        assert b'kDartIsolateSnapshotInstructions' in symbols, 'Missing Dart AOT instructions'
        bundles = []
        for bundle in [app, *app.glob('PlugIns/*.appex')]:
            bundle_info = plistlib.loads((bundle / 'Info.plist').read_bytes())
            assert bundle_info['CFBundleVersion'] == info['CFBundleVersion'], 'Extension build mismatch'
            assert bundle_info['CFBundleShortVersionString'] == info['CFBundleShortVersionString'], 'Extension version mismatch'
            profile = plistlib.loads(run('security', 'cms', '-D', '-i', str(bundle / 'embedded.mobileprovision')))
            signed_xml = run('codesign', '-d', '--entitlements', ':-', str(bundle))
            entitlements = plistlib.loads(b'<?xml' + signed_xml.split(b'<?xml', 1)[1])
            certificate_prefix = root / ('signing-certificate-' + str(len(bundles)) + '-')
            run('codesign', '-d', '--extract-certificates=' + str(certificate_prefix), str(bundle))
            leaf_certificate = Path(str(certificate_prefix) + '0').read_bytes()
            assert leaf_certificate in profile['DeveloperCertificates'], 'Signing certificate not in provisioning profile'
            assert entitlements.get('application-identifier') == profile['Entitlements'].get('application-identifier'), 'Signed application identifier mismatch'
            assert not entitlements.get('get-task-allow', False), 'Development entitlement in App Store IPA'
            assert not profile.get('ProvisionedDevices') and not profile.get('ProvisionsAllDevices'), 'Not App Store distribution'
            assert profile['ExpirationDate'].replace(tzinfo=timezone.utc) > datetime.now(timezone.utc), 'Expired profile'
            group = 'group.top.idealclover.wheretosleepinnju.group'
            assert group in entitlements.get('com.apple.security.application-groups', []), 'Missing signed App Group'
            assert group in profile['Entitlements'].get('com.apple.security.application-groups', []), 'Profile missing App Group'
            uuid = run('xcrun', 'dwarfdump', '--uuid', str(bundle / bundle_info['CFBundleExecutable'])).decode().splitlines()
            bundles.append({'bundleId': bundle_info['CFBundleIdentifier'], 'build': bundle_info['CFBundleVersion'],
                            'minimumOS': bundle_info.get('MinimumOSVersion'), 'uuid': [line.split(' (', 1)[0] for line in uuid],
                            'profileExpires': profile['ExpirationDate'].isoformat(), 'distribution': 'App Store'})
        return {'ipa': str(ipa), 'sha256': hashlib.sha256(ipa.read_bytes()).hexdigest(), 'bytes': ipa.stat().st_size,
                'version': info['CFBundleShortVersionString'], 'build': info['CFBundleVersion'],
                'sceneLifecycle': True, 'releaseAOT': True, 'deepSignatureVerified': True, 'signingCertificateMatchesProfile': True, 'bundles': bundles,
                'physicalDeviceRuntimeVerified': False}


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('ipa', type=Path)
    parser.add_argument('--build')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    result = verify(args.ipa, args.build)
    output = json.dumps(result, ensure_ascii=False, indent=2) + '\n'
    if args.output:
        args.output.write_text(output)
    print(output)
