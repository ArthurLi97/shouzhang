// components/canvas/PaperSheet.ets
// Paper Craft 厚纸板装饰组件
// 用多层 Stack 叠加模拟实体纸张厚度、soft shadow、切割边缘

import { getThicknessColor } from '../../utils/ColorUtils';

@Component
export struct PaperSheet {
  @Prop color: string = '#FFFFFF';
  @Prop thickness: number = 2;        // 纸张厚度（px）
  @Prop radius: number = 0;           // 圆角
  @Prop showHighlight: boolean = true; // 是否显示顶部高光边
  @BuilderParam content: () => void = this.defaultBuilder;

  @Builder
  defaultBuilder() {}

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // Layer 1: 环境柔化 shadow（大半径低浓度）
      Stack()
        .width('100%')
        .height('100%')
        .backgroundColor(this.color)
        .borderRadius(this.radius)
        .shadow({
          radius: 16,
          color: 'rgba(0,0,0,0.04)',
          offsetX: 0,
          offsetY: 6
        })

      // Layer 2: 核心 shadow（小半径贴底阴影）
      Stack()
        .width('100%')
        .height('100%')
        .backgroundColor(this.color)
        .borderRadius(this.radius)
        .shadow({
          radius: 4,
          color: 'rgba(0,0,0,0.06)',
          offsetX: 0,
          offsetY: 2
        })

      // Layer 3: 厚度层（深色偏移，模拟纸张侧面）
      Stack()
        .width('100%')
        .height('100%')
        .backgroundColor(getThicknessColor(this.color))
        .borderRadius(this.radius)
        .offset({ x: 0, y: this.thickness })

      // Layer 4: 主色层
      Stack()
        .width('100%')
        .height('100%')
        .backgroundColor(this.color)
        .borderRadius(this.radius)

      // Layer 5: 顶部高光边（模拟纸张顶面受光）
      if (this.showHighlight) {
        Stack()
          .width('100%')
          .height('100%')
          .borderRadius(this.radius)
          .border({
            width: { top: 0.5, left: 0.5, right: 0, bottom: 0 },
            color: 'rgba(255,255,255,0.35)',
            style: BorderStyle.Solid
          })
      }

      // Layer 6: 内容插槽
      Stack() {
        this.content()
      }
      .width('100%')
      .height('100%')
    }
  }
}
