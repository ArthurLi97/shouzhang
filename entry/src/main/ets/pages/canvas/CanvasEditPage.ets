// pages/canvas/CanvasEditPage.ets
// MEMO Editor — 唯一主页面：Canvas + Collection Drawer

import { CanvasSticker } from '../../models/CanvasSticker';
import { Sticker } from '../../models/Sticker';
import { Collection } from '../../models/Collection';
import { CanvasElement } from '../../components/canvas/CanvasElement';
import { CollectionDrawer } from '../../components/canvas/CollectionDrawer';
import { RdbHelper } from '../../database/RdbHelper';
import { HdsSnackBar } from '../../components/hds/HdsSnackBar';
import { PermissionManager } from '../../utils/PermissionManager';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { cameraPicker } from '@kit.CameraKit';
import { camera } from '@kit.CameraKit';
import { common } from '@kit.AbilityKit';
import { UriParam } from '../../models/PageParams';
import { BG_BASE, PAPER, TEXT_PRIMARY, TEXT_SECONDARY } from '../../constants/ThemeConstants';

const STICKER_BASE_SIZE = 124; // 100 内容 + 12*2 白边

interface Position {
  x: number;
  y: number;
}

@Component
export struct CanvasEditPage {
  @Consume('rootPathStack') pathStack: NavPathStack;
  @State canvasStickers: CanvasSticker[] = [];
  @State selectedId: string | null = null;
  @State canvasWidth: number = 360;
  @State canvasHeight: number = 450;
  @State drawerExpanded: boolean = false;
  @State showPickerSheet: boolean = false;
  @State isExporting: boolean = false;
  @State isPageVisible: boolean = false;

  private undoStack: CanvasSticker[][] = [];
  private redoStack: CanvasSticker[][] = [];
  private idCounter: number = 0;
  private dragStartX: number = 0;
  private dragStartY: number = 0;
  private threeFingerStartX: number = 0;
  private stickerImageMap: Map<number, string> = new Map();

  @StorageLink('pending_photo_uri') @Watch('onPendingPhotoChanged') pendingPhotoUri: string = '';

  aboutToAppear(): void {
    this.checkPendingCanvasSticker();
  }

  onPageShow(): void {
    this.isPageVisible = true;
    this.checkPendingCanvasSticker();
  }

  onPageHide(): void {
    this.isPageVisible = false;
  }

  aboutToDisappear(): void {
    // 保存 canvas 状态到 AppStorage，供 HomePage 预览
    AppStorage.setOrCreate('home_canvas_stickers', this.canvasStickers);
    const entries: [number, string][] = [];
    this.stickerImageMap.forEach((value, key) => { entries.push([key, value]); });
    AppStorage.setOrCreate('home_canvas_image_map', JSON.stringify(entries));
  }

  private checkPendingCanvasSticker(): void {
    const pendingUri = AppStorage.get<string>('pending_canvas_sticker');
    if (pendingUri) {
      AppStorage.delete('pending_canvas_sticker');
      const stickerId = AppStorage.get<number>('pending_sticker_id') ?? 0;
      AppStorage.delete('pending_sticker_id');
      this.addCanvasSticker(stickerId, pendingUri);
      HdsSnackBar.show({ message: '贴纸已添加到画布' });
    }
  }

  onPendingPhotoChanged(): void {
    if (!this.isPageVisible) return;
    if (this.pendingPhotoUri) {
      const uri = this.pendingPhotoUri;
      this.pendingPhotoUri = '';
      const param: UriParam = { uri };
      this.pathStack.pushPathByName('ProcessingPage', param);
    }
  }

  get selectedSticker(): CanvasSticker | undefined {
    return this.canvasStickers.find(s => s.id === this.selectedId);
  }

  private cloneStickers(items: CanvasSticker[]): CanvasSticker[] {
    return items.map((src: CanvasSticker) => {
      const clone = new CanvasSticker(src.id, src.stickerId, src.x, src.y);
      clone.scale = src.scale;
      clone.rotation = src.rotation;
      clone.zIndex = src.zIndex;
      clone.width = src.width;
      clone.height = src.height;
      return clone;
    });
  }

