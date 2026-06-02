// utils/CanvasExporter.ets
// 画布离屏渲染导出工具

import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { CanvasItem } from '../models/CanvasItem';
import { BackgroundConfig } from '../models/BackgroundConfig';

const EXPORT_WIDTH = 1080;
const EXPORT_HEIGHT = 1350; // 4:5 比例

export class CanvasExporter {
  /** 导出过程中的图片缓存，避免同一 URI 重复解码 */
  private static imageCache: Map<string, image.PixelMap> = new Map();

  /**
   * 将画布内容导出为 PNG 图片文件
   */
  static async exportToFile(
    items: CanvasItem[],
    background: BackgroundConfig,
    context: Context
  ): Promise<string | null> {
    // 清空缓存，防止上次导出的残留
    CanvasExporter.clearCache();

    try {
      // 创建离屏 Canvas
      const offCanvas = new OffscreenCanvas(EXPORT_WIDTH, EXPORT_HEIGHT);
      const ctx = offCanvas.getContext('2d');

      // 1. 绘制背景
      await CanvasExporter.drawBackground(ctx, background);

      // 2. 按 zIndex 排序后绘制元素
      const sortedItems = [...items].sort((a, b) => a.zIndex - b.zIndex);
      for (const item of sortedItems) {
        await CanvasExporter.drawItem(ctx, item);
      }

      // 3. 读取像素数据并创建 PixelMap
      const imageData = ctx.getImageData(0, 0, EXPORT_WIDTH, EXPORT_HEIGHT);
      const rawData = new Uint8Array(imageData.data);
      const pixelBuffer = rawData.buffer.slice(rawData.byteOffset, rawData.byteOffset + rawData.byteLength);
      const exportedPixelMap = await image.createPixelMap(pixelBuffer, {
        size: { width: EXPORT_WIDTH, height: EXPORT_HEIGHT },
        pixelFormat: image.PixelMapFormat.RGBA_8888,
      });

      // 4. 保存为 PNG
      const dir = context.filesDir + '/canvas';
      try {
        fileIo.accessSync(dir);
      } catch {
        fileIo.mkdirSync(dir);
      }
      const filePath = dir + `/canvas_${Date.now()}.png`;

      const imagePacker = image.createImagePacker();
      const packOpts: image.PackingOption = {
        format: 'image/png',
        quality: 100,
      };
      const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
      await imagePacker.packToFile(exportedPixelMap, file.fd, packOpts);
      imagePacker.release?.();
      exportedPixelMap.release?.();
      fileIo.closeSync(file);

      return `file://${filePath}`;
    } catch (err) {
      console.error('exportToFile error:', JSON.stringify(err));
      return null;
    } finally {
      // 确保无论成功失败都释放缓存
      CanvasExporter.clearCache();
    }
  }

  /**
   * 从缓存获取 PixelMap，未缓存则从 URI 加载
   */
  private static async getCachedPixelMap(uri: string): Promise<image.PixelMap | null> {
    const cached = CanvasExporter.imageCache.get(uri);
    if (cached) {
      return cached;
    }

    try {
      const imageSource = image.createImageSource(uri);
      const pixelMap = await imageSource.createPixelMap();
      // 注意：imageSource 释放后 pixelMap 仍然可用
      imageSource.release?.();
      CanvasExporter.imageCache.set(uri, pixelMap);
      return pixelMap;
    } catch (err) {
      console.error('getCachedPixelMap error:', JSON.stringify(err));
      return null;
    }
  }

  /**
   * 清空图片缓存并释放所有 PixelMap
   */
  private static clearCache(): void {
    CanvasExporter.imageCache.forEach((pm) => {
      pm.release?.();
    });
    CanvasExporter.imageCache.clear();
  }

