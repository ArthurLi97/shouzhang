// components/canvas/TextToolSheet.ets
// 文字工具面板：支持输入内容、选择颜色、调整大小

@Component
export struct TextToolSheet {
  onAddText?: (text: string, color: string, size: number) => void;
  @State inputText: string = '';
  @State selectedColor: string = '#1A1A1A';
  @State fontSize: number = 24;

  private colors: string[] = [
    '#1A1A1A', '#666666', '#999999', '#FFFFFF',
    '#FF8A80', '#FF6B6B', '#FFD93D', '#FF6B9D',
    '#6B5CE7', '#4ECDC4', '#45B7D1', '#96CEB4'
  ];

  build() {
    Column({ space: 12 }) {
      Text('添加文字')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 12 })
        .fontColor($r('app.color.ink_deep'))

      // 实时预览
      Stack() {
        Text(this.inputText || '预览文字')
          .fontSize(this.fontSize)
          .fontColor(this.selectedColor)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('90%')
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(60)
      .align(Alignment.Center)

      TextInput({ placeholder: '输入文字内容', text: this.inputText })
        .width('90%')
        .height(44)
        .backgroundColor($r('app.color.search_bg'))
        .borderRadius(8)
        .onChange((v) => { this.inputText = v; })

      // 颜色选择
      Row({ space: 8 }) {
        ForEach(this.colors, (color: string) => {
          Stack()
            .width(28)
            .height(28)
            .backgroundColor(color)
            .borderRadius(14)
            .border({
              width: this.selectedColor === color ? 3 : 1,
              color: this.selectedColor === color ? $r('app.color.brand_primary') : '#E5E5E5'
            })
            .onClick(() => { this.selectedColor = color; })
        }, (color: string) => color)
      }
      .width('90%')
      .justifyContent(FlexAlign.Center)

      // 大小滑块
      Row() {
        Text('小')
          .fontSize(12)
          .fontColor($r('app.color.ink_light'))
        Slider({
          value: this.fontSize,
          min: 12,
          max: 72,
          step: 2,
          style: SliderStyle.OutSet
        })
          .layoutWeight(1)
          .selectedColor($r('app.color.brand_primary'))
          .onChange((value: number) => { this.fontSize = value; })
        Text('大')
          .fontSize(12)
          .fontColor($r('app.color.ink_light'))
      }
      .width('90%')

      Button('添加', { type: ButtonType.Capsule })
        .width('90%')
        .height(40)
        .backgroundColor($r('app.color.brand_primary'))
        .fontColor(Color.White)
        .onClick(() => {
          if (this.inputText.trim()) {
            this.onAddText?.(this.inputText.trim(), this.selectedColor, this.fontSize);
            this.inputText = '';
          }
        })
    }
    .width('100%')
    .padding({ bottom: 16 })
    .backgroundColor('rgba(255,255,255,0.85)')
    .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
    .borderRadius({ topLeft: 20, topRight: 20 })
  }
}
