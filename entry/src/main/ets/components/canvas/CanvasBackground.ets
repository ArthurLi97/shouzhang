// components/canvas/CanvasBackground.ets
// 画布背景：使用 Canvas 2D 高性能绘制，避免 ForEach 创建大量组件
// 注意：父组件通过 .key() 强制重建来触发重绘，此处无需 @Watch

import { BackgroundConfig } from '../../models/BackgroundConfig';

@Component
export struct CanvasBackground {
  @Prop config: BackgroundConfig;
  @Prop instanceId: number = 0;
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));

  /** 获取实际使用的背景色 */
  private get bgColor(): string {
    if (this.config.type === 'color' && this.config.value === '#FFFFFF') {
      return '#FFF8F0';
    }
    return this.config.value.startsWith('#') ? this.config.value : '#FFF8F0';
  }

  private drawPattern(): void {
    const ctx = this.canvasContext;
    const width = ctx.width;
    const height = ctx.height;

    // 1. 基础背景色
    ctx.fillStyle = this.bgColor;
    ctx.fillRect(0, 0, width, height);

    // 2. 绘制图案
    switch (this.config.type) {
      case 'grid':
        this.drawGrid(ctx, width, height);
        break;
      case 'dot':
        this.drawDot(ctx, width, height);
        break;
      case 'paper':
        this.drawPaper(ctx, width, height);
        break;
      case 'matte':
        this.drawMatte(ctx, width, height);
        break;
      case 'pattern':
        this.drawCustomPattern(ctx, width, height);
        break;
      case 'image':
        // 图片背景在 build 中用 Image 组件覆盖
        break;
      default:
        // color 类型已填充基础色，无需额外绘制
        break;
    }
  }

  private drawCustomPattern(ctx: CanvasRenderingContext2D, width: number, height: number): void {
    switch (this.config.value) {
      case '波点':
        this.drawDot(ctx, width, height);
        break;
      case '条纹':
        this.drawStripe(ctx, width, height);
        break;
      case '方格':
        this.drawGrid(ctx, width, height);
        break;
      case '斜纹':
        this.drawDiagonal(ctx, width, height);
        break;
    }
  }

  private drawGrid(ctx: CanvasRenderingContext2D, width: number, height: number): void {
    ctx.strokeStyle = 'rgba(0,0,0,0.06)';
    ctx.lineWidth = 1;
    const gridSize = 40;
    ctx.beginPath();
    for (let x = 0; x <= width; x += gridSize) {
      ctx.moveTo(x, 0);
      ctx.lineTo(x, height);
    }
    for (let y = 0; y <= height; y += gridSize) {
      ctx.moveTo(0, y);
      ctx.lineTo(width, y);
    }
    ctx.stroke();
  }

  private drawDot(ctx: CanvasRenderingContext2D, width: number, height: number): void {
    ctx.fillStyle = 'rgba(0,0,0,0.08)';
    const spacing = 30;
    const radius = 2;
    for (let x = spacing; x < width; x += spacing) {
      for (let y = spacing; y < height; y += spacing) {
        ctx.beginPath();
        ctx.arc(x, y, radius, 0, Math.PI * 2);
        ctx.fill();
      }
    }
  }

  private drawPaper(ctx: CanvasRenderingContext2D, width: number, height: number): void {
    ctx.strokeStyle = 'rgba(0,0,0,0.04)';
    ctx.lineWidth = 0.5;
    const lineHeight = 24;
    ctx.beginPath();
    for (let y = lineHeight; y < height; y += lineHeight) {
      ctx.moveTo(0, y);
      ctx.lineTo(width, y);
    }
    ctx.stroke();
  }

  private drawMatte(ctx: CanvasRenderingContext2D, width: number, height: number): void {
    ctx.fillStyle = 'rgba(255,255,255,0.2)';
    for (let i = 0; i < 300; i++) {
      const x = Math.random() * width;
      const y = Math.random() * height;
      const r = Math.random() * 2 + 0.5;
      ctx.beginPath();
      ctx.arc(x, y, r, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  private drawStripe(ctx: CanvasRenderingContext2D, width: number, height: number): void {
    ctx.fillStyle = 'rgba(0,0,0,0.04)';
    const stripeHeight = 16;
    for (let y = 0; y < height; y += stripeHeight * 2) {
      ctx.fillRect(0, y, width, stripeHeight);
    }
  }

  private drawDiagonal(ctx: CanvasRenderingContext2D, width: number, height: number): void {
    ctx.strokeStyle = 'rgba(0,0,0,0.05)';
    ctx.lineWidth = 1;
    const spacing = 30;
    ctx.beginPath();
    for (let i = -height; i < width + height; i += spacing) {
      ctx.moveTo(i, 0);
      ctx.lineTo(i + height, height);
    }
    ctx.stroke();
  }

  build() {
    Stack() {
      Canvas(this.canvasContext)
        .width('100%')
        .height('100%')
        .onReady(() => {
          this.drawPattern();
        })

      // 图片背景层（覆盖在 Canvas 上方）
      if (this.config.type === 'image' && this.config.value) {
        Image(this.config.value)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
      }
    }
    .width('100%')
    .height('100%')
    .aspectRatio(4 / 5)
    .clip(true)
  }
}
