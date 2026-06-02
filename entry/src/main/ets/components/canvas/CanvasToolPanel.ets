// components/canvas/CanvasToolPanel.ets

interface ToolItem {
  name: string;
  icon: Resource;
  label: string;
}

@Component
export struct CanvasToolPanel {
  @Link activeTool: string;
  onToolChange?: (tool: string) => void;

  private tools: ToolItem[] = [
    { name: 'sticker', icon: $r('sys.symbol.plus'), label: '添加贴纸' },
    { name: 'text', icon: $r('sys.symbol.textformat'), label: '文字' },
    { name: 'bg', icon: $r('sys.symbol.rectangle'), label: '背景' },
    { name: 'export', icon: $r('sys.symbol.arrow_up'), label: '导出' },
  ];

  build() {
    Row() {
      ForEach(this.tools, (tool: ToolItem) => {
        Column({ space: 4 }) {
          SymbolGlyph(tool.icon)
            .fontSize(24)
            .fontColor([
              this.activeTool === tool.name
                ? $r('app.color.brand_primary')
                : $r('app.color.ink_mid')
            ])
          Text(tool.label)
            .fontSize(11)
            .fontColor(
              this.activeTool === tool.name
                ? $r('app.color.brand_primary')
                : $r('app.color.ink_mid')
            )
            .fontWeight(this.activeTool === tool.name ? FontWeight.Medium : FontWeight.Normal)
        }
        .width('25%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .onClick(() => { this.onToolChange?.(tool.name); })
      })
    }
    .width('100%')
    .height(80)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius({ topLeft: 20, topRight: 20 })
    .shadow({ radius: 16, color: $r('app.color.shadow_float'), offsetX: 0, offsetY: -4 })
    .padding({ bottom: '16vp' })
  }
}
