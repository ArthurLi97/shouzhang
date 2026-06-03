// pages/home/HomePage.ets
// MEMO 首页 — Capture → Collect → Compose
// 顶部固定 Header + 滚动内容区 + LatestMemo 三种状态

import { Collection } from '../../models/Collection';
import { CanvasSticker } from '../../models/CanvasSticker';
import { CanvasProject } from '../../models/CanvasProject';
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
const MEMO_PREVIEW_HEIGHT = 240;
const PREVIEW_STICKER_SIZE = 48;
const PREVIEW_STICKER_BORDER = 6;

interface PreviewStickerPos {
  x: string;
  y: string;
  rotation: number;
}

interface PreviewStickerItem {
  uri: string;
  pos: PreviewStickerPos;
}

const PREVIEW_POSITIONS: PreviewStickerPos[] = [
  { x: '12%', y: '12%', rotation: -8 },
  { x: '52%', y: '8%', rotation: 5 },
  { x: '30%', y: '42%', rotation: -3 },
  { x: '68%', y: '38%', rotation: 10 },
  { x: '10%', y: '68%', rotation: -6 },
  { x: '58%', y: '65%', rotation: 4 },
];

@Component
export struct HomePage {
  @Consume('rootPathStack') pathStack: NavPathStack;
  @State collections: Collection[] = [];
  @State collectionCounts: Map<number, number> = new Map();
  @State totalStickers: number = 0;
  @State previewStickers: PreviewStickerItem[] = [];
  @State hasDraft: boolean = false;
  @State latestProject: CanvasProject | null = null;
  @State showPickerSheet: boolean = false;

  private db: RdbHelper = RdbHelper.getInstance();

  aboutToAppear(): void {
    this.loadData();
    this.loadDraftState();
    this.loadLatestProject();
  }

