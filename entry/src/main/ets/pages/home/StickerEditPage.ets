// pages/home/StickerEditPage.ets

import { Sticker } from '../../models/Sticker';
import { RdbHelper } from '../../database/RdbHelper';
import { UriParam } from '../../models/PageParams';
import { HdsSnackBar } from '../../components/hds/HdsSnackBar';
import { ImageProcessor } from '../../utils/ImageProcessor';
import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';

interface ColorResult {
  nr: number;
  ng: number;
  nb: number;
}

@Component
export struct StickerEditPage {
  @Consume('homePathStack') pathStack: NavPathStack;
  @State stickerUri: string = '';
  @State previewBg: string = '棋盘格';
  @State borderValue: number = 0;
  @State shadowOn: boolean = true;
  @State shadowIntensity: number = 0.5;
  @State isProcessing: boolean = false;
  private db: RdbHelper = RdbHelper.getInstance();
  private originalPixelMap: image.PixelMap | null = null;

  aboutToAppear(): void {
    const raw: object | null = this.pathStack.getParamByName('StickerEditPage') as object | null;
    if (raw) {
      const params: UriParam = raw as UriParam;
      this.stickerUri = params.uri;
      this.loadOriginalImage();
    }
  }

  aboutToDisappear(): void {
    this.originalPixelMap?.release?.();
    this.originalPixelMap = null;
  }

  async loadOriginalImage(): Promise<void> {
    try {
      this.originalPixelMap = await ImageProcessor.uriToPixelMap(this.stickerUri);
    } catch (err) {
      console.error('loadOriginalImage error:', JSON.stringify(err));
    }
  }

  private applyColorAdjustments(r: number, g: number, b: number): ColorResult {
    return { nr: r, ng: g, nb: b };
  }

  async renderWithEdits(srcPixelMap: image.PixelMap): Promise<image.PixelMap | null> {
    try {
      const info = await srcPixelMap.getImageInfo();
      const srcW = info.size.width;
      const srcH = info.size.height;
      const padding = Math.max(this.borderValue * 8, this.shadowOn ? 24 : 0);
      const canvasW = srcW + padding * 2;
      const canvasH = srcH + padding * 2;
      const offCanvas = new OffscreenCanvas(canvasW, canvasH);
      const ctx = offCanvas.getContext('2d');
      ctx.drawImage(srcPixelMap, padding, padding, srcW, srcH);

      if (this.borderValue > 0) {
        const borderSize = this.borderValue * 6;
        const subjectData = ctx.getImageData(padding, padding, srcW, srcH);
        const edgeW = srcW + borderSize * 2;
        const edgeH = srcH + borderSize * 2;
        const edgeBuffer = new ArrayBuffer(edgeW * edgeH * 4);
        const edgeView = new Uint8Array(edgeBuffer);
        for (let y = 0; y < srcH; y++) {
          for (let x = 0; x < srcW; x++) {
            const srcIdx = (y * srcW + x) * 4;
            const dstIdx = ((y + borderSize) * edgeW + (x + borderSize)) * 4;
            edgeView[dstIdx] = subjectData.data[srcIdx];
            edgeView[dstIdx + 1] = subjectData.data[srcIdx + 1];
            edgeView[dstIdx + 2] = subjectData.data[srcIdx + 2];
            edgeView[dstIdx + 3] = subjectData.data[srcIdx + 3];
          }
        }
        for (let i = 0; i < edgeW * edgeH; i++) {
          const idx = i * 4;
          if (edgeView[idx + 3] > 0) {
            edgeView[idx] = 255;
            edgeView[idx + 1] = 255;
            edgeView[idx + 2] = 255;
            edgeView[idx + 3] = 255;
          }
        }
        const edgePixelMap = await image.createPixelMap(edgeBuffer, {
          size: { width: edgeW, height: edgeH },
          pixelFormat: image.PixelMapFormat.RGBA_8888,
        });
        ctx.globalCompositeOperation = 'destination-over';
        ctx.drawImage(edgePixelMap, padding - borderSize, padding - borderSize);
        ctx.globalCompositeOperation = 'source-over';
        edgePixelMap.release?.();
      }

      if (this.shadowOn) {
        const shadowAlpha = Math.round(this.shadowIntensity * 25);
        ctx.save();
        ctx.shadowColor = `rgba(0,0,0,${shadowAlpha / 100})`;
        ctx.shadowBlur = 16;
        ctx.shadowOffsetX = 2;
        ctx.shadowOffsetY = 6;
        ctx.fillStyle = 'rgba(0,0,0,0.01)';
        ctx.fillRect(padding, padding, srcW, srcH);
        ctx.restore();
      }

      const exportData = ctx.getImageData(0, 0, canvasW, canvasH);
      const rawData = new Uint8Array(exportData.data);
      const pixelBuffer = rawData.buffer.slice(rawData.byteOffset, rawData.byteOffset + rawData.byteLength);
      const pixelMap = await image.createPixelMap(pixelBuffer, {
        size: { width: canvasW, height: canvasH },
        pixelFormat: image.PixelMapFormat.RGBA_8888,
      });
      return pixelMap;
    } catch (err) {
      console.error('renderWithEdits error:', JSON.stringify(err));
      return null;
    }
  }

