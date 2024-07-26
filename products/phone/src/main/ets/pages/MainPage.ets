/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License,Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { image } from '@kit.ImageKit';
import { display } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { ActivityView } from '@ohos/activity';
import { fileIo } from '@kit.CoreFileKit';
import { ArticleDetailView, DiscoverView, FeedWaterFlow } from '@ohos/discover';
import { LearningDetailPage, LearningPath, LearningView } from '@ohos/learning';
import { ChallengeDetailPage, ChallengeView, IntroductionPage } from '@ohos/challenge';
import { BreakpointSystem, BreakpointTypeEnum, Logger, ResourcesType, WindowUtil } from '@ohos/utils';
import { ConfirmPage, LearningResource, MineView, PhotoPage, UserModel } from '@ohos/mine';
import { AppConstants } from '../constants/AppConstants';
import { CustomTabBar } from '../components/CustomTabBar';
import { TabBarType } from '../model/TabBarModel';
import { GlobalContext } from '@ohos/datastore';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = '[App]';
const context = (getContext(this) as common.UIAbilityContext);

/**
 * profile path init;
 */
PersistentStorage.persistProp('profilePath', '');
PersistentStorage.persistProp('showTag', 0);
let storage = LocalStorage.getShared()

@Entry(storage)
@Component
struct MainPage {
  @LocalStorageLink('mainTabIndex') currentIndex: TabBarType = TabBarType.DISCOVER;
  @State webViewController: webview.WebviewController | null = null;
  @State learnedId: string = '';
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.MD;
  private breakpointSystem: BreakpointSystem = new BreakpointSystem();
  @Provide('appPathStack') appPathStack: NavPathStack = new NavPathStack();
  @Provide('minePathStack') minePathStack: NavPathStack = new NavPathStack();
  @Provide('discoverPathStack') discoverPathStack: NavPathStack = new NavPathStack();
  @StorageLink('profilePath') profilePath: string = '';
  @StorageLink('showTag') showTag: number = 0;

  aboutToAppear() {
    this.breakpointSystem.register();
    try {
      if (display.isFoldable()) {
        this.changeOrientation(display.getFoldStatus());
        display.on('foldStatusChange', (status: display.FoldStatus) => {
          this.changeOrientation(status);
        });
      }
    } catch (exception) {
      Logger.error(TAG, 'Is not foldable device error: ' + JSON.stringify(exception));
    }

    WindowUtil.setMissionContinueActive(context, true);

    let isContinue: boolean = GlobalContext.getContext().getObject('isContinue') as boolean;
    if (isContinue) {
      let userData: string = GlobalContext.getContext().getObject('userData') as string;
      UserModel.getInstance().saveDistributedUserData(userData)
    }
    this.createProfile()
  }

