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
import { LazyDataSource, Logger } from '@ohos/utils';
import { LoadingLayout, NoMoreLayout, WebView } from '@ohos/uicomponents';
import { LearningConstants } from '../constants/LearningConstants';
import { LearningPath } from '../model/LearningPath';
import { LearningModel } from '../model/LearningModel';
import { LearningComment } from '../model/LearningComment';
import { CommentItem } from '../components/CommentItem';
import { GlobalContext } from '@ohos/datastore';


const TAG = '[LearningDetailPage]';

const LEARN_MIN_DURATION = 5;

@Component
export struct LearningDetailPage {
  @State learningModel: LearningModel = LearningModel.getInstance();
  @State commentList: Array<LearningComment> = [];
  @Prop learningItem: LearningPath = new LearningPath();
  onDestinationBack: (learningId?: string) => void = () => {
  };
  @Consume('appPathStack') appPathStack: NavPathStack;
  @State webViewController: webview.WebviewController = new webview.WebviewController();
  @State commentController: webview.WebviewController = new webview.WebviewController();
  @StorageProp('foldExpanded') foldExpanded: boolean = false;
  @State showComment: boolean = false;
  @State showCommentBtn: boolean = false;
  @State loadingCommentsStatus: boolean = false;
  private intervalId?: number;
  private learnSeconds: number = 0;
  @State learningCommentsDataSource: LazyDataSource<LearningComment> = this.learningModel.learningCommentsDataSource;

  aboutToDisappear(): void {
    GlobalContext.getContext().deleteObject('isContinue');
    GlobalContext.getContext().deleteObject('stackName');
  }

  onBackPressBack() {
    if (this.webViewController.accessBackward()) {
      this.webViewController.backward();
      return true;
    }
    if (this.learningItem.isLearned === false && this.learnSeconds >= LEARN_MIN_DURATION) {
      this.onDestinationBack(this.learningItem.id);
    } else {
      this.onDestinationBack();
    }
    return true;
  }

  startLearning(): void {
    if (!this.intervalId && (!this.learningItem.isLearned)) {
      this.learnSeconds = 0;
      this.intervalId = setInterval(() => {
        this.learnSeconds++;
        Logger.info(TAG, 'learnSeconds: ' + this.learnSeconds);
        if (this.learnSeconds === LEARN_MIN_DURATION) {
          clearInterval(this.intervalId);
          Logger.info(TAG, 'learning completed');
        }
      }, LearningConstants.ANIMATION_DURATION_NORMAL);
    }
  }

  loadingComments(isFirstLoad: boolean) {
    this.loadingCommentsStatus = true;
    this.learningModel.getLearningComments(this.learningItem.id, isFirstLoad).then(() => {
      this.loadingCommentsStatus = false;
    })
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Column() {
            Row() {
              Image($r('app.media.ic_back'))
                .width($r('app.float.normal_img_size'))
                .height($r('app.float.normal_img_size'))
                .margin({ left: $r('app.float.xxl_padding_margin'), right: $r('app.float.lg_padding_margin') })
                .onClick(() => this.onDestinationBack())

              Text(this.learningItem.title)
                .fontSize($r('app.float.title_text_size'))
                .fontWeight(FontWeight.Medium)
                .textAlign(TextAlign.Start)
            }
            .height($r('app.float.navigation_height'))
          }
          .padding({ top: AppStorage.get<number>('statusBarHeight') })

          if (this.foldExpanded && this.showCommentBtn) {
            Column() {
              Row() {
                Text($r('app.string.featured_reviews'))
                  .margin({ left: $r('app.float.xxl_padding_margin') })
                  .fontColor($r('app.color.double_title_color'))
                  .fontSize($r('app.float.font_size_large'))
                  .fontWeight(FontWeight.Medium)
                  .visibility(this.showComment ? Visibility.Visible : Visibility.None)
                  .layoutWeight(1)
                Image(this.showComment ? $r('app.media.ic_normal') : $r('app.media.ic_double'))
                  .margin({ top: $r('app.float.sm_padding_margin'), right: $r('app.float.xxl_padding_margin') })
                  .width($r('app.float.comment_icon_size'))
                  .aspectRatio(1)
                  .onClick(() => {
                    animateTo({ duration: LearningConstants.SWIPER_DURATION }, () => {
                      this.showComment = !this.showComment;
                      if (this.showComment) {
                        this.loadingComments(true);
                      }
                    });
                  })
              }
              .height($r('app.float.navigation_height'))
              .width(LearningConstants.FULL_PERCENT)
              .justifyContent(FlexAlign.End)
            }
            .padding({ top: AppStorage.get<number>('statusBarHeight') })
            .width(this.showComment ? LearningConstants.HALF_PERCENT : $r('app.float.menu_width'))
            .backgroundColor(this.showComment ? $r('app.color.common_background_color') : $r('app.color.white'))
          }
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width(LearningConstants.FULL_PERCENT)

        Row() {
          WebView({
            url: this.learningItem.url,
            webViewController: $webViewController,
            hiddenScrollBar: true,
            shouldShowExtBtn: () => {
              let webUrl: string = this.webViewController.getUrl();
              let shouldShow: boolean = webUrl.includes('/content?chapterId=');
              this.showCommentBtn = this.foldExpanded && shouldShow;
              if (!shouldShow) {
                animateTo({ duration: 300 }, () => {
                  this.showComment = false;
                });
              }
            },
            handlePageEnd: () => {
              this.startLearning();
            }
          })
            .layoutWeight(1)

          Row() {
            if (this.loadingCommentsStatus) {
              LoadingLayout()
            } else {
              List() {
                LazyForEach(this.learningModel.learningCommentsDataSource, (item: LearningComment, index: number) => {
                  ListItem() {
                    CommentItem({ item: item })
                      .onAppear(() => {
                        if (!this.loadingCommentsStatus && this.learningModel.hasNextPage && index + 3 === this.learningCommentsDataSource.dataArray.length) {
                          this.learningModel.getLearningComments(this.learningItem.id, false);
                        }
                      })
                  }
                })
                if (!this.loadingCommentsStatus && !this.learningModel.hasNextPage) {
                  ListItem() {
                    NoMoreLayout()
                  }
                }
              }
              .cachedCount(3)
              .padding({ left: $r('app.float.xxl_padding_margin'), right: $r('app.float.xxl_padding_margin') })
              .height(LearningConstants.FULL_PERCENT)
              .width(LearningConstants.FULL_PERCENT)
            }
          }
          .backgroundColor($r('app.color.common_background_color'))
          .clip(true)
          .width(this.foldExpanded && this.showComment ? LearningConstants.HALF_PERCENT : 0)
          .height(LearningConstants.FULL_PERCENT)
        }
        .layoutWeight(1)
      }
      .width(LearningConstants.FULL_PERCENT)
      .height(LearningConstants.FULL_PERCENT)
    }
    .height(LearningConstants.FULL_PERCENT)
    .width(LearningConstants.FULL_PERCENT)
    .hideTitleBar(true)
    .onHidden(() => {
      if (this.intervalId && this.intervalId > -1) {
        clearInterval();
        this.intervalId = undefined;
      }
    })
    .onBackPressed(() => {
      this.onBackPressBack();
      return true;
    })
  }
}