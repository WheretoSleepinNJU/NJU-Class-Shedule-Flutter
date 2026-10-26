/**
 * Copyright (c) 2026 Huawei Device Co., Ltd.
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

import { Log } from '@ohos/flutter_ohos';
import { Params, BlurStyleConfig } from './CustomToastDialog';

const TAG: string = 'CustomToastView';

@Component
struct CustomToastView {
  @State message: string = 'hello world';
  @State gravity: string = 'bottom';
  @State bgColor: ResourceColor = Color.Black;
  @State textColor: ResourceColor = Color.White;
  // null 表示沿用系统默认字号，不强制覆盖
  @State textSize: number | null = null;
  @State fontPath: string = '';
  private blurStyleConfig: BlurStyleConfig = {
    blurStyle: BlurStyle.NONE
  };

  aboutToAppear(): void {
    if (this.fontPath) {
      try {
        this.getUIContext().getFont().registerFont({
          familyName: 'fontStyle',
          familySrc: `file:/${this.fontPath}`
        });
      } catch (error) {
        // 字体注册失败时沿用默认字体，避免异常传播到对话框渲染层
        Log.e(TAG, 'Register font failed: ' + JSON.stringify(error));
      }
    }
  }

  build() {
    Stack() {
      Column() {
        if (this.textSize == null) {
          Text(this.message)
            .fontColor(this.textColor)
            .fontFamily('fontStyle')
        } else {
          Text(this.message)
            .fontSize(this.textSize)
            .fontColor(this.textColor)
            .fontFamily('fontStyle')
        }
      }
      .padding({ left: 20, right: 20, top: 10, bottom: 10 })
      .borderRadius(24)
      .backgroundColor(this.bgColor)
      .backgroundBlurStyle(
        this.blurStyleConfig.blurStyle
      )
    }
  }
}

@Builder
export function dialogBuilder(params: Params) {
  CustomToastView(params);
}
