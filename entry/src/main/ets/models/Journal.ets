// models/Journal.ets
// 保存的手账作品

export interface Journal {
  id: number;
  title: string;
  canvasSnapshot: string;  // 缩略图 URI
}
