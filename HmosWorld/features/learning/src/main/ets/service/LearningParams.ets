
export interface UserIdParams {
  userId: string;
}

export interface LearningParams extends UserIdParams {
  pathId: string;
}

export interface LearningCommentsParams extends UserIdParams {
  pathId: string;
  pageNum: number,
  pageSize: number
}
