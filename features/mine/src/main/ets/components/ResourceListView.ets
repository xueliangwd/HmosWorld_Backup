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

import { common } from '@kit.AbilityKit';
import {
  BreakpointType,
  BreakpointTypeEnum,
  CommonConstants,
  EventTypeEnum,
  LazyDataSource,
  Logger,
  ObservedArray,
  ResourcesType,
  WindowUtil
} from '@ohos/utils';
import { NoMoreLayout } from '@ohos/uicomponents';
import { GlobalContext } from '@ohos/datastore';
import { ArticleCardView } from './ArticleCardView';
import { FeedCardView } from './FeedCardView';
import Constants from '../constants/Constants';
import { ScrollPosition } from './MineView';
import { UserModel } from '../model/UserModel';
import { ArticleDetailView } from './ArticleDetailView';
import { LearningResource } from '../model/LearningResource';

const eventHub: common.EventHub = (getContext(this) as common.UIAbilityContext).eventHub;

const TAG = '[ResourceListView]';

@Component
export struct ResourceListView {
  @Provide('listPathStack') listPathStack: NavPathStack = new NavPathStack();
  @Consume('appPathStack') appPathStack: NavPathStack;
  @State userModel: UserModel = UserModel.getInstance();
  @State collectedIds: ObservedArray<string> = this.userModel.collectedIds;
  @State likedIds: ObservedArray<string> = this.userModel.likedIds;
  @State listPosition: number = ScrollPosition.start;
  @State webViewController?: WebviewController = undefined;
  @Consume scrollPosition: number;
  @Consume('minePathStack') minePathStack: NavPathStack;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.MD;
  scrollerForScroll?: Scroller;
  scrollerForList?: Scroller;
  @State selectedId: string = '';
  @Link resDataSource: LazyDataSource<LearningResource>;

  isCollected(resourceId: string): boolean {
    return this.collectedIds.some((id: string) => id === resourceId);
  }

  isLiked(resourceId: string): boolean {
    return this.likedIds.some((id: string) => id === resourceId);
  }

  aboutToAppear() {
    let isContinue: boolean = GlobalContext.getContext().getObject('isContinue') as boolean;
    let stackName: string = GlobalContext.getContext().getObject('stackName') as string;
    Logger.info(TAG, 'aboutToAppear stackName is:' + stackName);

    if (isContinue && stackName === 'mineArticleDetail') {
      let learningStr: string = GlobalContext.getContext().getObject('articleItem') as string;
      let learningResource: LearningResource = JSON.parse(learningStr) as LearningResource;
      this.jumpDetail(learningResource, stackName)
    } else {
      if (this.currentBreakpoint === BreakpointTypeEnum.LG) {
        this.listPathStack.pushPathByName('', this.resDataSource.dataArray[0]);
        this.selectedId = this.resDataSource.dataArray[0].id;
      }
    }
  }

  @Builder
  listRouter(name: string, param: LearningResource) {
    ArticleDetailView({
      articleDetail: param,
      webViewController: $webViewController,
      isLarge: false,
      onDestinationBack: () => this.onDestinationBack()
    })
  }

  onDestinationBack(): boolean {
    if (this.webViewController?.accessBackward()) {
      this.webViewController.backward();
    } else {
      this.listPathStack.pop();
    }
    return true;
  }

  jumpDetail(item: LearningResource, stackName?: string) {
    GlobalContext.getContext().setObject('articleItem', JSON.stringify(item));
    this.selectedId = item.id;
    if (this.currentBreakpoint === BreakpointTypeEnum.LG) {
      if (stackName === 'mineArticleDetail') {
        this.minePathStack.pushPathByName('detailLarge', item);
      } else {
        this.listPathStack.pushPathByName('', item);
      }
    } else {
      GlobalContext.getContext().setObject('stackName', 'mineArticleDetail');
      WindowUtil.updateStatusBarColor(getContext(this), false);
      this.appPathStack.pushPathByName('articleDetail', item);
    }
  }

  build() {
    Navigation(this.listPathStack) {
      List({ space: CommonConstants.SPACE_12, scroller: this.scrollerForList }) {
        LazyForEach(this.resDataSource, (content: LearningResource) => {
          ListItem() {
            if (content.type === ResourcesType.ARTICLE) {
              ArticleCardView({
                articleItem: content,
                isSelected: this.currentBreakpoint === BreakpointTypeEnum.LG && this.selectedId == content.id,
                isCollected: this.isCollected(content.id),
                isLiked: this.isLiked(content.id),
                onCollected: () => {
                  eventHub.emit(EventTypeEnum.COLLECTED, {
                    resourceId: content.id,
                    resourceType: content.type,
                    actionValue: !this.isCollected(content.id)
                  })
                },
                onLiked: () => {
                  eventHub.emit(EventTypeEnum.LIKED, {
                    resourceId: content.id,
                    resourceType: content.type,
                    actionValue: !this.isLiked(content.id)
                  })
                },
                handleClick: () => {
                  this.jumpDetail(content)
                }
              })
                .reuseId('article')
            } else {
              FeedCardView({
                isSelected: this.currentBreakpoint === BreakpointTypeEnum.LG && this.selectedId == content.id,
                articleItem: content,
                handleClick: () => {
                  this.jumpDetail(content)
                }
              })
                .reuseId('feed')
            }
          }
          .backgroundColor($r('app.color.hmos_color_white'))
          .borderRadius($r('app.float.xxl_border_radius'))
          .margin({ right: $r('app.float.md_padding_margin') })
        }, (item: LearningResource) => item.id)
        ListItem() {
          NavRouter({ name: '', param: this.resDataSource.dataArray[0] }) {
            NoMoreLayout()
          }
        }
      }
      .cachedCount(3)
      .padding({
        left: new BreakpointType({
          sm: $r('app.float.md_padding_margin'),
          md: $r('app.float.xxl_padding_margin'),
          lg: $r('app.float.xxl_padding_margin')
        }).getValue(this.currentBreakpoint),
        right: new BreakpointType<Length>({
          sm: 0,
          md: $r('app.float.md_padding_margin'),
          lg: 0
        }).getValue(this.currentBreakpoint)
      })
      .lanes(new BreakpointType({ sm: 1, md: Constants.COUNT_TWO, lg: 1 }).getValue(this.currentBreakpoint))
      .width(CommonConstants.FULL_PERCENT)
      .height(CommonConstants.FULL_PERCENT)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.None)
      .onReachStart(() => {
        this.listPosition = ScrollPosition.start;
      })
      .onReachEnd(() => {
        this.listPosition = ScrollPosition.end;
      })
      .onScrollFrameBegin((offset: number) => {
        if (!((this.listPosition === ScrollPosition.start && offset < 0)
          || (this.listPosition === ScrollPosition.end && offset > 0))) {
          this.listPosition = ScrollPosition.center;
        }

        if (this.scrollPosition === ScrollPosition.end
          && (this.listPosition !== ScrollPosition.start || offset > 0)) {
          return { offsetRemain: offset };
        } else {
          this.scrollerForScroll?.scrollBy(0, offset);
          return { offsetRemain: 0 };
        }
      })
    }
    .navBarWidth(Constants.PERCENT_50)
    .navDestination(this.listRouter)
    .mode(this.currentBreakpoint === BreakpointTypeEnum.LG ? NavigationMode.Split : NavigationMode.Stack)
    .hideTitleBar(true)
  }
}