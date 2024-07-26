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
import { promptAction } from '@kit.ArkUI';
import { LearningResource } from '@ohos/mine';
import { ActionEventData } from '@ohos/mine/src/main/ets/model/ActionEventData';
import { EventTypeEnum, LazyDataSource, LoadingStatus, Logger, ResourcesType, ResponseData } from '@ohos/utils';
import { DiscoverNetFunc } from '../service/DiscoverNetFunc';
import { HomeResources } from './HomeResource';

const TAG = '[DiscoverModel]';

@Observed
export class DiscoverModel {
  private funNetwork: DiscoverNetFunc;
  // Home page data loaded for the first time
  loadingStatus: LoadingStatus = LoadingStatus.OFF;
  swiperData: LearningResource[] = [];
  // Load more articles
  loadingArticleStatus: LoadingStatus = LoadingStatus.OFF;
  hasNextArticle: boolean = true;
  curArticlePage: number = 0;
  // Load more feeds
  loadingFeedStatus: LoadingStatus = LoadingStatus.OFF;
  hasNextFeed: boolean = true;
  curFeedPage: number = 0;
  // Load detail
  detailLoadingStatus: LoadingStatus = LoadingStatus.OFF;
  private eventHub: common.EventHub = (getContext(this) as common.UIAbilityContext).eventHub;
  private static instance: DiscoverModel;
  feedArticleDataSource: LazyDataSource<LearningResource> = new LazyDataSource();
  techArticleDataSource: LazyDataSource<LearningResource> = new LazyDataSource();

  private constructor() {
    Logger.info(TAG, 'DiscoverModel constructor');
    this.funNetwork = new DiscoverNetFunc();
    // Subscribing to public events
    this.eventHub.on(EventTypeEnum.COLLECTED,
      (eventData: ActionEventData): void => this.setCollectionCount(eventData));
    this.eventHub.on(EventTypeEnum.LIKED, (eventData: ActionEventData): void => this.setLikesCount(eventData));
  }

  /**
   * Get discover model instance.
   *
   * @returns discover model instance.
   */
  public static getInstance(): DiscoverModel {
    if (!DiscoverModel.instance) {
      DiscoverModel.instance = new DiscoverModel();
    }
    return DiscoverModel.instance;
  }

  /**
   * Data loaded on the home page converts network data into page rendering data
   */
  getHomeResources(): Promise<void> {
    this.loadingStatus = LoadingStatus.LOADING;
    return new Promise((resolve, reject) => {
      this.funNetwork.getHomeResources().then((data: HomeResources) => {
        const feedArticleList: Array<LearningResource> = [];
        data.feedData.resourceList.forEach((res: LearningResource) => {
          feedArticleList.push(new LearningResource(res));
        });
        this.feedArticleDataSource.pushArrayData(feedArticleList);

        const techArticleList: Array<LearningResource> = [];
        data.articleData.resourceList.forEach((res: LearningResource) => {
          techArticleList.push(new LearningResource(res));
        });
        this.techArticleDataSource.pushArrayData(techArticleList);

        this.swiperData.length = 0;
        this.swiperData = data.bannerList;
        // load more info
        this.curArticlePage = data.articleData.currentPage;
        this.hasNextArticle = data.articleData.hasNext;
        this.curFeedPage = data.feedData.currentPage;
        this.hasNextFeed = data.feedData.hasNext;
        // loading status
        this.loadingStatus = LoadingStatus.SUCCESS;
        Logger.info(TAG, JSON.stringify(this.swiperData));
        resolve();
      }).catch((err: Error) => {
        this.loadingStatus = LoadingStatus.FAILED;
        Logger.error(TAG, `Init failed! Error message is ${err}`);
        reject();
      });
    });
  }