  onPageShow(): void {
    this.loadData();
    this.loadDraftState();
    this.loadLatestProject();
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

  loadDraftState(): void {
    const canvasStickers = AppStorage.get<CanvasSticker[]>('home_canvas_stickers');
    this.hasDraft = canvasStickers !== undefined && canvasStickers.length > 0;
    if (this.hasDraft) {
      this.loadPreviewStickers();
    } else {
      this.previewStickers = [];
    }
  }

  loadPreviewStickers(): void {
    const canvasStickers = AppStorage.get<CanvasSticker[]>('home_canvas_stickers');
    const mapStr = AppStorage.get<string>('home_canvas_image_map');
    if (!canvasStickers || canvasStickers.length === 0 || !mapStr) {
      this.previewStickers = [];
      return;
    }

    let imageMap: Map<number, string>;
    try {
      const entries = JSON.parse(mapStr) as [number, string][];
      imageMap = new Map<number, string>(entries);
    } catch {
      this.previewStickers = [];
      return;
    }

    const preview: PreviewStickerItem[] = [];
    const count = Math.min(canvasStickers.length, PREVIEW_POSITIONS.length);
    for (let i = 0; i < count; i++) {
      const cs = canvasStickers[i];
      const uri = imageMap.get(cs.stickerId);
      if (uri) {
        const item: PreviewStickerItem = { uri, pos: PREVIEW_POSITIONS[i] };
        preview.push(item);
      }
    }
    this.previewStickers = preview;
  }

  async loadLatestProject(): Promise<void> {
    try {
      this.latestProject = await this.db.getLatestCanvasProject();
    } catch (err) {
      console.error('loadLatestProject error:', JSON.stringify(err));
      this.latestProject = null;
    }
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

  onJournalTap(): void {
    const pid = this.latestProject?.id;
    if (pid === undefined || pid === null) return;
    interface JournalNavParam {
      id: number;
    }
    const param: JournalNavParam = { id: pid };
    this.pathStack.pushPathByName('JournalDetailPage', param);
  }

  onSeeAllJournals(): void {
    const param: Record<string, string> = {};
    this.pathStack.pushPathByName('JournalPage', param);
  }

  // ========== Header + Capture (固定顶部) ==========
  @Builder
  HeaderWithCapture(): void {
    Column({ space: 12 }) {
      // 极弱顶部标题
      Text(this.getCurrentDate())
        .fontSize(14)
        .fontColor(TEXT_SECONDARY)
        .width('100%')
        .textAlign(TextAlign.Start)

      // Capture 大印章按钮
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
    .padding({ left: 16, right: 16, top: 28, bottom: 8 })
    .alignItems(HorizontalAlign.Start)
  }

  // ========== My Collections ==========
  @Builder
  CollectionStack(): void {
    Column({ space: 0 }) {
      Text('My Collections')
        .fontSize(14)
        .fontColor(TEXT_SECONDARY)
        .width('100%')
        .textAlign(TextAlign.Start)
        .margin({ bottom: 12 })

      // 层叠容器
      Stack({ alignContent: Alignment.TopStart }) {
        ForEach(this.collections, (col: Collection, index: number) => {
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
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  private getStackHeight(): number {
    if (this.collections.length === 0) return 0;
    return (this.collections.length - 1) * OVERLAP_PX + SHEET_HEIGHT;
  }

  // ========== Latest Memo Preview（三种状态）==========
  @Builder
  LatestMemoPreview(): void {
    Column({ space: 8 }) {
      // 标题行
      this.MemoTitleRow()

      Stack({ alignContent: Alignment.Center }) {
        // 厚纸板手账纸
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
              radius: 16,
              color: 'rgba(0,0,0,0.06)',
              offsetX: 0,
              offsetY: 5
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

          // 主色层 + 纹理 + 高光边
          Stack() {
            Stack()
              .width('100%')
              .height('100%')
              .backgroundColor(PAPER)
              .borderRadius(4)

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

            Stack()
              .width('100%')
              .height('100%')
              .borderRadius(4)
              .border({
                width: { top: 0.5, left: 0.5, right: 0, bottom: 0 },
                color: 'rgba(255,255,255,0.35)',
                style: BorderStyle.Solid
              })

            // === 状态 A：Continue Draft ===
            if (this.hasDraft) {
              ForEach(this.previewStickers, (item: PreviewStickerItem, index: number) => {
                Stack({ alignContent: Alignment.Center }) {
                  Image(item.uri)
                    .width(PREVIEW_STICKER_SIZE)
                    .height(PREVIEW_STICKER_SIZE)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(8)
                }
                .padding(PREVIEW_STICKER_BORDER)
                .backgroundColor(Color.White)
                .borderRadius(14)
                .shadow({
                  radius: 8,
                  color: 'rgba(0,0,0,0.08)',
                  offsetX: 0,
                  offsetY: 3
                })
                .position({ x: item.pos.x, y: item.pos.y })
                .rotate({ angle: item.pos.rotation })
              }, (item: PreviewStickerItem, index: number) => index.toString())
            }
            // === 状态 B：Latest Memo（缩略图）===
            else if (this.latestProject) {
              if (this.latestProject.thumbnailUri) {
                Image(this.latestProject.thumbnailUri)
                  .width('85%')
                  .height('85%')
                  .objectFit(ImageFit.Cover)
                  .borderRadius(8)
              } else {
                Column({ space: 6 }) {
                  SymbolGlyph($r('sys.symbol.camera'))
                    .fontSize(28)
                    .fontColor([TEXT_TERTIARY])
                  Text(this.latestProject.title)
                    .fontSize(14)
                    .fontColor(TEXT_SECONDARY)
                }
              }
            }
            // === 状态 C：引导空态 ===
            else {
              Column({ space: 10 }) {
                SymbolGlyph($r('sys.symbol.star'))
                  .fontSize(32)
                  .fontColor([$r('app.color.dust_pink')])

                Text('Your first memo')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(TEXT_PRIMARY)

                Text('Add stickers from a collection above, or tap Capture to start')
                  .fontSize(13)
                  .fontColor(TEXT_SECONDARY)
                  .textAlign(TextAlign.Center)
                  .padding({ left: 24, right: 24 })
              }
            }
          }
          .width('100%')
          .height('100%')
        }
        .width('100%')
        .height(MEMO_PREVIEW_HEIGHT)
        .onClick(() => {
          if (this.latestProject && !this.hasDraft) {
            this.onJournalTap();
          } else {
            this.onCanvasTap();
          }
        })
      }
      .width('100%')

      // 底部提示
      Text(this.getMemoHint())
        .fontSize(12)
        .fontColor(TEXT_TERTIARY)
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
  }

  @Builder
  MemoTitleRow(): void {
    Row() {
      if (this.hasDraft) {
        Text('Continue')
          .fontSize(14)
          .fontColor(TEXT_SECONDARY)
      } else {
        Text('Latest Memo')
          .fontSize(14)
          .fontColor(TEXT_SECONDARY)
      }

      Blank().layoutWeight(1)

      // "See all" 只在有作品且无草稿时显示
      if (!this.hasDraft && this.latestProject) {
        Text('See all')
          .fontSize(13)
          .fontColor($r('app.color.dust_pink'))
          .onClick(() => this.onSeeAllJournals())
      }
    }
    .width('100%')
    .height(20)
  }

  private getMemoHint(): string {
    if (this.hasDraft) return 'Tap to continue editing';
    if (this.latestProject) return 'Tap to view';
    return 'Tap to start';
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
    Column({ space: 0 }) {
      // 固定顶部：Header + Capture（始终可见）
      this.HeaderWithCapture()

      // 可滚动内容区
      Scroll() {
        Column({ space: 20 }) {
          this.CollectionStack()

          Divider()
            .strokeWidth(0.5)
            .color($r('app.color.divider'))

          this.LatestMemoPreview()

          // 底部留白
          Blank().height(32)
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
    .bindSheet(this.showPickerSheet, this.PickerSheetBuilder(), {
      height: 240,
      showClose: false,
      backgroundColor: 'rgba(255,255,255,0.95)',
    })
  }
}
