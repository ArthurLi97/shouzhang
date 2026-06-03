// components/canvas/CollectionFolderSheet.ets
// Collection 层叠纸张 — 单张厚纸板文件夹卡片
// 左侧标签脊 + 名称 + 计数 + 纸张厚度与阴影

import { getThicknessColor } from '../../utils/ColorUtils';
import { TEXT_PRIMARY, TEXT_SECONDARY, TEXT_TERTIARY } from '../../constants/ThemeConstants';

const SHEET_HEIGHT = 64;
const TAB_WIDTH = 6;
const TAB_RADIUS = 12;

interface CollectionFolderSheetParams {
  name: string;
  color: string;
  count: number;
  onTap?: () => void;
}

@Component
export struct CollectionFolderSheet {
  @Prop name: string = '';
  @Prop color: string = '#FFFFFF';
  @Prop count: number = 0;
  onTap?: () => void;

  private get tabColor(): string {
    return getThicknessColor(this.color);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // === Layer 1: 环境柔化 shadow ===
      Stack()
        .width('100%')
        .height('100%')
        .backgroundColor(this.color)
        .borderRadius(16)
        .shadow({
          radius: 12,
          color: 'rgba(0,0,0,0.05)',
          offsetX: 0,
          offsetY: 4
        })

      // === Layer 2: 核心贴底 shadow ===
      Stack()
        .width('100%')
        .height('100%')
        .backgroundColor(this.color)
        .borderRadius(16)
        .shadow({
          radius: 4,
          color: 'rgba(0,0,0,0.06)',
          offsetX: 0,
          offsetY: 2
        })

      // === Layer 3: 厚度层 ===
      Stack()
        .width('100%')
        .height('100%')
        .backgroundColor(getThicknessColor(this.color))
        .borderRadius(16)
        .offset({ x: 0, y: 2 })

      // === Layer 4: 主色层 ===
      Stack()
        .width('100%')
        .height('100%')
        .backgroundColor(this.color)
        .borderRadius(16)

      // === Layer 5: 顶部高光边 ===
      Stack()
        .width('100%')
        .height('100%')
        .borderRadius(16)
        .border({
          width: { top: 0.5, left: 0.5, right: 0, bottom: 0 },
          color: 'rgba(255,255,255,0.4)',
          style: BorderStyle.Solid
        })

      // === Layer 6: 内容 ===
      Row({ space: 0 }) {
        // 左侧标签脊（文件夹感）
        Stack()
          .width(TAB_WIDTH)
          .height('100%')
          .backgroundColor(this.tabColor)
          .borderRadius({ topLeft: TAB_RADIUS, bottomLeft: TAB_RADIUS })

        // 内容区
        Row({ space: 8 }) {
          Text(this.name)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(TEXT_PRIMARY)
            .layoutWeight(1)

          Text(`${this.count}`)
            .fontSize(14)
            .fontColor(TEXT_SECONDARY)

          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(14)
            .fontColor([TEXT_TERTIARY])
        }
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
      }
      .width('100%')
      .height('100%')

      // 可点击遮罩：只覆盖顶部标签区域（44px），底部20px可穿透到下层
      Row()
        .width('100%')
        .height(44)
        .position({ x: 0, y: 0 })
        .onClick(() => { this.onTap?.(); })
    }
    .width('100%')
    .height(SHEET_HEIGHT)
  }
}
