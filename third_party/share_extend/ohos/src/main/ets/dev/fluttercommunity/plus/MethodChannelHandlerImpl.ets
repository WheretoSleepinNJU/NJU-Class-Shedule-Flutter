/*
* Copyright (c) 2024 Shenzhen Kaihong Digital Industry Development Co., Ltd.
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { MethodCall } from '@ohos/flutter_ohos';
import { MethodCallHandler, MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import Share from './Share';
import { List } from '@kit.ArkTS';

const TAG = 'MethodCallHandlerImpl';

export default class MethodCallHandlerImpl implements MethodCallHandler {
  private share: Share | null = null;

  constructor(share: Share) {
    this.share = share;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    let method: string = call.method;
    Log.i(TAG, "onMethodCall: " + method);
    let type: string = call.argument("type");
    let list: List<string> = call.argument("list");
    let subject: string = call.argument('subject');
    try {
      switch (method) {
        case 'share':
          if ("text" === type) {
            this.share?.shareText(list[0]);
          } else {
            this.share?.shareFiles(list, subject);
          }
          break;
        default:
          result.notImplemented();
          break;
      }
    } catch (err) {
      Log.e(TAG, 'err:' + JSON.stringify(err));
    }
  }
}
