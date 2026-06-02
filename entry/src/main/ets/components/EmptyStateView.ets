// components/EmptyStateView.ets

@Component
export struct EmptyStateView {
  @Prop icon: Resource;
  @Prop title: string;
  @Prop subtitle: string;

  build() {
    Column({ space: 16 }) {
      SymbolGlyph(this.icon)
        .fontSize(64)
        .fontColor([$r('app.color.ink_light')])
        .opacity(0.5)

      Text(this.title)
        .fontSize(16)
        .fontColor($r('app.color.ink_mid'))

      Text(this.subtitle)
        .fontSize(14)
        .fontColor($r('app.color.ink_light'))
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
}