  async saveSticker(): Promise<void> {
    if (!this.originalPixelMap) {
      HdsSnackBar.show({ message: '图片加载中，请稍候' });
      return;
    }
    this.isProcessing = true;
    try {
      const processed = await this.renderWithEdits(this.originalPixelMap);
      if (!processed) {
        HdsSnackBar.show({ message: '图片处理失败' });
        return;
      }
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const savedUri = await ImageProcessor.savePixelMapToFile(processed, context, `sticker_${Date.now()}.png`);
      if (!savedUri) {
        HdsSnackBar.show({ message: '文件保存失败' });
        return;
      }
      const now = Date.now();
      const sticker: Sticker = {
        id: 0,
        uri: savedUri,
        category: '其他',
        createdAt: now,
        updatedAt: now,
      };
      await this.db.insertSticker(sticker);
      const param: UriParam = { uri: sticker.uri };
      this.pathStack.pushPathByName('SaveSuccessPage', param);
    } catch (err) {
      console.error('saveSticker error:', JSON.stringify(err));
      HdsSnackBar.show({ message: '保存失败，请重试' });
    } finally {
      this.isProcessing = false;
    }
  }

  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));

  @Builder
  PreviewBackground() {
    Canvas(this.canvasContext)
      .width('100%')
      .height('100%')
      .backgroundColor(
        this.previewBg === '米色' ? '#F5F0E8' :
        (this.previewBg === '深色' ? '#333333' : '#F0F0F0')
      )
      .onReady(() => {
        if (this.previewBg !== '棋盘格') return;
        const ctx = this.canvasContext;
        const size = 20;
        const width = ctx.width;
        const height = ctx.height;
        for (let x = 0; x < width; x += size) {
          for (let y = 0; y < height; y += size) {
            ctx.fillStyle = ((x / size + y / size) % 2 === 0) ? '#FFFFFF' : '#E5E5E5';
            ctx.fillRect(x, y, size, size);
          }
        }
      })
  }

  private get previewBorderWidth(): number {
    return this.borderValue * 6;
  }

  private get previewShadow(): ShadowOptions | undefined {
    if (!this.shadowOn) return undefined;
    return {
      radius: 12,
      color: `rgba(0,0,0,${Math.round(this.shadowIntensity * 20) / 100})`,
      offsetX: 2,
      offsetY: 4
    };
  }

  build() {
    Column() {
      // 顶部操作栏：返回 + 完成
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([$r('app.color.ink_deep')])
          .onClick(() => { this.pathStack.pop(); })

        Blank().layoutWeight(1)

        Text(this.isProcessing ? '保存中...' : '完成')
          .fontSize(16)
          .fontColor(this.isProcessing ? $r('app.color.ink_light') : $r('app.color.brand_primary'))
          .fontWeight(FontWeight.Medium)
          .onClick(() => { if (!this.isProcessing) this.saveSticker(); })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      // 预览区
      Stack() {
        this.PreviewBackground()

        Image(this.stickerUri)
          .objectFit(ImageFit.Contain)
          .width('70%')
          .border(this.borderValue > 0 ? {
            width: this.previewBorderWidth,
            color: Color.White,
            style: BorderStyle.Solid
          } : undefined)
          .shadow(this.previewShadow)
      }
      .layoutWeight(1)
      .width('100%')

      // 底部编辑面板
      Column({ space: 16 }) {
        // 描边
        Column({ space: 8 }) {
          Text('描边')
            .fontSize(14)
            .fontColor($r('app.color.ink_mid'))
            .width('100%')

          Row({ space: 12 }) {
            ForEach(['小', '中', '大'], (label: string, index: number) => {
              Text(label)
                .fontSize(14)
                .fontWeight(this.borderValue === index ? FontWeight.Medium : FontWeight.Normal)
                .fontColor(this.borderValue === index ? $r('app.color.brand_primary') : $r('app.color.ink_mid'))
                .backgroundColor(this.borderValue === index ? $r('app.color.brand_primary_light') : $r('app.color.chip_bg'))
                .padding({ top: 8, bottom: 8, left: 32, right: 32 })
                .borderRadius(20)
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .onClick(() => { this.borderValue = index; })
            })
          }
          .width('100%')
        }
        .width('100%')

        // 阴影
        Row() {
          Text('阴影')
            .fontSize(14)
            .fontColor($r('app.color.ink_mid'))

          Blank().layoutWeight(1)

          Toggle({ type: ToggleType.Switch, isOn: this.shadowOn })
            .selectedColor($r('app.color.brand_primary'))
            .onChange((isOn: boolean) => { this.shadowOn = isOn; })
        }
        .width('100%')

        // 预览效果
        Column({ space: 8 }) {
          Text('预览效果')
            .fontSize(14)
            .fontColor($r('app.color.ink_mid'))
            .width('100%')

          Row({ space: 12 }) {
            // 棋盘格
            Stack() {
              Canvas(this.canvasContext)
                .width('100%')
                .height('100%')
                .onReady(() => {
                  const ctx = this.canvasContext;
                  const size = 10;
                  for (let x = 0; x < ctx.width; x += size) {
                    for (let y = 0; y < ctx.height; y += size) {
                      ctx.fillStyle = ((x / size + y / size) % 2 === 0) ? '#FFFFFF' : '#E5E5E5';
                      ctx.fillRect(x, y, size, size);
                    }
                  }
                })
            }
            .width(56)
            .height(56)
            .borderRadius(12)
            .border(this.previewBg === '棋盘格' ? { width: 2, color: $r('app.color.brand_primary') } : undefined)
            .onClick(() => { this.previewBg = '棋盘格'; })

            // 米色
            Stack()
              .width(56)
              .height(56)
              .backgroundColor('#F5F0E8')
              .borderRadius(12)
              .border(this.previewBg === '米色' ? { width: 2, color: $r('app.color.brand_primary') } : undefined)
              .onClick(() => { this.previewBg = '米色'; })

            // 深色
            Stack()
              .width(56)
              .height(56)
              .backgroundColor('#333333')
              .borderRadius(12)
              .border(this.previewBg === '深色' ? { width: 2, color: $r('app.color.brand_primary') } : undefined)
              .onClick(() => { this.previewBg = '深色'; })
          }
          .width('100%')
        }
        .width('100%')

        // 收藏到贴纸库 大按钮
        Row({ space: 8 }) {
          SymbolGlyph($r('sys.symbol.heart'))
            .fontSize(18)
            .fontColor([Color.White])
          Text('收藏到贴纸库')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
        .width('100%')
        .height(48)
        .backgroundColor($r('app.color.brand_primary'))
        .borderRadius(24)
        .justifyContent(FlexAlign.Center)
        .onClick(() => { if (!this.isProcessing) this.saveSticker(); })
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius({ topLeft: 20, topRight: 20 })
      .shadow({ radius: 16, color: $r('app.color.shadow_float'), offsetX: 0, offsetY: -4 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_base'))
  }
}
