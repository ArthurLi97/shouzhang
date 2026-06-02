// components/canvas/StickerEditSheet.ets
// 贴纸编辑底部面板（对应原型图04）

import { CanvasItem } from '../../models/CanvasItem';

interface BorderSizeItem {
  label: string;
  value: number;
}

@Component
export struct StickerEditSheet {
  @ObjectLink item: CanvasItem;
  onClose?: () => void;
  onReset?: () => void;

  @State activeTab: number = 0;
  private borderSizes: BorderSizeItem[] = [
    { label: '小', value: 2 },
    { label: '中', value: 4 },
    { label: '大', value: 6 },
  ];
  private colors: string[] = [
    '#FFFFFF', '#FFE4E1', '#FFD93D', '#FF6B9D', '#6B5CE7',
    '#4ECDC4', '#45B7D1', '#96CEB4', '#FECA57', '#FF9FF3',
    '#54A0FF', '#5F27CD', '#00D2D3', '#1DD1A1', '#FF9F43',
    '#EE5A24', '#009432', '#0652DD', '#9980FA', '#833471',
  ];

  build() {
    Column({ space: 0 }) {
      // 顶部标题栏
      Row() {
        Text('编辑贴纸')
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

      // Tab 切换
      Row() {
        ForEach(['描边', '阴影', '调整'], (tab: string, index: number) => {
          Text(tab)
            .fontSize(14)
            .fontWeight(this.activeTab === index ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(this.activeTab === index ? $r('app.color.brand_primary') : $r('app.color.ink_mid'))
            .backgroundColor(this.activeTab === index ? $r('app.color.brand_primary_light') : Color.Transparent)
            .padding({ top: 6, bottom: 6, left: 20, right: 20 })
            .borderRadius(16)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .onClick(() => { this.activeTab = index; })
        })
      }
      .width('100%')
      .padding({ top: 4, bottom: 12, left: 16, right: 16 })

      // Tab 内容区
      if (this.activeTab === 0) {
        this.BorderTab()
      } else if (this.activeTab === 1) {
        this.ShadowTab()
      } else {
        this.AdjustTab()
      }

      // 底部操作
      Row({ space: 12 }) {
        Button('重置', { type: ButtonType.Capsule })
          .layoutWeight(1)
          .height(40)
          .backgroundColor($r('app.color.card_bg'))
          .fontColor($r('app.color.ink_mid'))
          .onClick(() => { this.onReset?.(); })

        Button('完成', { type: ButtonType.Capsule })
          .layoutWeight(1)
          .height(40)
          .backgroundColor($r('app.color.brand_primary'))
          .fontColor(Color.White)
          .onClick(() => { this.onClose?.(); })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 16, top: 8 })
    }
    .width('100%')
    .backgroundColor('rgba(255,255,255,0.95)')
    .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
    .borderRadius({ topLeft: 20, topRight: 20 })
  }

  @Builder
  BorderTab(): void {
    Column({ space: 16 }) {
      // 描边大小
      Column({ space: 8 }) {
        Text('描边大小')
          .fontSize(14)
          .fontColor($r('app.color.ink_deep'))
          .width('100%')

        Row({ space: 12 }) {
          ForEach(this.borderSizes, (size: BorderSizeItem) => {
            Text(size.label)
              .fontSize(14)
              .fontWeight(this.item.borderWidth === size.value ? FontWeight.Medium : FontWeight.Normal)
              .fontColor(this.item.borderWidth === size.value ? Color.White : $r('app.color.ink_mid'))
              .backgroundColor(this.item.borderWidth === size.value ? $r('app.color.brand_primary') : $r('app.color.card_bg'))
              .padding({ top: 8, bottom: 8, left: 24, right: 24 })
              .borderRadius(8)
              .onClick(() => { this.item.borderWidth = size.value; })
          }, (size: BorderSizeItem) => size.label)
        }
        .width('100%')
      }

      // 颜色选择器
      Column({ space: 8 }) {
        Text('描边颜色')
          .fontSize(14)
          .fontColor($r('app.color.ink_deep'))
          .width('100%')

        Grid() {
          ForEach(this.colors, (color: string) => {
            GridItem() {
              Stack() {
                Stack()
                  .width(32)
                  .height(32)
                  .backgroundColor(color)
                  .borderRadius(16)
                  .border({
                    width: this.item.borderColor === color ? 3 : 1,
                    color: this.item.borderColor === color ? $r('app.color.brand_primary') : $r('app.color.divider')
                  })
              }
              .width(40)
              .height(40)
              .align(Alignment.Center)
            }
            .onClick(() => { this.item.borderColor = color; })
          }, (color: string) => color)
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
        .columnsGap(8)
        .rowsGap(8)
        .width('100%')
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 8 })
    .layoutWeight(1)
  }

  @Builder
  ShadowTab(): void {
    Column({ space: 16 }) {
      Row() {
        Text('启用阴影')
          .fontSize(14)
          .fontColor($r('app.color.ink_deep'))
          .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.item.shadowEnabled })
          .selectedColor($r('app.color.brand_primary'))
          .onChange((isOn: boolean) => { this.item.shadowEnabled = isOn; })
      }
      .width('100%')

      // 阴影颜色（仅开启时显示）
      if (this.item.shadowEnabled) {
        Column({ space: 8 }) {
          Text('阴影颜色')
            .fontSize(14)
            .fontColor($r('app.color.ink_deep'))
            .width('100%')

          Grid() {
            ForEach(this.colors.slice(0, 10), (color: string) => {
              GridItem() {
                Stack() {
                  Stack()
                    .width(32)
                    .height(32)
                    .backgroundColor(color)
                    .borderRadius(16)
                    .border({
                      width: this.item.shadowColor === color ? 3 : 1,
                      color: this.item.shadowColor === color ? $r('app.color.brand_primary') : $r('app.color.divider')
                    })
                }
                .width(40)
                .height(40)
                .align(Alignment.Center)
              }
              .onClick(() => { this.item.shadowColor = color; })
            }, (color: string) => color)
          }
          .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
          .columnsGap(8)
          .rowsGap(8)
          .width('100%')
        }
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 8 })
    .layoutWeight(1)
  }