  /**
   * 绘制背景
   */
  private static async drawBackground(
    ctx: OffscreenCanvasRenderingContext2D,
    config: BackgroundConfig
  ): Promise<void> {
    const baseColor = config.value || '#FFF8F0';

    if (config.type === 'color' || config.type === 'grid' || config.type === 'dot' ||
        config.type === 'paper' || config.type === 'matte' || config.type === 'pattern') {
      ctx.fillStyle = baseColor;
      ctx.fillRect(0, 0, EXPORT_WIDTH, EXPORT_HEIGHT);
    }

    if (config.type === 'grid') {
      ctx.strokeStyle = 'rgba(0,0,0,0.06)';
      ctx.lineWidth = 1;
      const gridSize = 40;
      for (let x = 0; x <= EXPORT_WIDTH; x += gridSize) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, EXPORT_HEIGHT);
        ctx.stroke();
      }
      for (let y = 0; y <= EXPORT_HEIGHT; y += gridSize) {
        ctx.beginPath();
        ctx.moveTo(0, y);
        ctx.lineTo(EXPORT_WIDTH, y);
        ctx.stroke();
      }
    } else if (config.type === 'dot') {
      ctx.fillStyle = 'rgba(0,0,0,0.08)';
      const spacing = 30;
      const radius = 2;
      for (let x = spacing; x < EXPORT_WIDTH; x += spacing) {
        for (let y = spacing; y < EXPORT_HEIGHT; y += spacing) {
          ctx.beginPath();
          ctx.arc(x, y, radius, 0, Math.PI * 2);
          ctx.fill();
        }
      }
    } else if (config.type === 'paper') {
      ctx.strokeStyle = 'rgba(0,0,0,0.04)';
      ctx.lineWidth = 0.5;
      const lineHeight = 24;
      for (let y = lineHeight; y < EXPORT_HEIGHT; y += lineHeight) {
        ctx.beginPath();
        ctx.moveTo(0, y);
        ctx.lineTo(EXPORT_WIDTH, y);
        ctx.stroke();
      }
    } else if (config.type === 'matte') {
      ctx.fillStyle = 'rgba(255,255,255,0.2)';
      for (let i = 0; i < 300; i++) {
        const x = Math.random() * EXPORT_WIDTH;
        const y = Math.random() * EXPORT_HEIGHT;
        const r = Math.random() * 2 + 0.5;
        ctx.beginPath();
        ctx.arc(x, y, r, 0, Math.PI * 2);
        ctx.fill();
      }
    } else if (config.type === 'image' && config.value) {
      const pm = await CanvasExporter.getCachedPixelMap(config.value);
      if (pm) {
        ctx.drawImage(pm, 0, 0, EXPORT_WIDTH, EXPORT_HEIGHT);
      } else {
        ctx.fillStyle = '#FFF8F0';
        ctx.fillRect(0, 0, EXPORT_WIDTH, EXPORT_HEIGHT);
      }
    }
  }

  /**
   * 绘制单个画布元素
   */
  private static async drawItem(ctx: OffscreenCanvasRenderingContext2D, item: CanvasItem): Promise<void> {
    ctx.save();

    const w = item.width;
    const h = item.height;
    const centerX = item.x + w / 2;
    const centerY = item.y + h / 2;
    const cornerRadius = 8;

    // 应用变换
    ctx.translate(centerX, centerY);
    ctx.scale(item.scale, item.scale);
    ctx.rotate(item.rotation * Math.PI / 180);
    ctx.translate(-w / 2, -h / 2);

    // 1. 绘制阴影
    if (item.shadowEnabled) {
      ctx.save();
      ctx.shadowColor = item.shadowColor;
      ctx.shadowBlur = 8;
      ctx.shadowOffsetX = 2;
      ctx.shadowOffsetY = 4;
      CanvasExporter.roundRect(ctx, 0, 0, w, h, cornerRadius);
      ctx.fillStyle = 'rgba(0,0,0,0.01)';
      ctx.fill();
      ctx.restore();
    }

    // 2. 绘制白色圆角底
    CanvasExporter.roundRect(ctx, 0, 0, w, h, cornerRadius);
    ctx.fillStyle = '#FFFFFF';
    ctx.fill();

    // 3. 绘制内容
    if (item.type === 'sticker' && item.uri) {
      const pixelMap = await CanvasExporter.getCachedPixelMap(item.uri);
      if (pixelMap) {
        const padding = 4;
        ctx.drawImage(pixelMap, padding, padding, w - padding * 2, h - padding * 2);
      } else {
        ctx.strokeStyle = '#CCCCCC';
        ctx.strokeRect(4, 4, w - 8, h - 8);
      }
    } else if (item.type === 'text' && item.content) {
      ctx.fillStyle = item.fontColor;
      ctx.font = `${item.fontSize}px sans-serif`;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(item.content, w / 2, h / 2);
    }

    // 4. 绘制描边
    if (item.borderWidth > 0) {
      CanvasExporter.roundRect(ctx, 0, 0, w, h, cornerRadius);
      ctx.lineWidth = item.borderWidth;
      ctx.strokeStyle = item.borderColor;
      ctx.stroke();
    }

    ctx.restore();
  }

  /**
   * 绘制圆角矩形路径
   */
  private static roundRect(
    ctx: OffscreenCanvasRenderingContext2D,
    x: number, y: number, w: number, h: number, r: number
  ): void {
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.lineTo(x + w - r, y);
    ctx.arcTo(x + w, y, x + w, y + r, r);
    ctx.lineTo(x + w, y + h - r);
    ctx.arcTo(x + w, y + h, x + w - r, y + h, r);
    ctx.lineTo(x + r, y + h);
    ctx.arcTo(x, y + h, x, y + h - r, r);
    ctx.lineTo(x, y + r);
    ctx.arcTo(x, y, x + r, y, r);
    ctx.closePath();
  }
}
