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
import UIAbility from '@ohos.app.ability.UIAbility';
import List from '@ohos.util.List';
import fs from '@ohos.file.fs';
import { fileUri } from '@kit.CoreFileKit';
import { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import systemShare from '@hms.collaboration.systemShare';
import uniformTypeDescriptor from '@ohos.data.uniformTypeDescriptor';

const TAG = 'FlutterShare';

export default class Share {
  private  ability?: UIAbility | undefined = undefined;

  constructor() {
  }

  public setAbility(ability: UIAbility | undefined): void {
    this.ability = ability;
  }

  /**
   * 分享文本
   *
   * @param text 待分享文本
   * @param withResult 是否需要dismiss回调
   * @param result result
   */
  public shareText(text: string, withResult?: boolean, result?: MethodResult): void {
    if (!this.ability) {
      result?.error('no_ability', 'Share ability unavailable', null);
      Log.w(TAG, "share ability not exist");
      return
    }
    Log.i(TAG, "share");
    let record: systemShare.SharedRecord = {
      utd: uniformTypeDescriptor.getUniformDataTypeByMIMEType('text/plain'),
      content: text || ''
    }
    let data = new systemShare.SharedData(record);
    this.startShare(data, withResult, result);
  }

  /**
   * 分享文件
   *
   * @param paths 待分享文件路径集合
   * @param subject 分享标题
   * @param withResult 是否需要dismiss回调
   * @param result result
   * @returns await
   */
  public async shareFiles(paths: List<string>, subject: string | null, withResult?: boolean, result?: MethodResult): Promise<void> {
    if (!this.ability) {
      result?.error('no_ability', 'Share ability unavailable', null);
      Log.w(TAG, "shareFiles ability not exist");
      return
    }
    Log.i(TAG, "shareFiles");
    await this.clearShareCache()
    let fileUris = await this.getUrisForPaths(paths)
    Log.d(TAG, "shareFiles: path->" + JSON.stringify(fileUris));
    if (!fileUris || fileUris.length == 0) {
      result?.error('share_failed', 'Cannot prepare shared files', null);
      Log.w(TAG, "shareFiles copy to cache failed");
      return
    }
    let data: systemShare.SharedData | null = null;
    fileUris.forEach((uri: string, index: number) => {
      let record: systemShare.SharedRecord = {
        utd: this.getUniformTypeDescriptor(uri),
        uri: uri,
        title: subject || ''
      }
      if (data) {
        data.addRecord(record);
      } else {
        data = new systemShare.SharedData(record);
      }
    })
    this.startShare(data, withResult, result);
  }

  private startShare(data: systemShare.SharedData | null, withResult?: boolean, result?: MethodResult): void {
    if (!this.ability || !data) {
      result?.error('no_data', 'No share data or ability', null);
      Log.w(TAG, "startShare ability not exist or data empty");
      return
    }
    Log.i(TAG, "startShare");
    try {
      let controller = new systemShare.ShareController(data);
      if (withResult) {
        controller.on('dismiss', () => {
          result?.success('');
        });
      }
      controller.show(this.ability!.context, {
        previewMode: systemShare.SharePreviewMode.DETAIL,
        selectionMode: systemShare.SelectionMode.BATCH
      }).then(() => {
        if (!withResult) result?.success('');
      }).catch(() => {
        result?.error('share_failed', 'Cannot open share panel', null);
      });
    } catch (err) {
      Log.e(TAG, 'startShare err:' + JSON.stringify(err));
      result?.error('share_failed', 'Cannot open share panel', null);
    }
  }

  private getUniformTypeDescriptor(fileUri: string): string {
    const dotIndex = fileUri.lastIndexOf('.');
    if (dotIndex != -1) {
      const fileExtension = '.' + fileUri.substring(dotIndex + 1);
      return uniformTypeDescriptor.getUniformDataTypeByFilenameExtension(fileExtension) || 'general.file';
    }
    return 'general.file';
  }

  /**
   * 分享路径
   *
   * @returns 分享路径
   */
  private shareCacheFolder(): string {
    if (!this.ability) {
      Log.w(TAG, "shareCacheFolder ability not exist");
      return ""
    }
    return this.ability.context.cacheDir + '/share_extend' || "";
  }

  /**
   * 获取复制到cache后的路径集合
   *
   * @param paths paths
   * @returns cache的路径集合
   */
  private async getUrisForPaths(paths: List<string>): Promise<Array<string>> {
    Log.i(TAG, "getUrisForPaths");
    let uris = new Array<string>();
    try {
      for (let index = 0; index < paths.length; index++) {
        const file: string = await this.copyToShareCache(paths[index]);
        if (file) uris.push(fileUri.getUriFromPath(file));
      }
    } catch (err) {
      Log.e(TAG, 'getUrisForPaths err:' + JSON.stringify(err));
    }
    return uris
  }

  /**
   * 清空cache缓存
   *
   * @returns 清空cache缓存
   */
  private async clearShareCache(): Promise<void> {
    Log.i(TAG, "clearShareCacheFolder");
    try {
      let folder: string = this.shareCacheFolder();
      if (folder && fs.accessSync(folder)) {
        let files = fs.listFileSync(folder);
        if (files.length > 0) {
          files.forEach(item => {
            fs.unlinkSync(folder + '/' + item);
          })
          fs.rmdirSync(folder);
        }
      }
    } catch (err) {
      Log.e(TAG, 'clearShareCacheFolder err:' + JSON.stringify(err));
    }
  }

  /**
   * 复制到缓存目录
   *
   * @param file 待复制文件
   * @returns 缓存路径
   */
  private async copyToShareCache(file: string): Promise<string> {
    let folder = this.shareCacheFolder();
    if (!folder) {
      return ""
    }
    Log.i(TAG, "copyToShareCache");
    if (!fs.accessSync(folder)) {
      fs.mkdirSync(folder);
    }
    let oldFile: fs.File = fs.openSync(file);
    let newFile = folder + '/' + oldFile.name;
    try {
      fs.copyFileSync(oldFile.fd, newFile);
    } finally {
      fs.closeSync(oldFile);
    }
    return newFile
  }
}