  /**
   * Load next page article data
   */
  loadMoreArticle(): Promise<LearningResource[]> {
    this.loadingArticleStatus = LoadingStatus.LOADING;
    return new Promise((resolve, reject) => {
      this.funNetwork.getMoreResources(this.curArticlePage + 1, ResourcesType.ARTICLE)
        .then((data: ResponseData<LearningResource>) => {
          const techArticleList: Array<LearningResource> = [];
          data.resourceList.forEach((res: LearningResource) => {
            techArticleList.push(new LearningResource(res));
          });
          this.techArticleDataSource.appendArrayData(techArticleList);
          this.curArticlePage = data.currentPage;
          this.hasNextArticle = data.hasNext;
          this.loadingArticleStatus = LoadingStatus.SUCCESS;
          Logger.info(TAG, 'LoadMore articles success!');
          resolve(data.resourceList)
        })
        .catch((err: Error) => {
          this.loadingArticleStatus = LoadingStatus.FAILED;
          promptAction.showToast({
            message: $r('app.string.load_failed')
          });
          Logger.error(TAG, `LoadMore articles failed! Error message is ${err}.`);
        });
    })
  }

  /**
   * Load next page feed data
   */
  loadMoreFeed(): void {
    if (this.hasNextFeed) {
      this.loadingFeedStatus = LoadingStatus.LOADING;
      this.funNetwork.getMoreResources(this.curFeedPage + 1, ResourcesType.FEED)
        .then((data: ResponseData<LearningResource>) => {
          const feedArticleList: Array<LearningResource> = [];
          data.resourceList.forEach((res: LearningResource) => {
            feedArticleList.push(new LearningResource(res));
          });
          this.feedArticleDataSource.appendArrayData(feedArticleList);

          this.curFeedPage = data.currentPage;
          this.hasNextFeed = data.hasNext;
          this.loadingFeedStatus = LoadingStatus.SUCCESS;
          Logger.info(TAG, 'LoadMore feed success!' + JSON.stringify(data));
        })
        .catch((err: Error) => {
          this.loadingFeedStatus = LoadingStatus.FAILED;
          promptAction.showToast({
            message: $r('app.string.load_failed')
          });
          Logger.error(TAG, `LoadMore feed failed! Error message is ${err}.`);
        });
    }
  }

  /**
   * Set view counts of feed or article by resourceId
   * @param resourceId
   */
  setViewsCount(resourceId: string): void {
    this.feedArticleDataSource.dataArray.forEach((res: LearningResource) => {
      if (res.id === resourceId) {
        res.viewsCount += 1;
      }
    });
    this.techArticleDataSource.dataArray.forEach((res: LearningResource) => {
      if (res.id === resourceId) {
        res.viewsCount += 1;
      }
    });
  }

  /**
   * Set collection count of feed or article through public event parameters
   * @param eventData
   */
  setCollectionCount(eventData: ActionEventData): void {
    if (eventData.resourceType === ResourcesType.FEED) {
      this.feedArticleDataSource.dataArray.forEach((res: LearningResource) => {
        if (res.id === eventData.resourceId) {
          res.collectionCount += eventData.actionValue ? 1 : -1;
        }
      });
    }
    if (eventData.resourceType === ResourcesType.ARTICLE) {
      this.techArticleDataSource.dataArray.forEach((res: LearningResource) => {
        if (res.id === eventData.resourceId) {
          res.collectionCount += eventData.actionValue ? 1 : -1;
        }
      });
    }
  }

  /**
   * Set likes count of feed or article through public event parameters
   * @param eventData
   */
  setLikesCount(eventData: ActionEventData): void {
    if (eventData.resourceType === ResourcesType.FEED) {
      this.feedArticleDataSource.dataArray.forEach((res: LearningResource) => {
        if (res.id === eventData.resourceId) {
          res.likesCount += eventData.actionValue ? 1 : -1;
        }
      });
    }
    if (eventData.resourceType === ResourcesType.ARTICLE) {
      this.techArticleDataSource.dataArray.forEach((res: LearningResource) => {
        if (res.id === eventData.resourceId) {
          res.likesCount += eventData.actionValue ? 1 : -1;
        }
      });
    }
  }
}

