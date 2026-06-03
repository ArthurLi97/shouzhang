// pages/home/StickerPreviewPage.ets
// 抠图结果预览 + Signature Sticker Creation Animation
// 保存时播放 900ms 物理贴纸诞生动画：白边生长 → 抬起 → 浮起 → 飞向 Collection

import { UriParam } from '../../models/PageParams';
import { RdbHelper } from '../../database/RdbHelper';
import { HdsSnackBar } from '../../components/hds/HdsSnackBar';
import { TEXT_PRIMARY } from '../../constants/ThemeConstants';

const BORDER_GROW_MS = 200;
const LIFT_MS = 150;
const FLOAT_MS = 200;
const FLY_MS = 250;
const LAND_MS = 100;
const TOTAL_MS = BORDER_GROW_MS + LIFT_MS + FLOAT_MS + FLY_MS + LAND_MS;

@Component
export struct StickerPreviewPage {
  @Consume('rootPathStack') pathStack: NavPathStack;
  @State uri: string = '';
  @State isAnimating: boolean = false;

  // 动画状态变量
  @State stickerPadding: number = 0;
  @State stickerRadius: number = 20;
  @State stickerScale: number = 1;
  @State stickerOffsetY: number = 0;
  @State stickerOpacity: number = 1;
  @State showLandCopy: boolean = false;
  @State landCopyScale: number = 0.3;
  @State landCopyOpacity: number = 0;

  aboutToAppear(): void {
    const raw: object | null = this.pathStack.getParamByName('StickerPreviewPage') as object | null;
    if (raw) {
      const params: UriParam = raw as UriParam;
      this.uri = params.uri;
    }
  }

  private delay(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  async onSaveTap(): Promise<void> {
    if (this.isAnimating) return;
    this.isAnimating = true;

    // ===== Signature Sticker Creation Animation =====

    // Stage 1: 白边生长 (0-200ms)
    // 白色边框从 0 渐长为 12px，圆角同步放大
    this.getUIContext()?.animateTo({ duration: BORDER_GROW_MS, curve: Curve.EaseInOut }, () => {
      this.stickerPadding = 12;
      this.stickerRadius = 24;
    });
    await this.delay(BORDER_GROW_MS + 20);

    // Stage 2: 轻微抬起 (200-350ms)
    // scale 1.0 → 1.05，shadow 加深感
    this.getUIContext()?.animateTo({ duration: LIFT_MS, curve: Curve.EaseInOut }, () => {
      this.stickerScale = 1.05;
    });
    await this.delay(LIFT_MS + 20);

    // Stage 3: 浮起 (350-550ms)
    // 贴纸向上浮动 30px，保持 scale
    this.getUIContext()?.animateTo({ duration: FLOAT_MS, curve: Curve.EaseInOut }, () => {
      this.stickerOffsetY = -30;
    });
    await this.delay(FLOAT_MS + 20);

    // Stage 4: 飞向 Collection (550-800ms)
    // 贴纸缩小并飞向屏幕底部（Collection Drawer 区域），同时淡出
    this.getUIContext()?.animateTo({ duration: FLY_MS, curve: Curve.FastOutSlowIn }, () => {
      this.stickerScale = 0.15;
      this.stickerOffsetY = 220;
      this.stickerOpacity = 0;
    });

    // 同时：在屏幕中央（Canvas 位置）显示 landing copy，soft-land
    await this.delay(FLY_MS * 0.4);
    this.showLandCopy = true;
    this.getUIContext()?.animateTo({ duration: LAND_MS + 80, curve: Curve.EaseOut }, () => {
      this.landCopyScale = 1;
      this.landCopyOpacity = 1;
    });
    await this.delay(FLY_MS * 0.6 + 40);

    // 动画完成，执行实际保存
    await this.saveSticker();
  }

  async saveSticker(): Promise<void> {
    if (!this.uri) return;
    try {
      const db = RdbHelper.getInstance();
      const collections = await db.getCollections();
      const firstCollectionId = collections.length > 0 ? collections[0].id : 1;

      const id = await db.insertSticker({
        image: this.uri,
        collectionId: firstCollectionId,
      });

      AppStorage.setOrCreate('pending_sticker_id', id);
      AppStorage.setOrCreate('pending_canvas_sticker', this.uri);
      this.pathStack.clear();
    } catch (err) {
      console.error('saveSticker error:', JSON.stringify(err));
      HdsSnackBar.show({ message: '保存失败' });
      this.isAnimating = false;
    }
  }

  retake(): void {
    AppStorage.setOrCreate('auto_open_picker', true);
    this.pathStack.clear();
  }

  build() {
    Stack() {
      Column({ space: 0 }) {
        // 顶部 Bar
        Row() {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(24)
            .fontColor([TEXT_PRIMARY])
            .onClick(() => { this.pathStack.clear(); })

          Blank().layoutWeight(1)

          Text('预览')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(TEXT_PRIMARY)

          Blank().layoutWeight(1)
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })

        // 动画区域
        Stack({ alignContent: Alignment.Center }) {
          // 主贴纸（带动画）
          Stack({ alignContent: Alignment.Center }) {
            Image(this.uri)
              .width('75%')
              .aspectRatio(1)
              .objectFit(ImageFit.Cover)
              .borderRadius(this.stickerRadius)
          }
          .padding(this.stickerPadding)
          .backgroundColor(this.stickerPadding > 0 ? Color.White : Color.Transparent)
          .borderRadius(this.stickerRadius + this.stickerPadding)
          .shadow({
            radius: this.stickerScale > 1 ? 24 : 20,
            color: this.stickerScale > 1 ? 'rgba(0,0,0,0.14)' : 'rgba(0,0,0,0.1)',
            offsetX: 0,
            offsetY: this.stickerScale > 1 ? 10 : 8
          })
          .scale({ x: this.stickerScale, y: this.stickerScale })
          .offset({ y: this.stickerOffsetY })
          .opacity(this.stickerOpacity)
          .animation({ duration: 200, curve: Curve.EaseInOut })

          // Landing Copy：飞向 Canvas 的副本
          if (this.showLandCopy) {
            Stack({ alignContent: Alignment.Center }) {
              Image(this.uri)
                .width(100)
                .height(100)
                .objectFit(ImageFit.Cover)
                .borderRadius(24)
            }
            .padding(12)
            .backgroundColor(Color.White)
            .borderRadius(36)
            .shadow({
              radius: 20,
              color: 'rgba(0,0,0,0.08)',
              offsetX: 0,
              offsetY: 6
            })
            .scale({ x: this.landCopyScale, y: this.landCopyScale })
            .opacity(this.landCopyOpacity)
            .animation({ duration: 180, curve: Curve.EaseOut })
          }
        }
        .width('100%')
        .layoutWeight(1)

        // 底部按钮区
        Column({ space: 12 }) {
          Button(this.isAnimating ? '正在保存...' : '保存贴纸', { type: ButtonType.Capsule })
            .width('90%')
            .height(48)
            .backgroundColor($r('app.color.dust_pink'))
            .fontColor(TEXT_PRIMARY)
            .enabled(!this.isAnimating)
            .onClick(() => { this.onSaveTap(); })

          Button('重新拍摄', { type: ButtonType.Capsule })
            .width('90%')
            .height(48)
            .backgroundColor(Color.Transparent)
            .fontColor($r('app.color.ink_mid'))
            .border({ width: 1, color: $r('app.color.divider') })
            .enabled(!this.isAnimating)
            .onClick(() => { this.retake(); })
        }
        .padding({ bottom: 32, top: 16 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.bg_base'))
    }
  }
}
