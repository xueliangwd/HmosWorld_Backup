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

import { formInfo } from '@kit.FormKit';
import { abilityAccessCtrl, AbilityConstant, bundleManager, Permissions, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { buffer } from '@kit.ArkTS';
import { initialize } from '@hw-agconnect/hmcore';
import { Logger, WindowUtil } from '@ohos/utils';
import { AppConstants } from '../constants/AppConstants';
import { GlobalContext } from '@ohos/datastore';

const TAG = '[EntryAbility]';
let localStorage: LocalStorage = new LocalStorage();

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Logger.info(TAG, 'Ability onCreate');
    this.dynamicLoading();
    this.initAgc();
    this.handleParams(want);
    this.restoringData(want, launchParam);
    WindowUtil.setMissionContinueActive(this.context, false);
  }

  dynamicLoading(): void {
    try {
      import('@kit.ArkWeb').then(module => {
        module.webview.WebviewController.initializeWebEngine();
      });
    } catch (err) {
      Logger.error(TAG, 'dynamicLoading ArkWeb error:' + err);
    }
  }

  async initAgc() {
    Logger.info('initAgc');
    const context = this.context;
    const value = await context.resourceManager.getRawFileContent("agconnect-services.json");
    let json: string = buffer.from(value as ArrayBuffer).toString("utf8");
    initialize(this.context, JSON.parse(json));
  }

  handleParams(want: Want): void {
    if (want.parameters && want.parameters[formInfo.FormParam.IDENTITY_KEY] !== undefined) {
      Logger.info(TAG, 'onNewWant WantIN:');
      let curFormId = want.parameters[formInfo.FormParam.IDENTITY_KEY];
      let params: Record<string, string> = want.parameters as Record<string, string>;
      Logger.info(TAG, `onNewWant formId: ${curFormId}, message: ${JSON.stringify(params)}`);
      GlobalContext.getContext().setObject('articleId', params.articleId);
      GlobalContext.getContext().setObject('type', params.type);
      GlobalContext.getContext().setObject('webUrl', params.webUrl);
    }
  }

  onDestroy(): void {
    Logger.info(TAG, 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    Logger.info(TAG, 'Ability onWindowStageCreate');
    AppStorage.setOrCreate<number>('statusBarHeight', AppConstants.DEFAULT_STATUS_HEIGHT);
    WindowUtil.requestFullScreen(windowStage, this.context);
    windowStage.loadContent('pages/SplashPage', localStorage);
  }

  onWindowStageRestore(windowStage: window.WindowStage): void {
    AppStorage.setOrCreate<number>('statusBarHeight', AppConstants.DEFAULT_STATUS_HEIGHT);
    WindowUtil.requestFullScreen(windowStage, this.context);
    Logger.info(TAG, 'Ability onWindowStageRestore');
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Logger.info(TAG, 'onNewWant want:' + JSON.stringify(want));
    this.handleParams(want);
    this.restoringData(want, launchParam);
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    Logger.info(TAG, 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    Logger.info(TAG, 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    Logger.info(TAG, 'Ability onBackground');
  }

  async checkPermissions(): Promise<void> {
    const permissions: Array<Permissions> = ["ohos.permission.DISTRIBUTED_DATASYNC"];
    const accessManager = abilityAccessCtrl.createAtManager();
    try {
      const bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION;
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleFlags);
      const grantStatus = await accessManager.checkAccessToken(bundleInfo.appInfo.accessTokenId, permissions[0]);

      if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
        accessManager.requestPermissionsFromUser(this.context, permissions)
      }
    } catch (err) {
      Logger.error('EntryAbility', 'checkPermissions', `Catch err: ${err}`);
      return;
    }
  }

  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    wantParam["mainTabIndex"] = localStorage.get('mainTabIndex') as number;
    wantParam["mineTabIndex"] = localStorage.get('mineTabIndex') as number;
    wantParam["userId"] = AppStorage.get<string>('userId') as string;
    wantParam["articleItem"] = GlobalContext.getContext().getObject('articleItem') as string;
    wantParam["stackName"] = GlobalContext.getContext().getObject('stackName') as string;
    wantParam["userData"] = GlobalContext.getContext().getObject('userData') as string;
    wantParam["learningItem"] = GlobalContext.getContext().getObject('learningItem') as string;
    wantParam["introductionItem"] = GlobalContext.getContext().getObject('introductionItem') as string;
    wantParam["isLogged"] = AppStorage.get<boolean>('isLogged') as boolean;
    Logger.info(TAG, 'onContinue wantParam:' + JSON.stringify(wantParam));
    return AbilityConstant.OnContinueResult.AGREE;
  }

  async restoringData(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    Logger.info(TAG, 'Ability restoringData1');
    this.checkPermissions();
    // Recovering migrated data from want.
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      Logger.info(TAG, 'Ability restoringData');
      if (want.parameters != undefined) {
        Logger.info(TAG, 'restoringData parameters:' + JSON.stringify(want.parameters));
        localStorage.setOrCreate('mainTabIndex', want.parameters.mainTabIndex)
        localStorage.setOrCreate('mineTabIndex', want.parameters.mineTabIndex)
        GlobalContext.getContext().setObject('articleItem', want.parameters.articleItem);
        GlobalContext.getContext().setObject('stackName', want.parameters.stackName);
        GlobalContext.getContext().setObject('userData', want.parameters.userData);
        GlobalContext.getContext().setObject('learningItem', want.parameters.learningItem);
        GlobalContext.getContext().setObject('introductionItem', want.parameters.introductionItem);
        GlobalContext.getContext().setObject('isContinue', true);
        AppStorage.setOrCreate('userId', want.parameters.userId);
        AppStorage.setOrCreate('isLogged', want.parameters.isLogged);
      }
      this.context.restoreWindowStage(localStorage);
    }
  }
}