  createProfile() {
    let distributedPath: string = `${context.distributedFilesDir}/temp_profile.jpg`;
    let localProfilePath = `${context.cacheDir}/${AppStorage.get<string>('userId') as string}_profile.jpg`;
    let isDisProfileAccess = fileIo.accessSync(distributedPath);
    Logger.info(TAG, 'isDisProfileAccess:' + isDisProfileAccess);
    if (isDisProfileAccess) {
      try {
        let saveFile = fileIo.openSync(localProfilePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
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
      } catch (error) {
        let err: BusinessError = error as BusinessError;
        Logger.error(TAG, `createProfile Failed to openSync / writeSync / closeSync. Code: ${err.code}, message: ${err.message}`);
      }
    }
    let isLocalProfileAccess = fileIo.accessSync(localProfilePath);
    if (isLocalProfileAccess) {
      Logger.info(TAG, 'isLocalProfileAccess:' + isLocalProfileAccess);
      let imageSource: image.ImageSource = image.createImageSource(localProfilePath);
      imageSource.createPixelMap((err, pixelmap) => {
        AppStorage.setOrCreate('pixelmap', pixelmap);
        this.profilePath = localProfilePath;
        this.showTag++;
      });
    }
  }

  changeOrientation(status: display.FoldStatus) {
    if (status !== display.FoldStatus.FOLD_STATUS_FOLDED) {
      AppStorage.setOrCreate('foldExpanded', true);
      WindowUtil.setMainWindowRestricted(getContext(this));
    } else {
      AppStorage.setOrCreate('foldExpanded', false);
      WindowUtil.setMainWindowPortrait(getContext(this));
    }
  }

  aboutToDisappear() {
    this.breakpointSystem.unregister();
    try {
      display.off('foldStatusChange');
      display.off('change');
    } catch (exception) {
      console.error('Failed to unregister callback. Code: ' + JSON.stringify(exception));
    }
    WindowUtil.setMissionContinueActive(context, false);
  }

  onPageShow() {
    let jumpArticleId: string = GlobalContext.getContext().getObject('articleId') as string;
    if (jumpArticleId) {
      GlobalContext.getContext().deleteObject('articleId');
      let article: LearningResource = new LearningResource();
      article.id = jumpArticleId;
      article.webUrl = GlobalContext.getContext().getObject('webUrl') as string;
      article.type = GlobalContext.getContext().getObject('type') as ResourcesType;
      this.appPathStack.pushPathByName('articleDetail', article);
    }
    if (this.currentIndex === TabBarType.MINE) {
      WindowUtil.updateStatusBarColor(getContext(this), true);
    }
    Logger.info(TAG, 'onPageShow');
    if (AppStorage.get<boolean>('getHomeResource')) {
      this.currentIndex = TabBarType.DISCOVER;
    }
  }

  onBackPress() {
    if (this.webViewController?.accessBackward()) {
      this.webViewController.backward();
      return true;
    }
    return false;
  }

  @Builder
  appRouter(name: string, param: object) {
    if (name === 'articleDetail') {
      ArticleDetailView({
        articleDetail: param as LearningResource,
        webViewController: $webViewController,
        onDestinationBack: () => this.onDestinationBack()
      })
    } else if (name === 'feedList') {
      FeedWaterFlow({
        onDestinationBack: () => this.appPathStack.pop()
      })
    } else if (name === 'learningDetail') {
      LearningDetailPage({
        learningItem: param as LearningPath,
        onDestinationBack: (learningId?: string) => {
          this.appPathStack.pop();
          this.learnedId = learningId || '';
        }
      })
    } else if (name === 'challengeDetail') {
      ChallengeDetailPage()
    } else if (name === 'introduction') {
      IntroductionPage({ currentZoneId: (param as Record<string, number>).id })
    } else if (name === 'PhotoPage') {
      PhotoPage()
    } else if (name === 'photoConfirm') {
      ConfirmPage({ uri: (param as Record<string, string>).uri })
    }
  }

  onDestinationBack(): boolean {
    if (this.webViewController?.accessBackward()) {
      this.webViewController.backward();
    } else {
      if (this.currentIndex === TabBarType.MINE) {
        WindowUtil.updateStatusBarColor(getContext(this), true);
      }
      this.appPathStack.pop();
    }
    return true;
  }

  build() {
    Navigation(this.appPathStack) {
      Stack() {
        if (this.currentBreakpoint === BreakpointTypeEnum.LG) {
          Image($r('app.media.ic_user_bg'))
            .width(AppConstants.FULL_PERCENT)
            .height(AppConstants.FULL_PERCENT)
        }

        Flex({
          direction: this.currentBreakpoint === BreakpointTypeEnum.LG ? FlexDirection.RowReverse : FlexDirection.Column,
        }) {
          Tabs({ index: this.currentIndex }) {
            TabContent() {
              DiscoverView()
            }

            TabContent() {
              LearningView({ learnedId: this.learnedId })
            }

            TabContent() {
              ChallengeView()
            }

            TabContent() {
              ActivityView({ webViewController: $webViewController })
            }

            TabContent() {
              MineView()
            }
          }
          .layoutWeight(1)
          .barHeight(0)
          .scrollable(false)
          .onChange((index) => {
            this.currentIndex = index;
          })

          CustomTabBar({ currentIndex: $currentIndex })
        }
        .width(AppConstants.FULL_PERCENT)
        .height(AppConstants.FULL_PERCENT)
        .backgroundColor((this.currentBreakpoint === BreakpointTypeEnum.LG && this.currentIndex === TabBarType.MINE) ?
        $r('app.color.clear_color') : $r('app.color.common_background_color'))
      }
    }
    .hideTitleBar(true)
    .navDestination(this.appRouter)
    .mode(NavigationMode.Stack)
  }
}