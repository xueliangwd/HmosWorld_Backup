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

import { common } from '@kit.AbilityKit';
import { BreakpointType, BreakpointTypeEnum, EventTypeEnum, Logger } from '@ohos/utils';
import { GlobalContext } from '@ohos/datastore';
import { AchievementDialog } from './AchievementDialog';
import { LearningConstants } from '../constants/LearningConstants';
import { LearningPath } from '../model/LearningPath';
import { LearningModel } from '../model/LearningModel';
import { LearningItem } from './LearningItem';

const TAG = '[LearningView]';

@Component
export struct LearningView {
  private eventHub: common.EventHub = (getContext(this) as common.UIAbilityContext).eventHub;
  @Consume('appPathStack') appPathStack: NavPathStack;
  @Prop @Watch('handlePathLearned') learnedId: string = '';
  @State learningModel: LearningModel = LearningModel.getInstance();
  @State learningItem: LearningPath | null = null;
  @StorageLink('currentBreakpoint') currentBreakpoint: BreakpointTypeEnum = BreakpointTypeEnum.MD;
  achievementDialog: CustomDialogController = new CustomDialogController({
    builder: AchievementDialog({ learningItem: $learningItem }),
    alignment: DialogAlignment.Center,
    autoCancel: false,
    maskColor: $r('app.color.achieve_dialog_mask_color'),
    customStyle: true
  });

  aboutToAppear(): void {
    this.learningModel.init();
    let isContinue: boolean = GlobalContext.getContext().getObject('isContinue') as boolean;
    let stackName: string = GlobalContext.getContext().getObject('stackName') as string;
    Logger.info(TAG, 'aboutToAppear stackName is:' + stackName);
    if (isContinue && stackName === 'learningDetail') {
      let learningStr: string = GlobalContext.getContext().getObject('learningItem') as string;
      let learningPath: LearningPath = JSON.parse(learningStr) as LearningPath;
      this.appPathStack.pushPathByName('learningDetail', learningPath);
    }
  }

  handlePathLearned(): void {
    Logger.info(TAG, 'handlePathLearned');
    Logger.info(TAG, `learnedId:${this.learnedId}`);
    if (this.learnedId) {
      this.learningModel.updateLearnedPath(this.learnedId).then(() => {
        Logger.info(TAG, 'show Dialog');
        this.eventHub.emit(EventTypeEnum.LEARNING, this.learnedId);
        this.learningItem = this.learningModel.getLearningMap().get(this.learnedId) as LearningPath;
        this.achievementDialog.open();
      });
    }
  }

  @Builder
  NaviBar() {
    Row() {
      Text($r('app.string.learning_title'))
        .fontSize($r('app.float.navigation_title_size'))
        .fontWeight(FontWeight.Bold)
        .margin({ left: $r('app.float.navigation_margin') })
    }
    .height($r('app.float.navigation_height'))
    .width(LearningConstants.FULL_PERCENT)
    .justifyContent(FlexAlign.Start)
  }

  build() {
    Column() {
      this.NaviBar();
      List({ space: LearningConstants.LIST_SPACE }) {
        ForEach(this.learningModel.list, (item: LearningPath) => {
          ListItem() {
            LearningItem({ learningItem: item })
          }
          .margin({ right: $r('app.float.md_padding_margin') })
          .onClick(() => {
            GlobalContext.getContext().setObject('learningItem', JSON.stringify(item));
            GlobalContext.getContext().setObject('stackName', 'learningDetail');
            this.appPathStack.pushPathByName('learningDetail', item);
          })
        })
      }
      .padding({ left: $r('app.float.md_padding_margin') })
      .layoutWeight(1)
      .lanes(new BreakpointType({
        sm: LearningConstants.LEARNING_LANES_SM,
        md: LearningConstants.LEARNING_LANES_MD,
        lg: LearningConstants.LEARNING_LANES_LG
      }).getValue(this.currentBreakpoint))
    }
    .width(LearningConstants.FULL_PERCENT)
    .height(LearningConstants.FULL_PERCENT)
    .padding({ top: AppStorage.get<number>('statusBarHeight') })
    .backgroundColor($r('app.color.common_background_color'))
  }
}

