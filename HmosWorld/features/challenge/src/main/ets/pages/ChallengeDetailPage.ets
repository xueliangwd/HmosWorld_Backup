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

import { webview } from '@kit.ArkWeb';
import { GlobalContext } from '@ohos/datastore';
import { Logger } from '@ohos/utils';
import { TopNavigationView, WebView } from '@ohos/uicomponents';
import { ChallengeConstants } from '../constants/ChallengeConstants';

const TAG = '[ChallengeDetailPage]';

@Component
export struct ChallengeDetailPage {
  @State webViewController: webview.WebviewController = new webview.WebviewController();
  @Consume('appPathStack') appPathStack: NavPathStack;
  private url = 'https://developer.huawei.com/consumer/cn/hdc/hdc2023/codelabs/index.html';
  private stackName: string = '';

  onBackPress(): boolean {
    if (this.webViewController.accessBackward()) {
      this.webViewController.backward();
      return true;
    }
    return false;
  }

  aboutToAppear(): void {
    this.stackName = GlobalContext.getContext().getObject('stackName') as string;
    Logger.info(TAG, 'aboutToAppear stackName is:' + this.stackName);
    if (this.stackName === 'introduction') {
      GlobalContext.getContext().setObject('stackName', 'challengeDetail');
    }
  }

  aboutToDisappear(): void {
    Logger.info(TAG, 'aboutToDisappear stackName is:' + this.stackName);
    if (this.stackName === 'challengeDetail') {
      GlobalContext.getContext().setObject('stackName', 'introduction');
    }
  }

  build() {
    NavDestination() {
      Column() {
        TopNavigationView({
          title: $r('app.string.code_lab_challenge'),
          onBackClick: () => {
            const isBack: boolean = this.onBackPress();
            if (!isBack) {
              this.appPathStack.pop();
            }
          }
        })
        WebView({
          url: this.url,
          webViewController: $webViewController,
        })
      }
      .padding({ top: AppStorage.get<number>('statusBarHeight') })
      .width(ChallengeConstants.FULL_PERCENT)
      .height(ChallengeConstants.FULL_PERCENT)
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      return this.onBackPress();
    })
  }
}