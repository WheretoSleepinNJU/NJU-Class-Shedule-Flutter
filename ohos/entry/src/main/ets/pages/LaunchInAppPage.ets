// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// https://gitcode.com/openharmony-tpc/flutter_packages/blob/master/packages/url_launcher/url_launcher_ohos/example/ohos/entry/src/main/ets/pages/LaunchInAppPage.ets

import { InAppBrowser } from 'url_launcher_ohos/src/main/ets/components/plugin/InAppBrowser';

@Entry
@Component
struct LaunchInAppPage {

  build() {
    Row() {
      InAppBrowser()
    }
  }
}
