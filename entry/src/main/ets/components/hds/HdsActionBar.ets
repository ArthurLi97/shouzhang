// components/hds/HdsActionBar.ets
// HDS 风格顶部操作栏封装（基础 ArkUI 实现，未来可无缝替换为真实 HDS Kit）

export enum ActionBarStyle {
  NORMAL,
  TRANSPARENT
}

export interface ActionButton {
  icon?: Resource;
  text?: string;
  textColor?: ResourceColor;
  action?: () => void;
}

export interface PrimaryTextConfig {
  text: string;
  fontSize?: number | string;
  fontWeight?: FontWeight;
  fontColor?: ResourceColor;
}

@Component
export struct HdsActionBar {
  @Prop startButtons: ActionButton[] = [];
  @Prop primaryText: PrimaryTextConfig | undefined = undefined;
  @Prop endButtons: ActionButton[] = [];
  @Prop actionBarStyle: ActionBarStyle = ActionBarStyle.NORMAL;
  @BuilderParam customArea: () => void = this.DefaultCustomArea;

  @Builder
  DefaultCustomArea(): void {}

  private defaultTextColor: ResourceColor = $r('app.color.ink_deep');

  @Builder
  StartButtonItem(btn: ActionButton): void {
    if (btn.icon) {
      SymbolGlyph(btn.icon)
        .fontSize(24)
        .fontColor([btn.textColor ?? this.defaultTextColor])
    } else if (btn.text) {
      Text(btn.text)
        .fontSize(16)
        .fontColor(btn.textColor ?? $r('app.color.brand_primary'))
    }
  }

  @Builder
  EndButtonItem(btn: ActionButton): void {
    if (btn.icon) {
      SymbolGlyph(btn.icon)
        .fontSize(24)
        .fontColor([btn.textColor ?? this.defaultTextColor])
    } else if (btn.text) {
      Text(btn.text)
        .fontSize(16)
        .fontColor(btn.textColor ?? $r('app.color.brand_primary'))
    }
  }

  build() {
    Row() {
      // 左侧按钮组
      Row({ space: 16 }) {
        ForEach(this.startButtons, (btn: ActionButton, index: number) => {
          Stack() {
            this.StartButtonItem(btn)
          }
          .onClick(() => { btn.action?.(); })
        }, (btn: ActionButton, index: number) => index.toString())
      }

      // 中间标题或自定义区域
      if (this.primaryText) {
        Text(this.primaryText.text)
          .fontSize(this.primaryText.fontSize ?? 18)
          .fontWeight(this.primaryText.fontWeight ?? FontWeight.Medium)
          .fontColor(this.primaryText.fontColor ?? this.defaultTextColor)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      } else {
        this.customArea()
      }

      // 右侧按钮组
      Row({ space: 16 }) {
        ForEach(this.endButtons, (btn: ActionButton, index: number) => {
          Stack() {
            this.EndButtonItem(btn)
          }
          .onClick(() => { btn.action?.(); })
        }, (btn: ActionButton, index: number) => index.toString())
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(this.actionBarStyle === ActionBarStyle.NORMAL ? 'rgba(248,248,246,0.85)' : Color.Transparent)
    .backgroundBlurStyle(this.actionBarStyle === ActionBarStyle.NORMAL ? BlurStyle.COMPONENT_THICK : undefined)
  }
}
