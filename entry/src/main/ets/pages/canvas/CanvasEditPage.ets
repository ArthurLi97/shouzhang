// pages/canvas/CanvasEditPage.ets
// 画布编辑器 - 支持单指拖拽、双指缩放旋转、删除区域、自适应画布

import { CanvasItem } from '../../models/CanvasItem';
import { BackgroundConfig } from '../../models/BackgroundConfig';
import { Sticker } from '../../models/Sticker';
import { CanvasBackground } from '../../components/canvas/CanvasBackground';
import { CanvasElement } from '../../components/canvas/CanvasElement';
import { CanvasToolPanel } from '../../components/canvas/CanvasToolPanel';
import { StickerPickerSheet } from '../../components/canvas/StickerPickerSheet';
import { TextToolSheet } from '../../components/canvas/TextToolSheet';
import { BackgroundToolSheet } from '../../components/canvas/BackgroundToolSheet';
import { StickerEditSheet } from '../../components/canvas/StickerEditSheet';
import { ExportParam } from '../../models/PageParams';
import { CanvasExporter } from '../../utils/CanvasExporter';
import { HdsSnackBar } from '../../components/hds/HdsSnackBar';
import { common } from '@kit.AbilityKit';

interface Position {
  x: number;
  y: number;
}

@Component
export struct CanvasEditPage {
  @Consume('canvasPathStack') pathStack: NavPathStack;
  @State canvasItems: CanvasItem[] = [];
  @State selectedItemId: string | null = null;
  @State activeTool: string = '';
  @State backgroundConfig: BackgroundConfig = { type: 'color', value: '#FFF8F0' };
  @State showEditSheet: boolean = false;

  // 画布实际尺寸（通过 onAreaChange 获取）
  @State canvasWidth: number = 360;
  @State canvasHeight: number = 450;

  // 背景切换标记（强制 CanvasBackground 交替重建以确保重绘）
  @State bgToggle: boolean = false;

  // 删除区域状态
  @State showDeleteZone: boolean = false;
  @State isOverDeleteZone: boolean = false;

  // 拖拽状态
  @State dragItemId: string = '';
  private dragStartX: number = 0;
  private dragStartY: number = 0;

  private undoStack: CanvasItem[][] = [];
  private redoStack: CanvasItem[][] = [];
  private idCounter: number = 0;

  aboutToAppear(): void {
    const pendingUri = AppStorage.get<string>('pending_canvas_sticker');
    if (pendingUri) {
      AppStorage.delete('pending_canvas_sticker');
      const sticker: Sticker = {
        id: 0,
        uri: pendingUri,
        category: '其他',
        createdAt: Date.now(),
        updatedAt: Date.now(),
      };
      this.addSticker(sticker);
    }
  }

  get selectedItem(): CanvasItem | undefined {
    return this.canvasItems.find(i => i.id === this.selectedItemId);
  }

  private cloneItems(items: CanvasItem[]): CanvasItem[] {
    return items.map((src: CanvasItem) => {
      const clone = new CanvasItem(src.id, src.type, src.x, src.y);
      clone.uri = src.uri;
      clone.content = src.content;
      clone.scale = src.scale;
      clone.rotation = src.rotation;
      clone.zIndex = src.zIndex;
      clone.width = src.width;
      clone.height = src.height;
      clone.borderWidth = src.borderWidth;
      clone.borderColor = src.borderColor;
      clone.shadowEnabled = src.shadowEnabled;
      clone.shadowColor = src.shadowColor;
      clone.fontColor = src.fontColor;
      clone.fontSize = src.fontSize;
      return clone;
    });
  }

  private nextId(): string {
    this.idCounter++;
    return `item_${Date.now()}_${this.idCounter}`;
  }

  /** 获取画布中心位置（带轻微防重叠偏移） */
  private getCenterPosition(itemW: number, itemH: number): Position {
    const baseX = Math.max(0, (this.canvasWidth - itemW) / 2);
    const baseY = Math.max(0, (this.canvasHeight - itemH) / 2);
    const offsetX = this.canvasItems.length > 0 ? (Math.random() - 0.5) * 40 : 0;
    const offsetY = this.canvasItems.length > 0 ? (Math.random() - 0.5) * 40 : 0;
    return {
      x: Math.max(0, Math.min(this.canvasWidth - itemW, baseX + offsetX)),
      y: Math.max(0, Math.min(this.canvasHeight - itemH, baseY + offsetY))
    };
  }