  private nextId(): string {
    this.idCounter++;
    return `cs_${Date.now()}_${this.idCounter}`;
  }

  /** 贴纸自动落点 */
  private getAutoPosition(index: number, itemW: number, itemH: number): Position {
    const cx = this.canvasWidth / 2;
    const cy = this.canvasHeight / 2;
    const baseX = cx - itemW / 2;
    const baseY = cy - itemH / 2;

    if (index === 0) return { x: baseX, y: baseY };

    if (index >= 1 && index <= 4) {
      const radius = Math.min(this.canvasWidth, this.canvasHeight) * 0.22;
      const angle = (index - 1) * (Math.PI * 2 / 4) - Math.PI / 4;
      return {
        x: Math.max(0, Math.min(this.canvasWidth - itemW, baseX + Math.cos(angle) * radius)),
        y: Math.max(0, Math.min(this.canvasHeight - itemH, baseY + Math.sin(angle) * radius))
      };
    }

    const minR = 30;
    const maxR = Math.min(this.canvasWidth, this.canvasHeight) * 0.28;
    const r = minR + Math.random() * (maxR - minR);
    const theta = Math.random() * Math.PI * 2;
    return {
      x: Math.max(0, Math.min(this.canvasWidth - itemW, baseX + Math.cos(theta) * r)),
      y: Math.max(0, Math.min(this.canvasHeight - itemH, baseY + Math.sin(theta) * r))
    };
  }

  /** 限制不越界 */
  private clampPos(item: CanvasSticker, x: number, y: number): void {
    const sw = item.width * item.scale;
    const sh = item.height * item.scale;
    item.x = Math.max(0, Math.min(this.canvasWidth - sw, x));
    item.y = Math.max(0, Math.min(this.canvasHeight - sh, y));
  }

  addCanvasSticker(stickerId: number, imageUri: string): void {
    this.saveState();
    this.stickerImageMap.set(stickerId, imageUri);
    const pos = this.getAutoPosition(this.canvasStickers.length, STICKER_BASE_SIZE, STICKER_BASE_SIZE);
    const cs = new CanvasSticker(this.nextId(), stickerId, pos.x, pos.y);
    cs.width = STICKER_BASE_SIZE;
    cs.height = STICKER_BASE_SIZE;
    cs.zIndex = this.canvasStickers.length;
    this.canvasStickers.push(cs);
    this.selectedId = cs.id;
  }

  saveState(): void {
    this.undoStack.push(this.cloneStickers(this.canvasStickers));
    if (this.undoStack.length > 50) this.undoStack.shift();
    this.redoStack = [];
  }

  undo(): void {
    if (this.undoStack.length === 0) return;
    this.redoStack.push(this.cloneStickers(this.canvasStickers));
    this.canvasStickers = this.undoStack.pop()!;
    this.selectedId = null;
  }

  redo(): void {
    if (this.redoStack.length === 0) return;
    this.undoStack.push(this.cloneStickers(this.canvasStickers));
    this.canvasStickers = this.redoStack.pop()!;
    this.selectedId = null;
  }

  deleteSticker(id: string): void {
    this.saveState();
    const idx = this.canvasStickers.findIndex(s => s.id === id);
    if (idx >= 0) {
      this.canvasStickers.splice(idx, 1);
      this.canvasStickers = [...this.canvasStickers];
      this.rebuildZIndex();
    }
    if (this.selectedId === id) this.selectedId = null;
  }

  rebuildZIndex(): void {
    this.canvasStickers.forEach((s, i) => s.zIndex = i);
  }

  bringToFront(): void {
    if (!this.selectedId) return;
    const idx = this.canvasStickers.findIndex(s => s.id === this.selectedId);
    if (idx >= 0 && idx < this.canvasStickers.length - 1) {
      this.saveState();
      const item = this.canvasStickers.splice(idx, 1)[0];
      this.canvasStickers.push(item);
      this.rebuildZIndex();
    }
  }

