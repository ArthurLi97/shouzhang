// components/canvas/CanvasElement.ets
// 画布元素：贴纸/文字，支持选中状态、拖拽反馈、删除提示

import { CanvasItem } from '../../models/CanvasItem';

@Component
export struct CanvasElement {
  @ObjectLink item: CanvasItem;
  @Prop isSelected: boolean;
  @Prop isDragging: boolean = false;
  @Prop isOverDelete: boolean = false;

  build() {
    Stack() {
      // 内容层
      Stack() {
        if (this.item.type === 'sticker' && this.item.uri) {
          Image(this.item.uri)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
        } else if (this.item.type === 'text' && this.item.content) {
          Text(this.item.content)
            .fontSize(this.item.fontSize)
            .fontColor(this.item.fontColor)
            .width('100%')
            .height('100%')
            .textAlign(TextAlign.Center)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .maxLines(3)
            .hitTestBehavior(HitTestMode.Transparent)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.item.type === 'text' ? 'rgba(255,255,255,0.01)' : Color.White)
      .borderRadius(8)
      .shadow(this.item.shadowEnabled ? {
        radius: 8,
        color: this.item.shadowColor,
        offsetX: 2,
        offsetY: 4
      } : undefined)
      .border(this.item.borderWidth > 0 ? {
        width: this.item.borderWidth,
        color: this.item.borderColor,
        style: BorderStyle.Solid
      } : undefined)
      // 拖拽时半透明
      .opacity(this.isDragging ? 0.75 : 1)
      // 选中时轻微放大
      .scale({
        x: this.isSelected ? 1.03 : 1,
        y: this.isSelected ? 1.03 : 1,
        centerX: '50%',
        centerY: '50%'
      })
      .animation({ duration: 150, curve: Curve.EaseInOut })

      // 选中状态外框
      if (this.isSelected) {
        Stack()
          .width('100%')
          .height('100%')
          .border({
            width: 2,
            color: this.isOverDelete ? '#FF3B30' : $r('app.color.brand_primary'),
            style: BorderStyle.Dashed
          })
          .borderRadius(8)
          .margin(2)

        // 四角控制点
        this.ControlDot(Alignment.TopStart)
        this.ControlDot(Alignment.TopEnd)
        this.ControlDot(Alignment.BottomStart)

        // 右下角缩放/旋转手柄
        Stack() {
          SymbolGlyph($r('sys.symbol.arrow_up_left_and_arrow_down_right'))
            .fontSize(12)
            .fontColor([Color.White])
        }
        .width(20)
        .height(20)
        .backgroundColor(this.isOverDelete ? '#FF3B30' : $r('app.color.brand_primary'))
        .borderRadius(10)
        .position({ x: -10, y: -10 })
        .align(Alignment.BottomEnd)
      }
    }
    .width(this.item.width)
    .height(this.item.height)
  }

  @Builder
  ControlDot(align: Alignment): void {
    Stack()
      .width(8)
      .height(8)
      .backgroundColor(this.isOverDelete ? '#FF3B30' : $r('app.color.brand_primary'))
      .borderRadius(4)
      .position({
        x: align === Alignment.TopStart || align === Alignment.BottomStart ? -4 : undefined,
        y: align === Alignment.TopStart || align === Alignment.TopEnd ? -4 : undefined,
        right: align === Alignment.TopEnd ? -4 : undefined,
        bottom: align === Alignment.BottomStart ? -4 : undefined,
      })
      .align(align)
  }
}
