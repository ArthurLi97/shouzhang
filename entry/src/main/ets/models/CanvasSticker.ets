// models/CanvasSticker.ets
// 画布上的贴纸实例

@Observed
export class CanvasSticker {
  id: string;
  stickerId: number;   // 关联原始 Sticker.id
  x: number;
  y: number;
  scale: number;
  rotation: number;
  zIndex: number;
  width: number;
  height: number;

  constructor(id: string, stickerId: number, x: number = 0, y: number = 0) {
    this.id = id;
    this.stickerId = stickerId;
    this.x = x;
    this.y = y;
    this.scale = 1;
    this.rotation = 0;
    this.zIndex = 0;
    this.width = 100;
    this.height = 100;
  }
}