  /** 限制元素位置（允许一半移出画布） */
  private clampPosition(item: CanvasItem, x: number, y: number): void {
    const halfW = (item.width * item.scale) / 2;
    const halfH = (item.height * item.scale) / 2;
    item.x = Math.max(-halfW, Math.min(this.canvasWidth - halfW, x));
    item.y = Math.max(-halfH, Math.min(this.canvasHeight - halfH, y));
  }

  /** 检测是否进入删除区域 */
  private checkDeleteZone(item: CanvasItem): void {
    const itemBottom = item.y + item.height * item.scale;
    const deleteZoneTop = this.canvasHeight - 60;
    this.isOverDeleteZone = itemBottom > deleteZoneTop;
  }

  addSticker(sticker: Sticker): void {
    this.saveState();
    const pos = this.getCenterPosition(100, 100);
    const item = new CanvasItem(this.nextId(), 'sticker', pos.x, pos.y);
    item.uri = sticker.uri;
    item.zIndex = this.canvasItems.length;
    this.canvasItems.push(item);
    this.selectedItemId = item.id;
    this.activeTool = '';
  }

  addText(text: string, color: string = '#1A1A1A', size: number = 24): void {
    this.saveState();
    const pos = this.getCenterPosition(160, 60);
    const item = new CanvasItem(this.nextId(), 'text', pos.x, pos.y);
    item.content = text;
    item.width = 160;
    item.height = 60;
    item.fontColor = color;
    item.fontSize = size;
    item.zIndex = this.canvasItems.length;
    this.canvasItems.push(item);
    this.selectedItemId = item.id;
    this.activeTool = '';
  }

  changeBackground(config: BackgroundConfig): void {
    this.backgroundConfig = config;
    this.bgToggle = !this.bgToggle;
  }

  saveState(): void {
    this.undoStack.push(this.cloneItems(this.canvasItems));
    if (this.undoStack.length > 20) {
      this.undoStack.shift();
    }
    this.redoStack = [];
  }

  undo(): void {
    if (this.undoStack.length === 0) return;
    this.redoStack.push(this.cloneItems(this.canvasItems));
    this.canvasItems = this.undoStack.pop()!;
    this.selectedItemId = null;
  }

  redo(): void {
    if (this.redoStack.length === 0) return;
    this.undoStack.push(this.cloneItems(this.canvasItems));
    this.canvasItems = this.redoStack.pop()!;
    this.selectedItemId = null;
  }

