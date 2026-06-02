// models/CanvasItem.ets

@Observed
export class CanvasItem {
  id: string;
  type: 'sticker' | 'text';
  uri?: string;
  content?: string;
  x: number;
  y: number;
  scale: number;
  rotation: number;
  zIndex: number;
  width: number;
  height: number;
  borderWidth: number;
  borderColor: string;
  shadowEnabled: boolean;
  shadowColor: string;
  fontColor: string;
  fontSize: number;

  constructor(id: string, type: 'sticker' | 'text', x: number = 0, y: number = 0) {
    this.id = id;
    this.type = type;
    this.x = x;
    this.y = y;
    this.scale = 1;
    this.rotation = 0;
    this.zIndex = 0;
    this.width = 100;
    this.height = 100;
    this.borderWidth = 0;
    this.borderColor = '#FFFFFF';
    this.shadowEnabled = true;
    this.shadowColor = 'rgba(0,0,0,0.15)';
    this.fontColor = '#1A1A1A';
    this.fontSize = 24;
  }
}
