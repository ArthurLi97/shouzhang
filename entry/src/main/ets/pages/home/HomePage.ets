// pages/home/HomePage.ets
// MEMO 首页 — Collection 为主角，Canvas 为配角
// 弱化顶部 + 层叠Collection纸张 + Mini Canvas预览 + 底部Capture按钮

import { Collection } from '../../models/Collection';
import { CanvasSticker } from '../../models/CanvasSticker';
import { CollectionDetailParam } from '../../models/PageParams';
import { CollectionFolderSheet } from '../../components/canvas/CollectionFolderSheet';
import { RdbHelper } from '../../database/RdbHelper';
import { HdsSnackBar } from '../../components/hds/HdsSnackBar';
import { PermissionManager } from '../../utils/PermissionManager';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { cameraPicker } from '@kit.CameraKit';
import { camera } from '@kit.CameraKit';
import { common } from '@kit.AbilityKit';
import { UriParam } from '../../models/PageParams';
import {
  BG_BASE, PAPER, TEXT_PRIMARY, TEXT_SECONDARY, TEXT_TERTIARY,
  getFolderColor
} from '../../constants/ThemeConstants';

const OVERLAP_PX = 44;
const SHEET_HEIGHT = 64;

@Component
export struct HomePage {
  @Consume('rootPathStack') pathStack: NavPathStack;
  @State collections: Collection[] = [];
  @State collectionCounts: Map<number, number> = new Map();
  @State totalStickers: number = 0;
  @State canvasStickerCount: number = 0;
  @State showPickerSheet: boolean = false;

  private db: RdbHelper = RdbHelper.getInstance();

  aboutToAppear(): void {
    this.loadData();
    this.loadCanvasState();
  }

  onPageShow(): void {
    this.loadData();
    this.loadCanvasState();
  }

  async loadData(): Promise<void> {
    try {
      this.collections = await this.db.getCollections();
      const newCounts = new Map<number, number>();
      let total = 0;
      for (const col of this.collections) {
        const count = await this.db.getStickerCountByCollection(col.id);
        newCounts.set(col.id, count);
        total += count;
      }
      this.collectionCounts = newCounts;
      this.totalStickers = total;
    } catch (err) {
      console.error('HomePage loadData error:', JSON.stringify(err));
    }
  }

  loadCanvasState(): void {
    const stickers = AppStorage.get<CanvasSticker[]>('home_canvas_stickers');
    this.canvasStickerCount = stickers ? stickers.length : 0;
  }

  getCurrentDate(): string {
    const now = new Date();
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    return `${months[now.getMonth()]} ${now.getDate()}`;
  }

  onCollectionTap(col: Collection, color: string): void {
    const param: CollectionDetailParam = {
      collectionId: col.id,
      collectionName: col.name,
      collectionColor: color
    };
    this.pathStack.pushPathByName('CollectionDetailPage', param);
  }

  onCanvasTap(): void {
    const param: Record<string, string> = {};
    this.pathStack.pushPathByName('CanvasEditPage', param);
  }