  @Builder
  AdjustTab(): void {
    Column({ space: 16 }) {
      Column({ space: 8 }) {
        Text('缩放大小')
          .fontSize(14)
          .fontColor($r('app.color.ink_deep'))
          .width('100%')

        Row() {
          Text('0.5x')
            .fontSize(12)
            .fontColor($r('app.color.ink_light'))

          Slider({
            value: this.item.scale,
            min: 0.5,
            max: 3.0,
            step: 0.1,
            style: SliderStyle.OutSet
          })
            .layoutWeight(1)
            .selectedColor($r('app.color.brand_primary'))
            .onChange((value: number) => { this.item.scale = value; })

          Text('3.0x')
            .fontSize(12)
            .fontColor($r('app.color.ink_light'))
        }
        .width('100%')

        Text(`${this.item.scale.toFixed(1)}x`)
          .fontSize(12)
          .fontColor($r('app.color.ink_mid'))
          .width('100%')
          .textAlign(TextAlign.Center)
      }

      Column({ space: 8 }) {
        Text('旋转角度')
          .fontSize(14)
          .fontColor($r('app.color.ink_deep'))
          .width('100%')

        Row() {
          Text('-180°')
            .fontSize(12)
            .fontColor($r('app.color.ink_light'))

          Slider({
            value: this.item.rotation,
            min: -180,
            max: 180,
            step: 5,
            style: SliderStyle.OutSet
          })
            .layoutWeight(1)
            .selectedColor($r('app.color.brand_primary'))
            .onChange((value: number) => { this.item.rotation = value; })

          Text('180°')
            .fontSize(12)
            .fontColor($r('app.color.ink_light'))
        }
        .width('100%')

        Text(`${Math.round(this.item.rotation)}°`)
          .fontSize(12)
          .fontColor($r('app.color.ink_mid'))
          .width('100%')
          .textAlign(TextAlign.Center)
      }

      // 文字元素专属编辑
      if (this.item.type === 'text') {
        // 文字颜色
        Column({ space: 8 }) {
          Text('文字颜色')
            .fontSize(14)
            .fontColor($r('app.color.ink_deep'))
            .width('100%')

          Grid() {
            ForEach(this.colors.slice(0, 12), (color: string) => {
              GridItem() {
                Stack() {
                  Stack()
                    .width(28)
                    .height(28)
                    .backgroundColor(color)
                    .borderRadius(14)
                    .border({
                      width: this.item.fontColor === color ? 3 : 1,
                      color: this.item.fontColor === color ? $r('app.color.brand_primary') : $r('app.color.divider')
                    })
                }
                .width(36)
                .height(36)
                .align(Alignment.Center)
              }
              .onClick(() => { this.item.fontColor = color; })
            }, (color: string) => color)
          }
          .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr')
          .columnsGap(6)
          .rowsGap(6)
          .width('100%')
        }

        // 字体大小
        Column({ space: 8 }) {
          Text('字体大小')
            .fontSize(14)
            .fontColor($r('app.color.ink_deep'))
            .width('100%')

          Row() {
            Text('12')
              .fontSize(12)
              .fontColor($r('app.color.ink_light'))

            Slider({
              value: this.item.fontSize,
              min: 12,
              max: 72,
              step: 2,
              style: SliderStyle.OutSet
            })
              .layoutWeight(1)
              .selectedColor($r('app.color.brand_primary'))
              .onChange((value: number) => { this.item.fontSize = value; })

            Text('72')
              .fontSize(12)
              .fontColor($r('app.color.ink_light'))
          }
          .width('100%')

          Text(`${this.item.fontSize.toFixed(0)}`)
            .fontSize(12)
            .fontColor($r('app.color.ink_mid'))
            .width('100%')
            .textAlign(TextAlign.Center)
        }
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 8 })
    .layoutWeight(1)
  }
}
