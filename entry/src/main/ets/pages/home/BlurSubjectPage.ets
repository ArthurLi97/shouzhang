// pages/home/BlurSubjectPage.ets
// 异常状态：主体模糊

@Component
export struct BlurSubjectPage {
  @Consume('rootPathStack') pathStack: NavPathStack;

  build() {
    Column({ space: 24 }) {
      SymbolGlyph($r('sys.symbol.camera'))
        .fontSize(80)
        .fontColor([$r('app.color.ink_light')])
        .opacity(0.5)

      Text('主体模糊')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.ink_deep'))

      Text('图片有些模糊，请尝试更清晰的图片')
        .fontSize(14)
        .fontColor($r('app.color.ink_mid'))
        .textAlign(TextAlign.Center)
        .padding({ left: 32, right: 32 })

      Button('重新选择', { type: ButtonType.Capsule })
        .width('60%')
        .height(48)
        .backgroundColor($r('app.color.brand_primary'))
        .fontColor(Color.White)
        .margin({ top: 24 })
        .onClick(() => {
          AppStorage.setOrCreate('auto_open_picker', true);
          this.pathStack.clear();
        })
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: '24vp' })
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.bg_base'))
  }
}
