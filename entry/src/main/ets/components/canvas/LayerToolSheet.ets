// components/canvas/LayerToolSheet.ets
// 图层管理底部面板

import { CanvasItem } from '../../models/CanvasItem';

@Component
export struct LayerToolSheet {
  @Link canvasItems: CanvasItem[];
  @Link selectedItemId: string | null;
  onClose?: () => void;

  get sortedItems(): CanvasItem[] {
    // 倒序显示：zIndex 大的在上层（数组末尾）
    return [...this.canvasItems].sort((a, b) => b.zIndex - a.zIndex);
  }

  moveUp(item: CanvasItem): void {
    // 在原始数组中找到索引，向上交换（zIndex 变大 = 上层）
    const idx = this.canvasItems.findIndex(i => i.id === item.id);
    if (idx < 0 || idx >= this.canvasItems.length - 1) return;
    // 与后一个元素交换（zIndex 更大 = 更上层）
    const temp = this.canvasItems[idx];
    this.canvasItems[idx] = this.canvasItems[idx + 1];
    this.canvasItems[idx + 1] = temp;
    this.canvasItems = [...this.canvasItems];
    this.rebuildZIndex();
  }

  moveDown(item: CanvasItem): void {
    const idx = this.canvasItems.findIndex(i => i.id === item.id);
    if (idx <= 0) return;
    // 与前一个元素交换（zIndex 更小 = 更下层）
    const temp = this.canvasItems[idx];
    this.canvasItems[idx] = this.canvasItems[idx - 1];
    this.canvasItems[idx - 1] = temp;
    this.canvasItems = [...this.canvasItems];
    this.rebuildZIndex();
  }

  deleteItem(item: CanvasItem): void {
    const idx = this.canvasItems.findIndex(i => i.id === item.id);
    if (idx >= 0) {
      this.canvasItems.splice(idx, 1);
      this.canvasItems = [...this.canvasItems];
      this.rebuildZIndex();
      if (this.selectedItemId === item.id) {
        this.selectedItemId = null;
      }
    }
  }

  rebuildZIndex(): void {
    this.canvasItems.forEach((item: CanvasItem, idx: number) => {
      item.zIndex = idx;
    });
  }

  build() {
    Column({ space: 0 }) {
      // 顶部标题栏
      Row() {
        Text('图层')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.ink_deep'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(20)
          .fontColor([$r('app.color.ink_mid')])
          .onClick(() => { this.onClose?.(); })
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })

      // 图层列表
      List() {
        ForEach(this.sortedItems, (item: CanvasItem) => {
          ListItem() {
            Row({ space: 12 }) {
              // 缩略图
              Stack() {
                if (item.type === 'sticker' && item.uri) {
                  Image(item.uri)
                    .width('100%')
                    .height('100%')
                    .objectFit(ImageFit.Cover)
                    .borderRadius(4)
                } else if (item.type === 'text') {
                  Text(item.content ?? '')
                    .fontSize(10)
                    .fontColor(Color.Black)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
              }
              .width(48)
              .height(48)
              .backgroundColor(Color.White)
              .borderRadius(6)
              .border({
                width: this.selectedItemId === item.id ? 2 : 1,
                color: this.selectedItemId === item.id ? $r('app.color.brand_primary') : $r('app.color.divider')
              })

              // 信息
              Column({ space: 4 }) {
                Text(item.type === 'sticker' ? '贴纸' : '文字')
                  .fontSize(14)
                  .fontColor($r('app.color.ink_deep'))
                Text(`层级 ${item.zIndex}`)
                  .fontSize(11)
                  .fontColor($r('app.color.ink_light'))
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              // 操作按钮
              Row({ space: 8 }) {
                SymbolGlyph($r('sys.symbol.arrow_up'))
                  .fontSize(18)
                  .fontColor([$r('app.color.ink_mid')])
                  .onClick(() => { this.moveUp(item); })

                SymbolGlyph($r('sys.symbol.arrow_down'))
                  .fontSize(18)
                  .fontColor([$r('app.color.ink_mid')])
                  .onClick(() => { this.moveDown(item); })

                SymbolGlyph($r('sys.symbol.trash'))
                  .fontSize(18)
                  .fontColor([$r('app.color.danger')])
                  .onClick(() => { this.deleteItem(item); })
              }
            }
            .width('100%')
            .height(64)
            .padding({ left: 16, right: 16 })
            .backgroundColor(this.selectedItemId === item.id ? $r('app.color.brand_primary_light') : Color.Transparent)
          }
          .onClick(() => { this.selectedItemId = item.id; })
        }, (item: CanvasItem) => item.id)
      }
      .divider({ strokeWidth: 0.5, color: $r('app.color.divider') })
      .layoutWeight(1)
      .padding({ bottom: 16 })
    }
    .width('100%')
    .height(320)
    .backgroundColor('rgba(255,255,255,0.95)')
    .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
    .borderRadius({ topLeft: 20, topRight: 20 })
  }
}
