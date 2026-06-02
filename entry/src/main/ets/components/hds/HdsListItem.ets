// components/hds/HdsListItem.ets
// HDS 风格列表项封装（基础 ArkUI 实现，未来可无缝替换为真实 HDS Kit）

@Component
export struct HdsListItem {
  @Prop primaryText: string = '';
  @Prop primaryTextFontSize: number = 16;
  @Prop showPrefixSymbol: boolean = false;
  @Prop primaryPrefixSymbol: Resource = $r('sys.symbol.heart');
  @Prop secondaryText: string = '';
  @Prop secondaryTextFontSize: number = 12;
  @Prop suffixType: string = '';
  @Prop suffixText: string = '';
  @Prop suffixBadgeText: string = '';
  @BuilderParam suffixArea: () => void = this.DefaultSuffixArea;

  @Builder
  DefaultSuffixArea(): void {
    if (this.suffixType === 'arrow') {
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor([$r('app.color.ink_light')])
    } else if (this.suffixType === 'text') {
      Text(this.suffixText)
        .fontSize(14)
        .fontColor($r('app.color.ink_light'))
        .margin({ right: 8 })
    } else if (this.suffixType === 'badge') {
      Text(this.suffixBadgeText)
        .fontSize(12)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.brand_primary'))
        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        .borderRadius(10)
    }
  }

  build() {
    Row({ space: 12 }) {
      if (this.showPrefixSymbol) {
        SymbolGlyph(this.primaryPrefixSymbol)
          .fontSize(20)
          .fontColor([$r('app.color.ink_mid')])
      }

      Column({ space: 4 }) {
        Text(this.primaryText)
          .fontSize(this.primaryTextFontSize)
          .fontColor($r('app.color.ink_deep'))

        if (this.secondaryText) {
          Text(this.secondaryText)
            .fontSize(this.secondaryTextFontSize)
            .fontColor($r('app.color.ink_light'))
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Blank()

      this.suffixArea()
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor($r('app.color.card_bg'))
  }
}
