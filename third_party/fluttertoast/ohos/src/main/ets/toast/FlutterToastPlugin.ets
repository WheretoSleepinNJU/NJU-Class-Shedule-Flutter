/*
 * Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
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
import MethodChannel from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import StandardMethodCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMethodCodec';
import { AbilityAware, AbilityPluginBinding, Log, MethodCall, MethodResult } from '@ohos/flutter_ohos';
import { CustomToastDialog, ToastDialogArgs } from './CustomToastDialog';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import fs from '@ohos.file.fs';

const TAG: string = "FlutterToastPlugin";
const LENGTH_LONG: number = 3500;
const LENGTH_SHORT: number = 2000;
const VALID_GRAVITIES: string[] = ['top', 'bottom', 'center'];
const DEFAULT_BACKGROUND_COLOR: string = '#ff000000';
const DEFAULT_TEXT_COLOR: string = '#ffffffff';

export default class FlutterToastPlugin implements FlutterPlugin, AbilityAware {
  private channel: MethodChannel | null = null;
  private context: common.UIAbilityContext | null = null;
  private dialog: CustomToastDialog | null = null;

  private hideTimer: number | null = null;
  private debounceTimer: number | null = null;
  private pendingDebounceResult: MethodResult | null = null;
  private fontPath: string = '';

  /**
   * 返回插件的唯一类名，用于 Flutter 引擎识别。
   *
   * @returns 插件类名字符串
   */
  getUniqueClassName(): string {
    return TAG;
  }

  /**
   * 插件附加到 Flutter 引擎时回调，初始化 MethodChannel。
   *
   * @param binding - Flutter 插件绑定对象
   */
  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.setupChannel(binding.getBinaryMessenger());
  }

  /**
   * 插件从 Flutter 引擎分离时回调，释放 MethodChannel 资源。
   *
   * @param binding - Flutter 插件绑定对象
   */
  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.cleanup();
    this.releasePersistentResources();
    this.teardownChannel();
  }

  private setupChannel(messenger: BinaryMessenger): void {
    this.channel = new MethodChannel(messenger, "PonnamKarthik/fluttertoast", StandardMethodCodec.INSTANCE);
    this.channel.setMethodCallHandler(this);
  }

  private teardownChannel(): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
  }

  /**
   * 插件附加到 Ability 时回调，保存 UIAbilityContext 供 Toast 显示使用。
   *
   * @param binding - Ability 插件绑定对象
   */
  onAttachedToAbility(binding: AbilityPluginBinding): void {
    if (binding != null) {
      this.context = binding.getAbility().context as common.UIAbilityContext;
    }
  }

  /**
   * 插件从 Ability 分离时回调，清理 Toast 资源并释放持久化资源。
   */
  onDetachedFromAbility(): void {
    this.cleanup();
    this.releasePersistentResources();
  }

  /**
   * 处理来自 Flutter 侧的方法调用。
   *
   * @param call - MethodCall 对象，包含方法名和参数
   * @param result - MethodResult 对象，用于返回结果给 Flutter
   */
  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'showToast':
        if (!this.context) {
          result.error("NOT_READY", "Plugin not attached to ability yet", null);
          return;
        }
        this.showToast(call, result);
        break;
      case 'cancel':
        this.cancel(result);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  /**
   * 在 ohos 平台显示 Toast 消息。
   * 支持自定义字体时使用 CustomToastDialog，否则使用系统 promptAction.showToast。
   * 自定义字体场景下使用 100ms 防抖延迟避免重复显示。
   *
   * @param call - MethodCall 对象，包含 msg、gravity、fontSize 等参数
   * @param result - MethodResult 对象，用于返回显示结果
   * @returns Promise，在参数校验、字体写入及 Toast 调度完成后结束；失败时通过 result.error 回传
   */
  async showToast(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      const validationError = this.validateShowParams(call);
      if (validationError !== null) {
        result.error(validationError.code, validationError.message, null);
        return;
      }

      const fontAsset: string | null = call.argument("fontAsset");
      const fontAssetDataOhos: Uint8Array | null = call.argument("fontAssetDataOhos");

      // 先写入字体并设置 this.fontPath，再 parse，避免首次自定义字体 args.fontPath 为空
      const fontAssetReady = await this.handleFontAsset(fontAssetDataOhos);
      if (fontAssetDataOhos && !fontAssetReady) {
        result.error("SHOW_ERROR", "Failed to write font file", null);
        return;
      }
      const args = this.parseToastArgs(call);

      if (fontAsset && this.fontPath) {
        this.showCustomToastWithDebounce(args, result);
      } else {
        this.showSystemToast(args);
        result.success(true);
      }
    } catch (error) {
      Log.e(TAG, "Show toast error: " + JSON.stringify(error));
      result.error("SHOW_ERROR", "Failed to show toast", error);
    }
  }

  /**
   * 取消当前显示的 Toast 并清理相关资源。
   *
   * @param result - MethodResult 对象，用于返回取消结果
   */
  cancel(result: MethodResult): void {
    this.cleanup();
    result.success(true);
  }

  private validateShowParams(call: MethodCall): ValidationError | null {
    // 与 Android/iOS 保持一致：允许空消息（msg: ''），不在此处拦截
    const textSize: number | null = call.argument("fontSize");
    if (textSize !== null && (textSize <= 0 || textSize > 100)) {
      return { code: "INVALID_PARAM", message: "Invalid fontSize" };
    }

    const gravity: string = call.argument("gravity") || 'bottom';
    if (!VALID_GRAVITIES.includes(gravity)) {
      return { code: "INVALID_PARAM", message: "Invalid gravity" };
    }

    return null;
  }

  private parseToastArgs(call: MethodCall): ToastDialogArgs {
    const msg: string = call.argument('msg') || '';
    const length: string = call.argument("length")?.toString() || 'short';
    const mDuration: number = length == 'long' ? LENGTH_LONG : LENGTH_SHORT;
    const gravity: string = call.argument("gravity") || 'bottom';
    const bgColor: string = this.toHexColor(call.argument("bgcolor"), DEFAULT_BACKGROUND_COLOR);
    const textColor: string = this.toHexColor(call.argument("textcolor"), DEFAULT_TEXT_COLOR);
    const textSize: number | null = call.argument("fontSize");
    return {
      message: msg,
      mDuration: mDuration,
      gravity: gravity,
      bgColor: bgColor,
      textColor: textColor,
      textSize: textSize,
      fontPath: this.fontPath,
      backgroundBlurStyle: BlurStyle.NONE
    };
  }

  private toHexColor(colorValue: number | null, defaultColor: string): string {
    if (colorValue === null) {
      return defaultColor;
    }
    if (colorValue < 0 || colorValue > 0xFFFFFFFF) {
      Log.e(TAG, 'Invalid color value: ' + colorValue + ', using default');
      return defaultColor;
    }
    return '#' + colorValue.toString(16).padStart(8, '0');
  }

  private async handleFontAsset(fontAssetDataOhos: Uint8Array | null): Promise<boolean> {
    if (!fontAssetDataOhos || this.fontPath) {
      return true;
    }
    if (!this.context) {
      return false;
    }

    const cacheDir = this.context.tempDir;
    this.fontPath = cacheDir + `/ohosFont.ttf`;
    let fileFd: number = -1;
    try {
      const file1 = fs.openSync(this.fontPath, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);
      fileFd = file1.fd;
      await fs.write(fileFd, fontAssetDataOhos.buffer);
    } catch (error) {
      // 先关闭再删除，避免写入失败后临时目录残留孤立空文件
      if (fileFd >= 0) {
        try {
          fs.closeSync(fileFd);
        } catch (closeError) {
          Log.e(TAG, 'Close font file error: ' + JSON.stringify(closeError));
        }
        fileFd = -1;
      }
      try {
        fs.unlinkSync(this.fontPath);
      } catch (unlinkError) {
        Log.e(TAG, 'Delete orphan font file error: ' + JSON.stringify(unlinkError));
      }
      this.fontPath = '';
      Log.e(TAG, 'Write font file error: ' + JSON.stringify(error));
      return false;
    } finally {
      if (fileFd >= 0) {
        fs.closeSync(fileFd);
      }
    }
    return true;
  }

  private showCustomToastWithDebounce(args: ToastDialogArgs, result: MethodResult): void {
    this.clearDebounceTimer(true);
    this.pendingDebounceResult = result;
    this.debounceTimer = setTimeout((): void => {
      this.debounceShowImpl(args);
    }, 100);
  }

  private async debounceShowImpl(args: ToastDialogArgs): Promise<void> {
    this.debounceTimer = null;
    const pendingResult = this.pendingDebounceResult;
    this.pendingDebounceResult = null;
    try {
      await this.showImpl(args);
      if (pendingResult !== null) {
        pendingResult.success(true);
      }
    } catch (error) {
      Log.e(TAG, 'showImpl error: ' + JSON.stringify(error));
      if (pendingResult !== null) {
        pendingResult.error("SHOW_ERROR", "Failed to show custom toast", error);
      }
    }
  }

  private clearDebounceTimer(completed: boolean): void {
    if (this.debounceTimer !== null) {
      clearTimeout(this.debounceTimer);
      this.debounceTimer = null;
    }
    if (this.pendingDebounceResult !== null) {
      this.pendingDebounceResult.success(completed);
      this.pendingDebounceResult = null;
    }
  }

  private showSystemToast(args: ToastDialogArgs): void {
    let alignment: number;
    switch (args.gravity) {
      case "center":
        alignment = Alignment.Center;
        break;
      case "top":
        alignment = Alignment.Top;
        break;
      default:
        alignment = Alignment.Bottom;
        break;
    }

    promptAction.showToast({
      message: args.message,
      duration: args.mDuration,
      alignment: alignment,
      backgroundColor: args.bgColor,
      textColor: args.textColor,
      bottom: '50vp',
      backgroundBlurStyle: BlurStyle.NONE
    });
  }

  private async showImpl(args: ToastDialogArgs): Promise<void> {
    if (this.hideTimer !== null) {
      clearTimeout(this.hideTimer);
      this.hideTimer = null;
    }

    if (this.dialog) {
      try {
        this.dialog.hide();
      } catch (error) {
        Log.e(TAG, 'Hide previous dialog failed: ' + JSON.stringify(error));
      }
    }

    if (!this.dialog && this.context) {
      this.dialog = new CustomToastDialog(this.context);
    }

    if (this.dialog) {
      // 等待对话框真正打开完成后再向 Flutter 返回 success
      try {
        await this.dialog.show(args);
        this.hideTimer = setTimeout(this.onHideTimerExpired.bind(this), args.mDuration);
      } catch (error) {
        // show() 可能在 setupWindow 之后失败，需 hide() 恢复 navigationIndicator
        try {
          this.dialog.hide();
        } catch (hideError) {
          Log.e(TAG, 'Hide dialog after show failure: ' + JSON.stringify(hideError));
        }
        this.dialog = null;
        const errMsg: string = error instanceof Error ? error.message : JSON.stringify(error);
        throw new Error('Show custom toast failed: ' + errMsg);
      }
    }
  }

  private onHideTimerExpired(): void {
    try {
      if (this.dialog) {
        this.cleanup();
      }
    } catch (error) {
      Log.e(TAG, 'Hide dialog error: ' + JSON.stringify(error));
    } finally {
      this.hideTimer = null;
    }
  }

  /**
   * 清理当前 Toast 相关运行时资源。
   * 取消防抖/隐藏定时器，关闭并释放自定义对话框；不删除字体缓存文件。
   * 在 cancel、生命周期分离及 Toast 自动隐藏时调用。
   */
  cleanup(): void {
    this.clearDebounceTimer(false);

    if (this.hideTimer !== null) {
      clearTimeout(this.hideTimer);
      this.hideTimer = null;
    }

    if (this.dialog) {
      try {
        this.dialog.hide();
      } catch (error) {
        Log.e(TAG, 'Dialog hide error: ' + JSON.stringify(error));
      }
      this.dialog = null;
    }
  }

  private releasePersistentResources(): void {
    this.context = null;

    if (this.fontPath) {
      try {
        fs.unlinkSync(this.fontPath);
      } catch (error) {
        Log.e(TAG, 'Delete font file error: ' + JSON.stringify(error));
      }
      this.fontPath = '';
    }
  }
}

interface ValidationError {
  code: string;
  message: string;
}
