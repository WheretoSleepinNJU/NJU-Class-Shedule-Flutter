## 9.0.0-ohos-1.0.0

* TAG 9.0.0-ohos-1.0.0.
* Fix toast dialog layout overlapping buttons in example demos.
* Remove legacy Flutter 3.7 adaptation notes from README.

## 9.0.0-ohos-1.0.0-beta.2

* TAG 9.0.0-ohos-1.0.0-beta.2.
* Harden OHOS plugin quality: refactor FlutterToastPlugin (param validation, error handling, lifecycle/resource cleanup); extract CustomToastDialog.
* Fix Platform.isOhos crash on non-OHOS platforms via safe platform check.
* Adjust OHOS defaults: gravity bottom, toast duration (short/long), default bg/text colors.
* Add unit tests and improve example demos.
* Improve README.OpenHarmony docs per quality review: TOC, version table, migration notes, OHOS env setup, API coverage, and fontAssetOhosPath examples.
* Add README.OpenHarmony_CN.md and README.OpenHarmony.md (replace legacy README_OpenHarmony*.md).
* Document known platform limitations (cancel for system toast, custom font using dialog).
* Add FAQ section covering issues #23, #26, #12 from user feedback.
