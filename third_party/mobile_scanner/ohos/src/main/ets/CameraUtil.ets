/*
* Copyright (c) 2023 Shenzhen Kaihong Digital Industry Development Co., Ltd.
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

import { BusinessError } from '@ohos.base';
import common from '@ohos.app.ability.common';
import { camera } from '@kit.CameraKit';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';

const TAG: string = "CameraUtil";

/**
 * 如果获取对象失败，说明相机可能被占用或无法使用。如果被占用，须等到相机被释放后才能重新获取。
 * @param context
 * @returns
 */
export function getCameraManager(context: common.BaseContext): camera.CameraManager | undefined {
  let cameraManager: camera.CameraManager | undefined = undefined;
  try {
    cameraManager = camera.getCameraManager(context);
  } catch (error) {
    let err = error as BusinessError;
    Log.e(TAG, `The getCameraManager call failed. error code: ${err.code}`);
  }
  return cameraManager;
}

export function createSession(cameraManager: camera.CameraManager, mode: camera.SceneMode): camera.PhotoSession | undefined {
  let photoSession: camera.PhotoSession | undefined = undefined;
  try {
    photoSession = cameraManager.createSession(mode) as camera.PhotoSession;
  } catch (error) {
    // 失败返回错误码error.code并处理
    let err = error as BusinessError;
    Log.e(TAG, `createCaptureSession error. error code: ${err.code}`);
  }
  return photoSession;
}

export function hasFlashUnit(context: common.BaseContext):boolean {
  let status: boolean = true;
  /*
  try {
    let cameraManager = getCameraManager(context)!;
    let photoSession = createSession(cameraManager, camera.SceneMode.NORMAL_PHOTO)!;
    photoSession.beginConfig();
    status = photoSession.hasFlash();
  } catch (error) {
    // 失败返回错误码error.code并处理
    let err = error as BusinessError;
    Log.e(TAG, `The hasFlash call failed. error code: ${err.code}`);
  }
  */
  return status;
}
