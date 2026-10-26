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
import { window, display, PromptAction } from '@kit.ArkUI';
import { ComponentContent, promptAction } from '@kit.ArkUI';
import { dialogBuilder } from './CustomToastView';

const TAG: string = 'CustomToastDialog';

export interface ToastDialogArgs {
  message: string;
  mDuration: number;
  gravity: string;
  bgColor: string;
  textColor: string;
  textSize: number | null;
  fontPath: string;
  backgroundBlurStyle: BlurStyle;
}

export interface BlurStyleConfig {
  blurStyle: BlurStyle;
}

class CustomToastDialog {
  private contentDialog: ComponentContent<Params> | null = null;
  private promptAction: PromptAction | null = null;
  public pageShow: boolean = false;
  public pageHide: boolean = false;
  private context: Context;
  private windowClass: window.Window | null = null;

  constructor(context: Context) {
    this.context = context;
  }

  /**
   * 显示自定义 Toast 对话框。
   * 异步等待窗口获取与对话框打开完成；失败时抛出异常，由调用方传播到 Flutter。
   *
   * @param args - Toast 参数，包含消息、时长、位置、颜色及字体路径等
   * @returns 对话框打开完成后的 Promise；失败时 reject
   */
  async show(args: ToastDialogArgs): Promise<void> {
    const params = new Params({
      message: args.message,
      duration: args.mDuration,
      gravity: args.gravity,
      bgColor: args.bgColor,
      textColor: args.textColor,
      textSize: args.textSize,
      fontPath: args.fontPath,
      backgroundBlurStyle: { blurStyle: args.backgroundBlurStyle },
      dialog: this
    });

    const systemAvoidAreaType = window.AvoidAreaType.TYPE_SYSTEM;

    try {
      const windowClass: window.Window = await window.getLastWindow(this.context);
      this.setupWindow(windowClass);

      const uiContext = windowClass.getUIContext();
      this.contentDialog = new ComponentContent(uiContext, wrapBuilder(dialogBuilder), params);
      this.promptAction = uiContext.getPromptAction();

      const avoidArea1 = windowClass.getWindowAvoidArea(systemAvoidAreaType);
      const statusBarHeight = avoidArea1.topRect.height;
      const bottomNavHeight = avoidArea1.bottomRect.height;
      const topRectVp = uiContext.px2vp(statusBarHeight);
      const bottomRectVp = uiContext.px2vp(bottomNavHeight);

      const options = this.buildDialogOptions(args, topRectVp, bottomRectVp);
      await this.promptAction.openCustomDialog(this.contentDialog, options);
    } catch (error) {
      const errMsg: string = 'Show custom toast failed: ' + JSON.stringify(error);
      Log.e(TAG, errMsg);
      throw new Error(errMsg);
    }
  }

  /**
   * 隐藏并关闭当前自定义 Toast 对话框。
   */
  hide(): void {
    try {
      if (this.promptAction && this.contentDialog) {
        this.promptAction.closeCustomDialog(this.contentDialog);
      }
    } catch (error) {
      Log.e(TAG, 'closeCustomDialog error: ' + JSON.stringify(error));
    } finally {
      this.contentDialog = null;
      this.promptAction = null;
      if (this.windowClass) {
        this.windowClass.setSpecificSystemBarEnabled('navigationIndicator', true);
        this.windowClass = null;
      }
    }
  }

  private setupWindow(windowClass: window.Window): void {
    this.windowClass = windowClass;
    windowClass.setSpecificSystemBarEnabled('navigationIndicator', false);
    windowClass.setDialogBackGestureEnabled(true);
  }

  private buildDialogOptions(args: ToastDialogArgs, topRectVp: number,
    bottomRectVp: number): promptAction.BaseDialogOptions {
    // 动态获取当前屏幕尺寸，避免旋转/多窗口后定位偏差
    const displayInfo = display.getDefaultDisplaySync();
    const screenWidth: number = px2vp(displayInfo.width);
    const screenHeight: number = px2vp(displayInfo.height);
    return {
      autoCancel: false,
      isModal: false,
      maskColor: '#000',
      offset: {
        dx: 0,
        dy: args.gravity == "center" ? 0 : args.gravity == "top" ? topRectVp : -bottomRectVp,
      },
      maskRect: {
        x: 0,
        y: 0,
        width: screenWidth,
        height: screenHeight
      },
      alignment: args.gravity == "center" ? DialogAlignment.Center :
        args.gravity == "top" ? DialogAlignment.Top : DialogAlignment.Bottom,
      onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
        if (dismissDialogAction.reason == DismissReason.PRESS_BACK) {
          dismissDialogAction.dismiss();
          // 立即走 hide() 恢复 navigationIndicator；否则要等 FlutterToastPlugin.hideTimer 到期
          this.hide();
        }
      },
    };
  }
}

interface ToastParams {
  message: string;
  duration: number;
  gravity: string;
  bgColor: string;
  textColor: string;
  textSize: number | null;
  fontPath: string;
  backgroundBlurStyle: BlurStyleConfig;
  dialog: CustomToastDialog;
}

class Params {
  message: string;
  duration: number;
  gravity: string;
  bgColor: string;
  textColor: string;
  // null 时不覆盖系统默认字号，与 Android 行为一致
  textSize: number | null;
  fontPath: string;
  backgroundBlurStyle: BlurStyleConfig;
  dialog: CustomToastDialog;

  constructor(param: ToastParams) {
    this.dialog = param.dialog;
    this.message = param.message;
    this.duration = param.duration;
    this.gravity = param.gravity;
    this.bgColor = param.bgColor;
    this.textColor = param.textColor;
    this.textSize = param.textSize;
    this.fontPath = param.fontPath;
    this.backgroundBlurStyle = param.backgroundBlurStyle;
  }
}

export {
  Params, CustomToastDialog
};
