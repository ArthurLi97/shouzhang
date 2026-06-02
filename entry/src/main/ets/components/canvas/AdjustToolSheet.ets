// components/canvas/AdjustToolSheet.ets

@Component
export struct AdjustToolSheet {
  onClear?: () => void;

  build() {
    Column({ space: 12 }) {
      Text('调整')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 12 })
        .fontColor($r('app.color.ink_deep'))

      Button('清空画布', { type: ButtonType.Capsule })
        .width('90%')
        .height(40)
        .backgroundColor($r('app.color.danger'))
        .fontColor(Color.White)
        .onClick(() => {
          this.onClear?.();
        })
    }
    .width('100%')
    .padding({ bottom: 16 })
    .backgroundColor('rgba(255,255,255,0.85)')
    .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
    .borderRadius({ topLeft: 20, topRight: 20 })
  }
}
