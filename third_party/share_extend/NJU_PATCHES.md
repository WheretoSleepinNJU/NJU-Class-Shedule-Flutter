# share_extend compatibility patch

Source: https://gitcode.com/fuchuanyang/fluttertpc_share_extend.git
Commit: ddeebd9496c690cdceed64b9a954326a48f8f473
License: MIT (see LICENSE).

This source snapshot keeps the existing Dart, iOS, and OHOS behavior. The Android
plugin removes only Flutter v1 embedding registration (`PluginRegistry.Registrar`),
which was removed from current Flutter. V2 `FlutterPlugin` / `ActivityAware`
registration and permission handling are retained. Upstream CPF's 2.0.0 OHOS tag
still contains the removed API, so this narrow patch is checked into the project
instead of editing the user's Pub cache. Examples and build outputs are omitted.

Rechecked 2026-10-24: CPF master / 2.0.0-ohos-1.0.0
(`4afdbce8489836425845d44f0322ca7fbeeaf660`) and dev
(`99188ae5a3e64f311c7a8dbb1b7129eabbf9facc`) still reference Registrar.
The patch changes one Java file (3 added / 13 removed lines). Keeping it here
makes a fresh checkout reproducible without depending on a machine-local cache
edit or requiring a separately published fork. This copy can be replaced with
an upstream Git dependency once that compatibility fix is released.

Trailing whitespace in imported documentation and iOS sources is normalized;
this does not change plugin behavior.

- Android: replace the removed Gradle jcenter() repository shorthand with mavenCentral() for the Compose bridge toolchain (Gradle 9).
