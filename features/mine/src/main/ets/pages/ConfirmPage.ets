/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { BreakpointType, BreakpointTypeEnum, CommonConstants, Logger, WindowUtil } from '@ohos/utils';
import { GlobalContext } from '@ohos/datastore';
import Constants from '../constants/Constants';
import { TopNavigationView } from '@ohos/uicomponents/Index';

const context = getContext(this) as common.ApplicationContext;

const TAG = '[ConfirmPage]';
const distributedProfilePath = 'file://com.huawei.hmos.world/' + context.distributedFilesDir + '/temp_profile.jpg';
const distributedPath: string = `${context.distributedFilesDir}/temp_profile.jpg`;

let imageWidth: BreakpointType<string> = new BreakpointType<string>({
  sm: CommonConstants.FULL_PERCENT,
  md: Constants.CLIP_RATIO_FOLD,
  lg: Constants.CLIP_RATIO_PAD
})

@Component
export struct ConfirmPage {
  @Prop uri: string = '';
  @Consume('appPathStack') appPathStack: NavPathStack;
  @StorageLink('profilePath') profilePath: string = '';
  @StorageProp('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.MD;
  @StorageLink('showTag') showTag: number = 0;
  @State isContinue: boolean = false;
  private localProfilePath = `${context.cacheDir}/${AppStorage.get<string>('userId') as string}_profile.jpg`;

  aboutToAppear(): void {
    GlobalContext.getContext().setObject('stackName', 'ConfirmPage');
    this.isContinue = GlobalContext.getContext().getObject('isContinue') as boolean;
    GlobalContext.getContext().deleteObject('isContinue');
    if (!this.isContinue) {
      this.savaFile2Distributed();
    }
  }

  savaFile2Distributed() {
    try {
      let srcFile = fileIo.openSync(this.uri, fileIo.OpenMode.READ_ONLY);
      let distributedPathFile = fileIo.openSync(distributedPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      fileIo.copyFileSync(srcFile.fd, distributedPathFile.fd);
      fileIo.closeSync(distributedPathFile);
      fileIo.closeSync(srcFile);
      Logger.info(TAG, 'savaFile2Distributed success, distributedPath is:' + distributedPath);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      Logger.error(TAG, `savaFile2Distributed Failed to openSync / writeSync / closeSync. Code: ${err.code}, message: ${err.message}`);
    }
  }

  saveFileToSandbox() {
    try {
      let saveFile = fileIo.openSync(this.localProfilePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      let file = fileIo.openSync(distributedPath, fileIo.OpenMode.READ_WRITE);
      let buf: ArrayBuffer = new ArrayBuffer(4096);
      let readSize = 0;
      let readLen = fileIo.readSync(file.fd, buf, { offset: readSize });
      while (readLen > 0) {
        readSize += readLen;
        fileIo.writeSync(saveFile.fd, buf);
        readLen = fileIo.readSync(file.fd, buf, { offset: readSize });
      }
      fileIo.closeSync(file);
      fileIo.closeSync(saveFile);
      Logger.info(TAG, 'saveFileToSandbox success, distributedPath is:' + this.localProfilePath);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      Logger.error(TAG, `saveFileToSandbox Failed to openSync / writeSync / closeSync. Code: ${err.code}, message: ${err.message}`);
    }
  }

  deleteDistributedFile() {
    fileIo.rmdir(distributedPath, (err: BusinessError) => {
      if (err) {
        Logger.error(TAG, 'rmdir failed with error message: ' + err.message + ', error code: ' + err.code);
      } else {
        Logger.info(TAG, 'rmdir succeed');
      }
    });
  }

  onBackPress(): boolean {
    this.checkBackAction(true);
    return true;
  }

  @Builder
  MenuBuilder() {
    Image($r('app.media.ic_public_ok'))
      .height($r('app.float.normal_icon_size'))
      .width($r('app.float.normal_icon_size'))
      .fillColor(Color.Black)
      .onClick(() => {
        this.saveFileToSandbox();
        this.profilePath = this.localProfilePath;
        this.appPathStack.pop();
        let imageSource: image.ImageSource = image.createImageSource(this.profilePath);
        imageSource.createPixelMap((err, pixelmap) => {
          AppStorage.setOrCreate('pixelmap', pixelmap);
          this.showTag++;
          this.appPathStack.pop();
        });
      })
  }

  checkBackAction(isCenter?: boolean) {
    AlertDialog.show(
      {
        message: $r('app.string.sure_cancel'),
        autoCancel: false,
        alignment: this.currentBreakpoint === (BreakpointTypeEnum.SM || isCenter) ? DialogAlignment.Center : DialogAlignment.TopStart,
        offset: this.currentBreakpoint === (BreakpointTypeEnum.SM || isCenter) ? { dx: 0, dy: 0 } : {
          dx: $r('app.float.xxl_padding_margin'),
          dy: Constants.NAVIGATION_HEIGHT + (AppStorage.get<number>('statusBarHeight') || 0)
        },
        gridCount: 4,
        primaryButton: {
          value: $r('app.string.cancel'),
          action: () => {
            console.info('Button-clicking callback')
          }
        },
        secondaryButton: {
          value: $r('app.string.sure'),
          action: () => {
            console.info('Button-clicking callback')
            this.deleteDistributedFile();
            this.appPathStack.pop();
          }
        }
      }
    )
  }

  build() {
    NavDestination() {
      Column() {
        TopNavigationView({
          onBackClick: () => {
            this.checkBackAction();
          }, title: $r('app.string.crop_photo'), menuView: this.MenuBuilder()
        })

        Stack() {
          Image(this.isContinue ? distributedProfilePath : this.uri)
            .mask(new Rect({
              width: CommonConstants.FULL_PERCENT,
              height: CommonConstants.FULL_PERCENT
            }).fill(Color.Gray))
            .aspectRatio(Constants.CLIP_RATIO_PHONE)
          Image(this.isContinue ? distributedProfilePath : this.uri)
            .aspectRatio(Constants.CLIP_RATIO_PHONE)
            .clip(new Circle({ height: Constants.CLIP_RATIO, width: Constants.CLIP_WIDTH })
              .position({
                y: Constants.CIRCLE_RATIO_Y,
                x: Constants.CLIP_MARGIN
              })
            )
        }
        .margin({ top: $r('app.float.xxl_padding_margin') })
        .width(imageWidth.getValue(this.currentBreakpoint))
      }
      .backgroundColor(Color.White)
      .padding({
        top: AppStorage.get<number>('statusBarHeight'),
        bottom: AppStorage.get<number>('naviIndicatorHeight') || 0
      })
      .height(CommonConstants.FULL_PERCENT)
      .justifyContent(FlexAlign.Start)
    }
    .hideTitleBar(true)
    .onShown(() => {
      WindowUtil.updateStatusBarColor(getContext(this), false);
    })
    .onHidden(() => {
      WindowUtil.updateStatusBarColor(getContext(this), true);
    })
    .onBackPressed(() => {
      return this.onBackPress();
    })
  }
}