  async finish(): Promise<void> {
    if (this.canvasItems.length === 0) {
      HdsSnackBar.show({ message: '画布为空，请先添加贴纸或文字' });
      return;
    }
    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      const uri = await CanvasExporter.exportToFile(
        this.canvasItems,
        this.backgroundConfig,
        context
      );
      if (!uri) {
        HdsSnackBar.show({ message: '导出失败' });
        return;
      }
      const params: ExportParam = {
        items: uri,
        background: JSON.stringify(this.backgroundConfig)
      };
      this.pathStack.pushPathByName('ExportPage', params);
    } catch (err) {
      console.error('finish error:', JSON.stringify(err));
      HdsSnackBar.show({ message: '导出失败' });
    }
  }

  onEditItem(itemId: string): void {
    this.selectedItemId = itemId;
    this.showEditSheet = true;
  }

  onResetEdit(): void {
    const item = this.canvasItems.find(i => i.id === this.selectedItemId);
    if (item) {
      item.borderWidth = 0;
      item.borderColor = '#FFFFFF';
      item.shadowEnabled = true;
      item.shadowColor = 'rgba(0,0,0,0.15)';
      item.scale = 1;
      item.rotation = 0;
      item.fontColor = '#1A1A1A';
      item.fontSize = 24;
    }
  }

  deleteItem(itemId: string): void {
    this.saveState();
    const index = this.canvasItems.findIndex(i => i.id === itemId);
    if (index >= 0) {
      this.canvasItems.splice(index, 1);
      this.canvasItems = [...this.canvasItems];
      this.rebuildZIndex();
    }
    if (this.selectedItemId === itemId) {
      this.selectedItemId = null;
    }
  }

  rebuildZIndex(): void {
    this.canvasItems.forEach((item: CanvasItem, idx: number) => {
      item.zIndex = idx;
    });
  }

  /** 将选中元素置顶 */
  bringToFront(): void {
    if (!this.selectedItemId) return;
    const index = this.canvasItems.findIndex(i => i.id === this.selectedItemId);
    if (index >= 0 && index < this.canvasItems.length - 1) {
      this.saveState();
      const item = this.canvasItems.splice(index, 1)[0];
      this.canvasItems.push(item);
      this.rebuildZIndex();
    }
  }

  /** 将选中元素置底 */
  sendToBack(): void {
    if (!this.selectedItemId) return;
    const index = this.canvasItems.findIndex(i => i.id === this.selectedItemId);
    if (index > 0) {
      this.saveState();
      const item = this.canvasItems.splice(index, 1)[0];
      this.canvasItems.unshift(item);
      this.rebuildZIndex();
    }
  }

  @Builder
  DeleteZone(): void {
    Column() {
      SymbolGlyph($r('sys.symbol.trash'))
        .fontSize(24)
        .fontColor([this.isOverDeleteZone ? Color.White : '#FF3B30'])
      Text('拖拽到此处删除')
        .fontSize(12)
        .fontColor(this.isOverDeleteZone ? Color.White : '#FF3B30')
        .margin({ top: 4 })
    }
    .width('100%')
    .height(60)
    .backgroundColor(this.isOverDeleteZone ? '#FF3B30' : 'rgba(255,255,255,0.92)')
    .justifyContent(FlexAlign.Center)
    .animation({ duration: 200 })
  }

  @Builder
  TopBar(): void {
    Row() {
      SymbolGlyph($r('sys.symbol.chevron_left'))
        .fontSize(22)
        .fontColor([$r('app.color.ink_deep')])
        .onClick(() => {
          AppStorage.setOrCreate('editor_exit', true);
        })

      Blank().layoutWeight(1)

      Row({ space: 16 }) {
        SymbolGlyph($r('sys.symbol.arrow_counterclockwise'))
          .fontSize(20)
          .fontColor([$r('app.color.ink_mid')])
          .onClick(() => { this.undo(); })

        SymbolGlyph($r('sys.symbol.arrow_clockwise'))
          .fontSize(20)
          .fontColor([$r('app.color.ink_mid')])
          .onClick(() => { this.redo(); })
      }

      Blank().layoutWeight(1)

      Text('导出')
        .fontSize(15)
        .fontColor($r('app.color.brand_primary'))
        .fontWeight(FontWeight.Medium)
        .onClick(() => { this.finish(); })
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
  }

  build() {
    Column() {
      // 顶部操作栏
      this.TopBar()

      // 中间画布区域
      Stack({ alignContent: Alignment.Bottom }) {
        // 画布内容（居中）
        Column() {
          Stack() {
            // 背景层：颜色走声明式实时更新，纹理/图案/图片走 Canvas 2D
            if (this.backgroundConfig.type === 'color') {
              Stack()
                .width('100%')
                .height('100%')
                .backgroundColor(this.backgroundConfig.value)
            } else if (this.bgToggle) {
              CanvasBackground({ config: this.backgroundConfig, instanceId: 1 })
                .width('100%')
                .height('100%')
            } else {
              CanvasBackground({ config: this.backgroundConfig, instanceId: 2 })
                .width('100%')
                .height('100%')
            }

            // 元素层
            Stack() {
              ForEach(this.canvasItems, (item: CanvasItem) => {
                CanvasElement({
                  item: item,
                  isSelected: this.selectedItemId === item.id,
                  isDragging: this.dragItemId === item.id,
                  isOverDelete: this.isOverDeleteZone && this.dragItemId === item.id
                })
                  .position({ x: item.x, y: item.y })
                  .scale({
                    x: item.scale,
                    y: item.scale,
                    centerX: '50%',
                    centerY: '50%'
                  })
                  .rotate({
                    angle: item.rotation,
                    centerX: '50%',
                    centerY: '50%'
                  })
                  .zIndex(item.zIndex)
                  // 元素级手势：点击/双击/长按选中、单指拖拽
                  .gesture(
                    GestureGroup(GestureMode.Exclusive,
                      TapGesture({ count: 1 })
                        .onAction(() => { this.selectedItemId = item.id; }),
                      TapGesture({ count: 2 })
                        .onAction(() => { this.onEditItem(item.id); }),
                      LongPressGesture({ duration: 500 })
                        .onAction(() => { this.onEditItem(item.id); }),
                      PanGesture({ fingers: 1, direction: PanDirection.All, distance: 5 })
                        .onActionStart(() => {
                          this.selectedItemId = item.id;
                          this.dragItemId = item.id;
                          this.dragStartX = item.x;
                          this.dragStartY = item.y;
                          this.showDeleteZone = true;
                        })
                        .onActionUpdate((e: GestureEvent) => {
                          const newX = this.dragStartX + e.offsetX;
                          const newY = this.dragStartY + e.offsetY;
                          this.clampPosition(item, newX, newY);
                          this.checkDeleteZone(item);
                        })
                        .onActionEnd(() => {
                          if (this.isOverDeleteZone) {
                            this.deleteItem(item.id);
                          }
                          this.dragItemId = '';
                          this.showDeleteZone = false;
                          this.isOverDeleteZone = false;
                        })
                    )
                  )
              }, (item: CanvasItem) => item.id)
            }
            .width('100%')
            .height('100%')
            // 空白区域点击取消选中 + 画布级双指手势
            .gesture(
              GestureGroup(GestureMode.Parallel,
                TapGesture({ count: 1 })
                  .onAction(() => {
                    this.selectedItemId = null;
                    this.showEditSheet = false;
                    this.activeTool = '';
                  }),
                GestureGroup(GestureMode.Parallel,
                  PinchGesture({ fingers: 2 })
                    .onActionUpdate((e: GestureEvent) => {
                      const selected = this.selectedItem;
                      if (selected) {
                        selected.scale = Math.max(0.3, Math.min(5.0, selected.scale * e.scale));
                      }
                    }),
                  RotationGesture({ fingers: 2 })
                    .onActionUpdate((e: GestureEvent) => {
                      const selected = this.selectedItem;
                      if (selected) {
                        selected.rotation += e.angle;
                      }
                    })
                )
              )
            )
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

        // 删除区域（拖拽时显示）
        if (this.showDeleteZone) {
          this.DeleteZone()
        }

        // 浮动工具面板
        if (this.activeTool === 'sticker') {
          StickerPickerSheet({
            onSelectSticker: (sticker) => { this.addSticker(sticker); }
          })
        } else if (this.activeTool === 'text') {
          TextToolSheet({
            onAddText: (text, color, size) => { this.addText(text, color, size); }
          })
        } else if (this.activeTool === 'bg') {
          BackgroundToolSheet({
            onChangeBackground: (config) => { this.changeBackground(config); }
          })
        }

        // 浮动贴纸编辑 Sheet
        if (this.showEditSheet && this.selectedItem) {
          StickerEditSheet({
            item: this.selectedItem,
            onClose: () => { this.showEditSheet = false; },
            onReset: () => { this.onResetEdit(); }
          })
        }
      }
      .width('100%')
      .layoutWeight(1)

      // 底部工具栏
      CanvasToolPanel({
        activeTool: this.activeTool,
        onToolChange: (tool) => {
          if (tool === 'export') {
            this.finish();
          } else if (this.activeTool === tool) {
            this.activeTool = '';
          } else {
            this.activeTool = tool;
          }
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_base'))
    // 拦截水平滑动手势，阻止冒泡到 Tabs 切换标签页
    .gesture(
      PanGesture({ fingers: 1, direction: PanDirection.Horizontal })
        .onActionStart(() => {})
        .onActionUpdate(() => {})
        .onActionEnd(() => {})
    )
  }
}
