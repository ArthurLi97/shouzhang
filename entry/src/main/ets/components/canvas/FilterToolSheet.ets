// components/canvas/FilterToolSheet.ets
// 滤镜工具占位面板

interface FilterItem {
  name: string;
  icon: Resource;
}

@Component
export struct FilterToolSheet {
  onClose?: () => void;

  private filters: FilterItem[] = [
    { name: '原图', icon: $r('sys.symbol.camera') },
    { name: '灰度', icon: $r('sys.symbol.circle') },
    { name: '复古', icon: $r('sys.symbol.circle') },
    { name: '明亮', icon: $r('sys.symbol.circle') },
    { name: '暖色', icon: $r('sys.symbol.circle') },
    { name: '冷色', icon: $r('sys.symbol.circle') },
  ];

  build() {
    Column({ space: 12 }) {
      // 顶部标题栏
      Row() {
        Text('滤镜')
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

      Text('滤镜功能开发中')
        .fontSize(14)
        .fontColor($r('app.color.ink_light'))
        .margin({ top: 8, bottom: 8 })

      // 滤镜选项骨架
      Row({ space: 16 }) {
        ForEach(this.filters, (filter: FilterItem) => {
          Column({ space: 6 }) {
            Stack() {
              SymbolGlyph(filter.icon)
                .fontSize(24)
                .fontColor([$r('app.color.ink_mid')])
            }
            .width(56)
            .height(56)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(28)

            Text(filter.name)
              .fontSize(11)
              .fontColor($r('app.color.ink_mid'))
          }
        }, (filter: FilterItem) => filter.name)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .padding({ top: 8, bottom: 16 })
    }
    .width('100%')
    .backgroundColor('rgba(255,255,255,0.95)')
    .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
    .borderRadius({ topLeft: 20, topRight: 20 })
  }
}
