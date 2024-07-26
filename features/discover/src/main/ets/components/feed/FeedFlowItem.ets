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
import { LearningResource } from '@ohos/mine';

import { CommonConstants, CommonUtil, Logger, TagColorMap } from '@ohos/utils';

const MAX_TOPIC_NUM: number = 2;
const AGC_SERVICE: string = 'agc-storage-drcn.platform.dbankcloud.cn';
const TAG = '[FeedCardView]';

@Reusable
@Component
export struct FeedFlowItem {
  @Prop feedItem: LearningResource = new LearningResource();

  build() {
    Column() {
      Stack({ alignContent: Alignment.BottomEnd }) {
        Image(this.feedItem.headerImageUrl)
          .alt($r('app.media.img_placeholder'))
          .borderRadius({
            topLeft: $r('app.float.lg_border_radius'),
            topRight: $r('app.float.lg_border_radius')
          })
          .width(CommonConstants.FULL_PERCENT)
          .height(CommonConstants.FULL_PERCENT)
        ViewsCountLabel({ viewsCount: this.feedItem.viewsCount })
      }
      .width(CommonConstants.FULL_PERCENT)
      .aspectRatio(this.feedItem.headerImageUrl.includes(AGC_SERVICE) ? 1.4 : 1.8)

      Text(this.feedItem.title)
        .width(CommonConstants.FULL_PERCENT)
        .height($r('app.float.hot_feed_area_height'))
        .fontSize($r('app.float.md_font_size'))
        .textAlign(TextAlign.Start)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .lineHeight($r('app.float.view_count_height'))
        .maxLines(CommonConstants.MAX_LINE_TWO)
        .padding({
          top: $r('app.float.sm_padding_margin'),
          bottom: $r('app.float.xs_padding_margin'),
          left: $r('app.float.md_padding_margin'),
          right: $r('app.float.md_padding_margin')
        })

      Row() {
        if (this.feedItem.topics.length > 0) {
          ForEach(this.feedItem.topics.slice(0, MAX_TOPIC_NUM), (topic: string) => {
            LabelCard({ text: topic })
              .margin({ right: $r('app.float.xs_padding_margin') })
          }, (item: string) => item)
        }
      }
      .width(CommonConstants.FULL_PERCENT)
      .borderRadius({
        bottomLeft: $r('app.float.lg_border_radius'),
        bottomRight: $r('app.float.lg_border_radius')
      })
      .height(40)
      .padding({
        left: $r('app.float.md_padding_margin'),
        right: $r('app.float.md_padding_margin'),
        bottom: $r('app.float.md_padding_margin')
      })
    }
    .width(CommonConstants.FULL_PERCENT)
    .backgroundColor(Color.White)
    .borderRadius($r('app.float.lg_border_radius'))
  }
}


@Component
struct LabelCard {
  @Prop text: string = '';

  build() {
    Row() {
      Text(this.text)
        .fontSize($r('app.float.xs_font_size'))
        .fontColor('#' + TagColorMap.get(this.text))
        .textAlign(TextAlign.Center)
        .fontWeight(FontWeight.Medium)
        .fontFamily(CommonConstants.HARMONY_HEITI_MEDIUM_FONT_FAMILY)
    }
    .borderRadius($r('app.float.xs_border_radius'))
    .backgroundColor('#1A' + TagColorMap.get(this.text))
    .padding({
      left: $r('app.float.sm_padding_margin'),
      right: $r('app.float.sm_padding_margin'),
      top: $r('app.float.feed_label_padding'),
      bottom: $r('app.float.feed_label_padding')
    })
  }
}

@Component
struct ViewsCountLabel {
  @Prop viewsCount: number = 0;

  build() {
    Row() {
      Image($r('app.media.ic_eye_open'))
        .size({ width: $r('app.float.icon_size'), height: $r('app.float.icon_size') })
        .fillColor(Color.White)
        .margin({ right: $r('app.float.xs_padding_margin') })

      Text(CommonUtil.transNumberOverOneThousand(this.viewsCount))
        .fontSize($r('app.float.sm_font_size'))
        .textAlign(TextAlign.Center)
        .fontColor(Color.White)
        .opacity(CommonConstants.FIRST_LEVEL_OPACITY)
    }
    .height($r('app.float.view_count_height'))
    .padding({ left: $r('app.float.xs_padding_margin'), right: $r('app.float.xs_padding_margin') })
    .backgroundColor($r('app.color.view_counts_bg_color'))
    .borderRadius($r('app.float.md_border_radius'))
    .margin({ right: $r('app.float.sm_padding_margin'), bottom: $r('app.float.sm_padding_margin') })
  }
}