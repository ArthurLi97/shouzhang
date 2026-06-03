// models/Sticker.ets
// 贴纸原始资源

export interface Sticker {
  id?: number;
  image: string;      // 图片文件 URI
  collectionId: number;
}
