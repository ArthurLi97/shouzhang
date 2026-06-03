// pages/Index.ets
// MEMO 根页面：Navigation 容器，默认显示 Canvas 编辑器

import { CanvasEditPage } from './canvas/CanvasEditPage';
import { ProcessingPage } from './home/ProcessingPage';
import { StickerPreviewPage } from './home/StickerPreviewPage';
import { NoSubjectPage } from './home/NoSubjectPage';
import { BlurSubjectPage } from './home/BlurSubjectPage';
import { MultiSubjectSelectPage } from './home/MultiSubjectSelectPage';
import { RdbHelper } from '../database/RdbHelper';
import { PreferencesHelper } from '../database/PreferencesHelper';
import { common } from '@kit.AbilityKit';
import { PrivacyDialog, PrivacyConsent } from '../components/PrivacyDialog';

type PrivacyViewMode = 'dialog' | 'privacy' | 'agreement';

@Entry
@Component
struct RootPage {
  @Provide('rootPathStack') pathStack: NavPathStack = new NavPathStack();
  @State showPrivacyDialog: boolean = false;
  @State privacyChecked: boolean = false;
  @State privacyViewMode: PrivacyViewMode = 'dialog';

  aboutToAppear(): void {
    this.initializeApp();
  }

  async initializeApp(): Promise<void> {
    const context = this.getUIContext().getHostContext() as common.Context;
    await RdbHelper.getInstance().init(context);
    await PreferencesHelper.getInstance().init(context);
    const consented = await PrivacyConsent.hasConsented();
    if (consented) {
      this.privacyChecked = true;
    } else {
      this.showPrivacyDialog = true;
    }
  }

  onPrivacyAgree(): void {
    this.showPrivacyDialog = false;
    PrivacyConsent.setConsented(true);
    this.privacyChecked = true;
  }

  onPrivacyDisagree(): void {
    this.showPrivacyDialog = false;
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    try {
      context.terminateSelf();
    } catch (err) {
      console.error('terminateSelf error:', JSON.stringify(err));
    }
  }

  @Builder
  navDestinationBuilder(name: string, param: object) {
    NavDestination() {
      if (name === 'ProcessingPage') {
        ProcessingPage()
      } else if (name === 'StickerPreviewPage') {
        StickerPreviewPage()
      } else if (name === 'NoSubjectPage') {
        NoSubjectPage()
      } else if (name === 'BlurSubjectPage') {
        BlurSubjectPage()
      } else if (name === 'MultiSubjectSelectPage') {
        MultiSubjectSelectPage()
      }
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg_base'))
  }

  build() {
    Stack() {
      if (this.privacyChecked) {
        Navigation(this.pathStack) {
          CanvasEditPage()
        }
        .hideTitleBar(true)
        .navDestination(this.navDestinationBuilder)
        .mode(NavigationMode.Stack)
        .width('100%')
        .height('100%')
      }

      if (this.showPrivacyDialog) {
        Column() {
          Blank()
            .backgroundColor('rgba(0,0,0,0.5)')
            .layoutWeight(1)
            .width('100%')

          if (this.privacyViewMode === 'dialog') {
            PrivacyDialog({
              onAgree: () => { this.onPrivacyAgree(); },
              onDisagree: () => { this.onPrivacyDisagree(); },
              onPrivacyClick: () => { this.privacyViewMode = 'privacy'; },
              onAgreementClick: () => { this.privacyViewMode = 'agreement'; }
            })
            .padding(24)
          } else {
            this.PrivacyContentBuilder()
          }
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  PrivacyContentBuilder(): void {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([$r('app.color.ink_deep')])
          .onClick(() => { this.privacyViewMode = 'dialog'; })
        Text(this.privacyViewMode === 'privacy' ? '隐私政策' : '用户协议')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.ink_deep'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Blank().width(24)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      Scroll() {
        Column({ space: 16 }) {
          Text(this.privacyViewMode === 'privacy' ? 'MEMO 隐私政策' : 'MEMO 用户协议')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.ink_deep'))
            .width('100%')

          Text('最后更新日期：2026年6月1日')
            .fontSize(12)
            .fontColor($r('app.color.ink_light'))
            .width('100%')
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)

      Row({ space: 12 }) {
        Button('不同意', { type: ButtonType.Capsule })
          .layoutWeight(1)
          .height(44)
          .backgroundColor($r('app.color.card_bg'))
          .fontColor($r('app.color.ink_mid'))
          .onClick(() => { this.onPrivacyDisagree(); })

        Button('同意', { type: ButtonType.Capsule })
          .layoutWeight(1)
          .height(44)
          .backgroundColor($r('app.color.brand_primary'))
          .fontColor(Color.White)
          .onClick(() => { this.onPrivacyAgree(); })
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_base'))
  }
}
