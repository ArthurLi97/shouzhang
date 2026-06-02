// components/hds/HdsToolBar.ets
// HDS 风格横向工具栏封装（基础 ArkUI 实现，未来可无缝替换为真实 HDS Kit）

export interface ToolItem {
  name: string;
  icon: Resource;
  label: string;
}

@Component
export struct HdsToolBar {
  @Prop tools: ToolItem[] = [];
  @Link activeTool: string;
  onChange?: (name: string) => void;
  @Prop barHeight: number = 56;

  build() {
    Row() {
      ForEach(this.tools, (tool: ToolItem, index: number) => {
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
        }
        .layoutWeight(1)
        .onClick(() => {
          this.activeTool = tool.name;
          this.onChange?.(tool.name);
        })
      }, (tool: ToolItem, index: number) => tool.name)
    }
    .width('100%')
    .height(this.barHeight)
    .backgroundColor('rgba(255,255,255,0.85)')
    .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
    .shadow({ radius: 8, color: $r('app.color.shadow_card'), offsetX: 0, offsetY: -2 })
  }
}
