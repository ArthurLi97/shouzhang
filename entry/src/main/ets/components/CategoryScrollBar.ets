// components/CategoryScrollBar.ets

@Component
export struct CategoryScrollBar {
  @Link selected: string;
  private categories: string[] = ['全部', '咖啡', '美食', '花草', '宠物', '其他'];

  build() {
    Scroll() {
      Row({ space: 12 }) {
        ForEach(this.categories, (cat: string) => {
          Text(cat)
            .fontSize(14)
            .fontWeight(this.selected === cat ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(this.selected === cat ? $r('app.color.ink_deep') : $r('app.color.ink_mid'))
            .backgroundColor(this.selected === cat ? $r('app.color.chip_bg') : Color.Transparent)
            .padding({ top: 6, bottom: 6, left: 12, right: 12 })
            .borderRadius(16)
            .onClick(() => { this.selected = cat; })
        })
      }
      .padding({ left: 16, right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .width('100%')
    .height(48)
  }
}
