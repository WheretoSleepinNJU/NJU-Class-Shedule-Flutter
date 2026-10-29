#!/usr/bin/env python3
"""Compile Android activity/widget code with the real Flutter embedding; run host tests.

Uses an isolated Android library so unrelated Flutter plugins and the installed Dart
version do not prevent native verification. Does not build an APK or use a device.
"""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET


def main():
    repo = Path(__file__).resolve().parents[1]
    properties = {}
    local = repo / 'android/local.properties'
    if local.exists():
        properties = dict(line.split('=', 1) for line in local.read_text().splitlines()
                          if '=' in line and not line.startswith('#'))
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--flutter-sdk', default=os.environ.get('FLUTTER_SDK', properties.get('flutter.sdk')))
    parser.add_argument('--android-sdk', default=os.environ.get('ANDROID_HOME', properties.get('sdk.dir')))
    parser.add_argument('--gradle', default=os.environ.get('GRADLE_BIN', shutil.which('gradle')))
    parser.add_argument('--offline', action='store_true')
    args = parser.parse_args()
    if not all([args.flutter_sdk, args.android_sdk, args.gradle]):
        parser.error('Provide --flutter-sdk, --android-sdk and --gradle (or their environment variables).')
    embedding = Path(args.flutter_sdk) / 'bin/cache/artifacts/engine/android-x64/flutter.jar'
    if not embedding.exists():
        parser.error(f'Missing {embedding}; precache Android artifacts with the selected Flutter SDK.')
    with tempfile.TemporaryDirectory(prefix='nju-live-activity-') as temporary:
        root = Path(temporary)
        (root / 'settings.gradle').write_text('''pluginManagement {
 repositories { google(); mavenCentral(); gradlePluginPortal() }
 resolutionStrategy { eachPlugin {
  if (requested.id.id == 'com.android.library') useModule('com.android.tools.build:gradle:8.13.0')
  if (requested.id.id == 'org.jetbrains.kotlin.android') useModule('org.jetbrains.kotlin:kotlin-gradle-plugin:2.2.21')
 } }
}
dependencyResolutionManagement { repositories { google(); mavenCentral(); maven { url 'https://jitpack.io' } } }
rootProject.name = 'NjuNativeLiveActivityTests'
''')
        (root / 'build.gradle').write_text('''plugins { id 'com.android.library'; id 'org.jetbrains.kotlin.android' }
def sourceRoot = providers.gradleProperty('sourceRoot').get()
android {
 namespace 'com.lilystudio.wheretosleepinnju'; compileSdk 36
 defaultConfig { minSdk 24; targetSdk 33 }
 buildFeatures { aidl true }
 sourceSets {
  main {
   java.srcDirs = ["$sourceRoot/android/app/src/main/java", "$sourceRoot/android/app/src/main/kotlin"]
   java.exclude '**/MainApplication.java', '**/UmengSdkPlugin.java', '**/GeneratedPluginRegistrant.java'
   aidl.srcDirs = ["$sourceRoot/android/app/src/main/aidl"]
   res.srcDirs = ["$sourceRoot/android/app/src/main/res"]
   manifest.srcFile 'AndroidManifest.xml'
  }
  test.java.srcDirs = ["$sourceRoot/android/app/src/test/java"]
 }
 testOptions { unitTests.returnDefaultValues = true; unitTests.includeAndroidResources = true }
 compileOptions { sourceCompatibility JavaVersion.VERSION_1_8; targetCompatibility JavaVersion.VERSION_1_8 }
}
kotlin { compilerOptions { jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8 } }
dependencies {
 implementation files(providers.gradleProperty('embeddingJar').get())
 implementation 'androidx.lifecycle:lifecycle-common:2.9.2'
 implementation 'androidx.core:core-ktx:1.17.0'
 implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2'
 implementation 'dev.rikka.shizuku:api:13.1.5'
 implementation 'dev.rikka.shizuku:provider:13.1.5'
 implementation 'com.github.topjohnwu.libsu:service:6.0.0'
 testImplementation 'junit:junit:4.13.2'
 testImplementation 'org.json:json:20180813'
 testImplementation 'org.robolectric:robolectric:4.14.1'
}
''')
        (root / 'local.properties').write_text(f'sdk.dir={args.android_sdk}\n')
        (root / 'gradle.properties').write_text('android.useAndroidX=true\norg.gradle.jvmargs=-Xmx2g\n')
        # Include the production live-activity manifest entries. Exclude unrelated
        # analytics initialization and Flutter plugin registration from this host harness.
        namespace = 'http://schemas.android.com/apk/res/android'
        ET.register_namespace('android', namespace)
        source = ET.parse(repo / 'android/app/src/main/AndroidManifest.xml').getroot()
        manifest = ET.Element('manifest')
        for permission in source.findall('uses-permission'):
            manifest.append(permission)
        application = ET.SubElement(manifest, 'application')
        for component in source.find('application'):
            if component.get(f'{{{namespace}}}name', '').startswith('.liveactivity.'):
                application.append(component)
        ET.ElementTree(manifest).write(root / 'AndroidManifest.xml', encoding='utf-8', xml_declaration=True)
        command = [args.gradle, '--console=plain', f'-PsourceRoot={repo}',
                   f'-PembeddingJar={embedding}', 'testDebugUnitTest', 'assembleDebug']
        if args.offline:
            command.append('--offline')
        subprocess.run(command, cwd=root, check=True)
        tests = failures = 0
        for report in (root / 'build/test-results/testDebugUnitTest').glob('TEST-*.xml'):
            suite = ET.parse(report).getroot()
            tests += int(suite.get('tests', 0))
            failures += int(suite.get('failures', 0)) + int(suite.get('errors', 0))
        print(f'Native Android checks: {tests} tests, {failures} failures. No device was used.')


if __name__ == '__main__':
    main()