  // ========== 顶部栏 ==========
  @Builder
  TopBar(): void {
    Column({ space: 2 }) {
      Text(this.getCurrentDate())
        .fontSize(14)
        .fontColor(TEXT_SECONDARY)

      Text('My Collection')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_PRIMARY)
    }
    .width('100%')
    .height(64)
    .padding({ left: 20, right: 20, top: 8 })
    .alignItems(HorizontalAlign.Start)
  }

  // ========== Collection 层叠区 ==========
  @Builder
  CollectionStack(): void {
    Column({ space: 0 }) {
      // 层叠容器
      Stack({ alignContent: Alignment.TopStart }) {
        ForEach(this.collections, (col: Collection, index: number) => {
          // 单张 Collection 卡片
          Stack({ alignContent: Alignment.TopStart }) {
            CollectionFolderSheet({
              name: col.name,
              color: getFolderColor(index),
              count: this.collectionCounts.get(col.id) ?? 0,
              onTap: () => this.onCollectionTap(col, getFolderColor(index))
            })
          }
          .width('100%')
          .height(SHEET_HEIGHT)
          .offset({ y: index * OVERLAP_PX })
          .zIndex(this.collections.length - index)
        }, (col: Collection) => col.id.toString())
      }
      .width('100%')
      .height(this.getStackHeight())

      // 空状态提示（全局无贴纸时）
      if (this.totalStickers === 0) {
        Text('Start collecting your first sticker')
          .fontSize(14)
          .fontColor(TEXT_TERTIARY)
          .margin({ top: 16, bottom: 8 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  private getStackHeight(): number {
    if (this.collections.length === 0) return 0;
    return (this.collections.length - 1) * OVERLAP_PX + SHEET_HEIGHT;
  }

  // ========== Mini Canvas 预览 ==========
  @Builder
  MiniCanvasPreview(): void {
    Column({ space: 8 }) {
      Text('Memo Canvas')
        .fontSize(14)
        .fontColor(TEXT_SECONDARY)
        .width('100%')
        .textAlign(TextAlign.Start)

      Stack({ alignContent: Alignment.Center }) {
        // 厚纸板画布
        Stack() {
          // 厚度层
          Stack()
            .width('100%')
            .height('100%')
            .backgroundColor('#E7E1DA')
            .borderRadius(4)
            .offset({ x: 0, y: 2 })

          // 环境 shadow
          Stack()
            .width('100%')
            .height('100%')
            .backgroundColor(PAPER)
            .borderRadius(4)
            .shadow({
              radius: 20,
              color: 'rgba(0,0,0,0.06)',
              offsetX: 0,
              offsetY: 6
            })

          // 核心 shadow
          Stack()
            .width('100%')
            .height('100%')
            .backgroundColor(PAPER)
            .borderRadius(4)
            .shadow({
              radius: 4,
              color: 'rgba(0,0,0,0.05)',
              offsetX: 0,
              offsetY: 2
            })

          // 主色层 + 纹理
          Stack() {
            Stack()
              .width('100%')
              .height('100%')
              .backgroundColor(PAPER)
              .borderRadius(4)

            // 45° 纹理
            Stack()
              .width('100%')
              .height('100%')
              .borderRadius(4)
              .linearGradient({
                angle: 45,
                colors: [
                  ['rgba(0,0,0,0.006)', 0], ['rgba(0,0,0,0)', 0.1],
                  ['rgba(0,0,0,0.006)', 0.2], ['rgba(0,0,0,0)', 0.3],
                  ['rgba(0,0,0,0.006)', 0.4], ['rgba(0,0,0,0)', 0.5],
                  ['rgba(0,0,0,0.006)', 0.6], ['rgba(0,0,0,0)', 0.7],
                  ['rgba(0,0,0,0.006)', 0.8], ['rgba(0,0,0,0)', 0.9],
                  ['rgba(0,0,0,0.006)', 1],
                ]
              })

            // 高光边
            Stack()
              .width('100%')
              .height('100%')
              .borderRadius(4)
              .border({
                width: { top: 0.5, left: 0.5, right: 0, bottom: 0 },
                color: 'rgba(255,255,255,0.35)',
                style: BorderStyle.Solid
              })

            // 内容
            if (this.canvasStickerCount > 0) {
              Text(`${this.canvasStickerCount} sticker${this.canvasStickerCount === 1 ? '' : 's'}`)
                .fontSize(14)
                .fontColor(TEXT_SECONDARY)
            } else {
              Column({ space: 6 }) {
                SymbolGlyph($r('sys.symbol.hand_draw'))
                  .fontSize(24)
                  .fontColor([TEXT_TERTIARY])

                Text('Tap to create your memo')
                  .fontSize(13)
                  .fontColor(TEXT_TERTIARY)
              }
            }
          }
          .width('100%')
          .height('100%')
        }
        .width('100%')
        .aspectRatio(4 / 3)
        .onClick(() => this.onCanvasTap())
      }
      .width('100%')
    }
    .width('100%')
  }

  // ========== Capture Button ==========
  @Builder
  CaptureButton(): void {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        // 厚度层
        Stack()
          .width(200)
          .height(56)
          .backgroundColor('#E5C5C7')
          .borderRadius(28)
          .offset({ x: 0, y: 2 })

        // 环境 shadow
        Stack()
          .width(200)
          .height(56)
          .backgroundColor($r('app.color.dust_pink'))
          .borderRadius(28)
          .shadow({
            radius: 16,
            color: 'rgba(0,0,0,0.1)',
            offsetX: 0,
            offsetY: 6
          })

        // 核心 shadow
        Stack()
          .width(200)
          .height(56)
          .backgroundColor($r('app.color.dust_pink'))
          .borderRadius(28)
          .shadow({
            radius: 6,
            color: 'rgba(0,0,0,0.08)',
            offsetX: 0,
            offsetY: 2
          })

        // 主色层
        Stack()
          .width(200)
          .height(56)
          .backgroundColor($r('app.color.dust_pink'))
          .borderRadius(28)

        // 高光边
        Stack()
          .width(200)
          .height(56)
          .borderRadius(28)
          .border({
            width: { top: 0.5, left: 0.5, right: 0, bottom: 0 },
            color: 'rgba(255,255,255,0.4)',
            style: BorderStyle.Solid
          })

        // 内容
        Row({ space: 8 }) {
          SymbolGlyph($r('sys.symbol.camera'))
            .fontSize(22)
            .fontColor([Color.White])

          Text('Capture')
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
      }
      .width(200)
      .height(56)
      .onClick(() => { this.showPickerSheet = true; })
    }
    .width('100%')
    .height(88)
    .position({ x: 0, y: undefined })
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(250,248,244,0.85)') // 轻微毛玻璃背景
    .backdropBlur(8)
  }

  // ========== 相机/相册选择 Sheet ==========
  @Builder
  PickerSheetBuilder(): void {
    Column({ space: 16 }) {
      Text('制作贴纸')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_PRIMARY)
        .margin({ top: 8 })

      Row({ space: 24 }) {
        Column({ space: 8 }) {
          Stack() {
            SymbolGlyph($r('sys.symbol.camera'))
              .fontSize(32)
              .fontColor([$r('app.color.dust_pink')])
          }
          .width(64)
          .height(64)
          .backgroundColor('#FAF0F1')
          .borderRadius(32)
          Text('拍照')
            .fontSize(14)
            .fontColor(TEXT_SECONDARY)
        }
        .onClick(() => this.onTakePhoto())

        Column({ space: 8 }) {
          Stack() {
            SymbolGlyph($r('sys.symbol.camera_fill'))
              .fontSize(32)
              .fontColor([$r('app.color.dust_pink')])
          }
          .width(64)
          .height(64)
          .backgroundColor('#FAF0F1')
          .borderRadius(32)
          Text('相册')
            .fontSize(14)
            .fontColor(TEXT_SECONDARY)
        }
        .onClick(() => this.onPickFromAlbum())
      }
      .margin({ top: 8, bottom: 16 })

      Button('取消', { type: ButtonType.Capsule })
        .width('80%')
        .height(44)
        .backgroundColor(Color.White)
        .fontColor(TEXT_SECONDARY)
        .border({ width: 1, color: $r('app.color.divider') })
        .onClick(() => this.showPickerSheet = false)
    }
    .width('100%')
    .padding(16)
  }

  async onPickFromAlbum(): Promise<void> {
    this.showPickerSheet = false;
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const hasPermission = await PermissionManager.requestPhotoReadPermission(context);
    if (!hasPermission) return;
    const picker = new photoAccessHelper.PhotoViewPicker();
    try {
      const result = await picker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1,
      });
      if (result.photoUris && result.photoUris.length > 0) {
        const uri = result.photoUris[0];
        AppStorage.setOrCreate('pending_photo_uri', uri);
        const param: UriParam = { uri };
        this.pathStack.pushPathByName('ProcessingPage', param);
      }
    } catch (err) {
      const code = (err as Error)?.message ?? '';
      if (!code.includes('cancel') && !code.includes('Cancel')) {
        console.error('PhotoViewPicker error:', JSON.stringify(err));
        HdsSnackBar.show({ message: '选择图片失败' });
      }
    }
  }

  async onTakePhoto(): Promise<void> {
    this.showPickerSheet = false;
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const hasPermission = await PermissionManager.requestCameraPermission(context);
    if (!hasPermission) return;
    try {
      const result = await cameraPicker.pick(context, [cameraPicker.PickerMediaType.PHOTO], {
        cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK,
      });
      if (result.resultCode === 0 && result.resultUri) {
        const uri = result.resultUri;
        AppStorage.setOrCreate('pending_photo_uri', uri);
        const param: UriParam = { uri };
        this.pathStack.pushPathByName('ProcessingPage', param);
      }
    } catch (err) {
      const code = (err as Error)?.message ?? '';
      if (!code.includes('cancel') && !code.includes('Cancel')) {
        console.error('cameraPicker error:', JSON.stringify(err));
        HdsSnackBar.show({ message: '拍照失败' });
      }
    }
  }

  // ========== Build ==========
  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column({ space: 0 }) {
        this.TopBar()

        Scroll() {
          Column({ space: 20 }) {
            this.CollectionStack()

            Divider()
              .strokeWidth(0.5)
              .color($r('app.color.divider'))
              .margin({ top: 8, bottom: 8 })

            this.MiniCanvasPreview()

            // 底部留白给 Capture Button
            Blank().height(100)
          }
          .width('100%')
          .padding(16)
        }
        .layoutWeight(1)
        .scrollable(ScrollDirection.Vertical)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(BG_BASE)

      // 底部 Capture Button
      this.CaptureButton()
    }
    .width('100%')
    .height('100%')
    .bindSheet(this.showPickerSheet, this.PickerSheetBuilder(), {
      height: 240,
      showClose: false,
      backgroundColor: 'rgba(255,255,255,0.95)',
    })
  }
}
