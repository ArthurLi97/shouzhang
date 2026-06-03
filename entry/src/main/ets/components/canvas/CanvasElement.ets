// components/canvas/CanvasElement.ets
// MEMO Canvas 贴纸 — 物理感照片贴纸
// 白边 12px + 24px 圆角 + 阴影，选中虚线框 + 旋转把手 + 删除按钮

import { BOUNDING, DANGER } from '../../constants/ThemeConstants';

const BORDER_WIDTH = 12;
const IMAGE_SIZE = 100;
const OUTER_SIZE = IMAGE_SIZE + BORDER_WIDTH * 2; // 124
const IMAGE_RADIUS = 24;
const OUTER_RADIUS = IMAGE_RADIUS + BORDER_WIDTH;   // 36

@Component
export struct CanvasElement {
  @Prop uri: string = '';
  @Prop isSelected: boolean = false;
  onDelete?: (id: string) => void;
  @Prop itemId: string = '';

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 白边贴纸层
      Stack({ alignContent: Alignment.Center }) {
        Image(this.uri)
          .width(IMAGE_SIZE)
          .height(IMAGE_SIZE)
          .objectFit(ImageFit.Contain)
          .borderRadius(IMAGE_RADIUS)
      }
      .padding(BORDER_WIDTH)
      .backgroundColor(Color.White)
      .borderRadius(OUTER_RADIUS)
      .shadow({
        radius: 20,
        color: 'rgba(0,0,0,0.08)',
        offsetX: 0,
        offsetY: 6
      })

      // 选中态层
      if (this.isSelected) {
        // 1.5px 虚线框（包裹白边外沿）
        Stack()
          .width(OUTER_SIZE)
          .height(OUTER_SIZE)
          .border({
            width: 1.5,
            color: BOUNDING,
            style: BorderStyle.Dashed
          })
          .borderRadius(OUTER_RADIUS)

        // 旋转把手 — 底部中心，24pt
        Stack({ alignContent: Alignment.Center }) {
          SymbolGlyph($r('sys.symbol.arrow_clockwise'))
            .fontSize(12)
            .fontColor([Color.White])
        }
        .width(24)
        .height(24)
        .backgroundColor(BOUNDING)
        .borderRadius(12)
        .offset({ x: 0, y: OUTER_SIZE / 2 - 12 })  // 底部中心外侧

        // 删除按钮 — 右上角，28pt 红色圆
        Stack({ alignContent: Alignment.Center }) {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(11)
            .fontColor([Color.White])
        }
        .width(28)
        .height(28)
        .backgroundColor(DANGER)
        .borderRadius(14)
        .offset({ x: OUTER_SIZE / 2 - 14, y: -(OUTER_SIZE / 2 - 14) })
        .shadow({ radius: 4, color: 'rgba(255,59,48,0.25)', offsetY: 2 })
        .onClick(() => { this.onDelete?.(this.itemId); })
      }
    }
    .width(OUTER_SIZE)
    .height(OUTER_SIZE)
  }
}
