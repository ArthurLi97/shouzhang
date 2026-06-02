// components/NewStickerCard.ets

@Component
export struct NewStickerCard {
  onCardClick?: () => void;

  build() {
    Column() {
      Row() {
        Stack() {
          SymbolGlyph($r('sys.symbol.plus'))
            .fontSize(20)
            .fontColor([Color.White])
        }
        .width(36)
        .height(36)
        .backgroundColor($r('app.color.brand_primary'))
        .borderRadius(18)

        Text('新建贴纸')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 12 })
          .fontColor($r('app.color.ink_deep'))
        Blank()
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(16)
          .fontColor([$r('app.color.ink_light')])
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .margin({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(16)
    .shadow({
      radius: 8,
      color: $r('app.color.shadow_card'),
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      this.onCardClick?.();
    })
  }
}