  sendToBack(): void {
    if (!this.selectedId) return;
    const idx = this.canvasStickers.findIndex(s => s.id === this.selectedId);
    if (idx > 0) {
      this.saveState();
      const item = this.canvasStickers.splice(idx, 1)[0];
      this.canvasStickers.unshift(item);
      this.rebuildZIndex();
    }
  }

  async exportCanvas(): Promise<void> {
    if (this.canvasStickers.length === 0) {
      HdsSnackBar.show({ message: '画布为空' });
      return;
    }
    HdsSnackBar.show({ message: '导出功能开发中' });
  }

  @Builder
  TopBar(): void {
    Row() {
      SymbolGlyph($r('sys.symbol.chevron_left'))
        .fontSize(24)
        .fontColor([TEXT_PRIMARY])
        .onClick(() => { this.pathStack.pop(); })

      Text('Edit Memo')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Row({ space: 20 }) {
        SymbolGlyph($r('sys.symbol.arrow_counterclockwise'))
          .fontSize(20)
          .fontColor([this.undoStack.length > 0 ? TEXT_PRIMARY : $r('app.color.ink_light')])
          .onClick(() => this.undo())

        SymbolGlyph($r('sys.symbol.arrow_clockwise'))
          .fontSize(20)
          .fontColor([this.redoStack.length > 0 ? TEXT_PRIMARY : $r('app.color.ink_light')])
          .onClick(() => this.redo())
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  EmptyState(): void {
    Column({ space: 12 }) {
      SymbolGlyph($r('sys.symbol.camera'))
        .fontSize(48)
        .fontColor([$r('app.color.ink_light')])

      Text('Collect your first sticker')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_PRIMARY)

      Text('Tap + to capture something you love')
        .fontSize(15)
        .fontColor(TEXT_SECONDARY)

      Button('制作贴纸', { type: ButtonType.Capsule })
        .width(140)
        .height(40)
        .backgroundColor($r('app.color.dust_pink'))
        .fontColor(TEXT_PRIMARY)
        .margin({ top: 8 })
        .onClick(() => this.showPickerSheet = true)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  FloatingCameraButton(): void {
    // 厚纸板相机按钮 — 像贴在页面上的工具
    Stack({ alignContent: Alignment.Center }) {
      // 厚度层
      Stack()
        .width(52)
        .height(52)
        .backgroundColor('#E5C5C7')
        .borderRadius(26)
        .offset({ x: 1, y: 2 })

      // 不对称 shadow（模拟左上方光源）
      Stack()
        .width(52)
        .height(52)
        .backgroundColor($r('app.color.dust_pink'))
        .borderRadius(26)
        .shadow({ radius: 10, color: 'rgba(0,0,0,0.12)', offsetX: 3, offsetY: 5 })

      // 主色层
      Stack()
        .width(52)
        .height(52)
        .backgroundColor($r('app.color.dust_pink'))
        .borderRadius(26)

      // 顶部高光边
      Stack()
        .width(52)
        .height(52)
        .borderRadius(26)
        .border({
          width: { top: 0.5, left: 0.5, right: 0, bottom: 0 },
          color: 'rgba(255,255,255,0.4)',
          style: BorderStyle.Solid
        })

      // 图标
      SymbolGlyph($r('sys.symbol.camera'))
        .fontSize(24)
        .fontColor([Color.White])
    }
    .width(52)
    .height(52)
    .position({ x: this.canvasWidth - 68, y: 16 })
    .onClick(() => this.showPickerSheet = true)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        this.TopBar()

        Stack({ alignContent: Alignment.Bottom }) {
          Column() {
            Stack({ alignContent: Alignment.Center }) {
              // === Paper Craft 厚纸板画布 ===

              // 厚度层：略深色偏移，模拟纸张厚度
              Stack()
                .width('100%')
                .height('100%')
                .backgroundColor('#E7E1DA')
                .borderRadius(4)
                .offset({ x: 0, y: 3 })

              // 环境柔化 shadow
              Stack()
                .width('100%')
                .height('100%')
                .backgroundColor(PAPER)
                .borderRadius(4)
                .shadow({
                  radius: 40,
                  color: 'rgba(0,0,0,0.07)',
                  offsetX: 0,
                  offsetY: 12
                })

              // 核心贴底 shadow
              Stack()
                .width('100%')
                .height('100%')
                .backgroundColor(PAPER)
                .borderRadius(4)
                .shadow({
                  radius: 8,
                  color: 'rgba(0,0,0,0.05)',
                  offsetX: 0,
                  offsetY: 3
                })

              // 主色层：带纸张纹理
              Stack() {
                // 基色
                Stack()
                  .width('100%')
                  .height('100%')
                  .backgroundColor(PAPER)
                  .borderRadius(4)

                // 纹理层 1：45° 细微纤维
                Stack()
                  .width('100%')
                  .height('100%')
                  .borderRadius(4)
                  .linearGradient({
                    angle: 45,
                    colors: [
                      ['rgba(0,0,0,0.006)', 0], ['rgba(0,0,0,0)', 0.05],
                      ['rgba(0,0,0,0.006)', 0.1], ['rgba(0,0,0,0)', 0.15],
                      ['rgba(0,0,0,0.006)', 0.2], ['rgba(0,0,0,0)', 0.25],
                      ['rgba(0,0,0,0.006)', 0.3], ['rgba(0,0,0,0)', 0.35],
                      ['rgba(0,0,0,0.006)', 0.4], ['rgba(0,0,0,0)', 0.45],
                      ['rgba(0,0,0,0.006)', 0.5], ['rgba(0,0,0,0)', 0.55],
                      ['rgba(0,0,0,0.006)', 0.6], ['rgba(0,0,0,0)', 0.65],
                      ['rgba(0,0,0,0.006)', 0.7], ['rgba(0,0,0,0)', 0.75],
                      ['rgba(0,0,0,0.006)', 0.8], ['rgba(0,0,0,0)', 0.85],
                      ['rgba(0,0,0,0.006)', 0.9], ['rgba(0,0,0,0)', 0.95],
                      ['rgba(0,0,0,0.006)', 1],
                    ]
                  })

                // 纹理层 2：135° 交叉纤维
                Stack()
                  .width('100%')
                  .height('100%')
                  .borderRadius(4)
                  .linearGradient({
                    angle: 135,
                    colors: [
                      ['rgba(0,0,0,0.004)', 0], ['rgba(0,0,0,0)', 0.1],
                      ['rgba(0,0,0,0.004)', 0.2], ['rgba(0,0,0,0)', 0.3],
                      ['rgba(0,0,0,0.004)', 0.4], ['rgba(0,0,0,0)', 0.5],
                      ['rgba(0,0,0,0.004)', 0.6], ['rgba(0,0,0,0)', 0.7],
                      ['rgba(0,0,0,0.004)', 0.8], ['rgba(0,0,0,0)', 0.9],
                      ['rgba(0,0,0,0.004)', 1],
                    ]
                  })

                // 顶部高光边
                Stack()
                  .width('100%')
                  .height('100%')
                  .borderRadius(4)
                  .border({
                    width: { top: 0.5, left: 0.5, right: 0, bottom: 0 },
                    color: 'rgba(255,255,255,0.4)',
                    style: BorderStyle.Solid
                  })
              }
              .width('100%')
              .height('100%')

              // 元素层
              Stack() {
                ForEach(this.canvasStickers, (cs: CanvasSticker) => {
                  CanvasElement({
                    itemId: cs.id,
                    uri: this.stickerImageMap.get(cs.stickerId) ?? '',
                    isSelected: this.selectedId === cs.id,
                    onDelete: (id: string) => this.deleteSticker(id)
                  })
                    .position({ x: cs.x, y: cs.y })
                    .scale({ x: cs.scale, y: cs.scale, centerX: '50%', centerY: '50%' })
                    .rotate({ angle: cs.rotation, centerX: '50%', centerY: '50%' })
                    .zIndex(cs.zIndex)
                    .gesture(
                      GestureGroup(GestureMode.Exclusive,
                        TapGesture({ count: 1 })
                          .onAction(() => { this.selectedId = cs.id; }),
                        LongPressGesture({ duration: 500 })
                          .onAction(() => {
                            this.selectedId = cs.id;
                            this.bringToFront();
                          }),
                        PanGesture({ fingers: 1, direction: PanDirection.All, distance: 5 })
                          .onActionStart(() => {
                            this.selectedId = cs.id;
                            this.dragStartX = cs.x;
                            this.dragStartY = cs.y;
                          })
                          .onActionUpdate((e: GestureEvent) => {
                            this.clampPos(cs, this.dragStartX + e.offsetX, this.dragStartY + e.offsetY);
                          })
                          .onActionEnd(() => {})
                      )
                    )
                }, (cs: CanvasSticker) => cs.id)
              }
              .width('100%')
              .height('100%')
              .gesture(
                GestureGroup(GestureMode.Parallel,
                  TapGesture({ count: 1 })
                    .onAction(() => { this.selectedId = null; }),
                  PinchGesture({ fingers: 2 })
                    .onActionUpdate((e: GestureEvent) => {
                      const s = this.selectedSticker;
                      if (s) s.scale = Math.max(0.25, Math.min(4.0, s.scale * e.scale));
                    }),
                  RotationGesture({ fingers: 2 })
                    .onActionUpdate((e: GestureEvent) => {
                      const s = this.selectedSticker;
                      if (s) s.rotation += e.angle;
                    })
                    .onActionEnd(() => {
                      const s = this.selectedSticker;
                      if (s) s.rotation = Math.round(s.rotation / 15) * 15;
                    }),
                  PanGesture({ fingers: 3, direction: PanDirection.Horizontal })
                    .onActionStart((e: GestureEvent) => { this.threeFingerStartX = e.offsetX; })
                    .onActionEnd((e: GestureEvent) => {
                      const dx = e.offsetX - this.threeFingerStartX;
                      if (dx < -40) this.undo();
                      else if (dx > 40) this.redo();
                    })
                )
              )

              // 空状态
              if (this.canvasStickers.length === 0) {
                this.EmptyState()
              }

              // 悬浮拍照按钮
              this.FloatingCameraButton()
            }
            .width('100%')
            .aspectRatio(4 / 5)
            .margin(8)
            .onAreaChange((oldValue: Area, newValue: Area) => {
              const w = newValue.width;
              const h = newValue.height;
              this.canvasWidth = (typeof w === 'number') ? w : (parseFloat(w as string) || 360);
              this.canvasHeight = (typeof h === 'number') ? h : (parseFloat(h as string) || 450);
            })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(BG_BASE)

      CollectionDrawer({
        onSelectSticker: (sticker) => {
          this.addCanvasSticker(sticker.id ?? 0, sticker.image);
        },
        expanded: this.drawerExpanded,
        onExpandChange: (expanded) => { this.drawerExpanded = expanded; }
      })
    }
    .width('100%')
    .height('100%')
    .bindSheet(this.showPickerSheet, this.PickerSheetBuilder(), {
      height: 240,
      showClose: false,
      backgroundColor: 'rgba(255,255,255,0.95)',
    })
  }

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
        AppStorage.setOrCreate('pending_photo_uri', result.photoUris[0]);
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
        AppStorage.setOrCreate('pending_photo_uri', result.resultUri);
      }
    } catch (err) {
      const code = (err as Error)?.message ?? '';
      if (!code.includes('cancel') && !code.includes('Cancel')) {
        console.error('cameraPicker error:', JSON.stringify(err));
        HdsSnackBar.show({ message: '拍照失败' });
      }
    }
  }
}
