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

import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import MethodChannel from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { AbilityAware, AbilityPluginBinding, Log } from '@ohos/flutter_ohos';
import MethodChannelHandlerImpl from './MethodChannelHandlerImpl';
import Share from './Share';

const TAG = "ShareExtendPlugin";

export default class ShareExtendPlugin implements FlutterPlugin, AbilityAware {
  private channel: MethodChannel | null = null;
  private methodChannelHandlerImpl: MethodChannelHandlerImpl | null = null;
  private share: Share | null = null

  constructor() {
  }

  getUniqueClassName(): string {
    return "ShareExtendPlugin"
  }

  onAttachedToAbility(binding: AbilityPluginBinding) {
    Log.i(TAG, "onAttachedToAbility");
    this.share?.setAbility(binding.getAbility());
  }

  onDetachedFromAbility() {
    Log.i(TAG, "onDetachedFromAbility");
    this.share?.setAbility(undefined);
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.share = new Share();
    this.methodChannelHandlerImpl = new MethodChannelHandlerImpl(this.share);
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "com.zt.shareextend/share_extend");
    this.channel.setMethodCallHandler(this.methodChannelHandlerImpl);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
      this.channel = null;
    }
  }
}