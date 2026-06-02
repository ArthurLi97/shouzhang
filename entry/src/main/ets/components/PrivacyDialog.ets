// components/PrivacyDialog.ets
// 隐私弹窗：首次启动时展示，用户同意后才初始化数据库

import { PreferencesHelper } from '../database/PreferencesHelper';

@Component
export struct PrivacyDialog {
  onAgree?: () => void;
  onDisagree?: () => void;
  onPrivacyClick?: () => void;
  onAgreementClick?: () => void;

  build() {
    Column({ space: 16 }) {
      Text('欢迎使用 SnapSticker')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.ink_deep'))
        .width('100%')
        .textAlign(TextAlign.Center)

      Text('我们重视您的隐私保护。在使用本应用前，请您阅读并同意以下协议：')
        .fontSize(14)
        .fontColor($r('app.color.ink_mid'))
        .width('100%')
        .lineHeight(22)

      Row({ space: 4 }) {
        Text('《隐私政策》')
          .fontSize(14)
          .fontColor($r('app.color.brand_primary'))
          .onClick(() => { this.onPrivacyClick?.(); })
        Text('和')
          .fontSize(14)
          .fontColor($r('app.color.ink_mid'))
        Text('《用户协议》')
          .fontSize(14)
          .fontColor($r('app.color.brand_primary'))
          .onClick(() => { this.onAgreementClick?.(); })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)

      Text('我们将申请相机和相册权限以提供核心功能，所有数据处理均在本地完成。')
        .fontSize(12)
        .fontColor($r('app.color.ink_light'))
        .width('100%')
        .lineHeight(20)

      Row({ space: 12 }) {
        Button('不同意', { type: ButtonType.Capsule })
          .layoutWeight(1)
          .height(40)
          .backgroundColor($r('app.color.card_bg'))
          .fontColor($r('app.color.ink_mid'))
          .onClick(() => { this.onDisagree?.(); })

        Button('同意', { type: ButtonType.Capsule })
          .layoutWeight(1)
          .height(40)
          .backgroundColor($r('app.color.brand_primary'))
          .fontColor(Color.White)
          .onClick(() => { this.onAgree?.(); })
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .padding(24)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(20)
  }
}

export class PrivacyConsent {
  private static KEY = 'privacy_consented';

  static async hasConsented(): Promise<boolean> {
    return await PreferencesHelper.getInstance().getBoolean(PrivacyConsent.KEY, false);
  }

  static async setConsented(value: boolean): Promise<void> {
    await PreferencesHelper.getInstance().setBoolean(PrivacyConsent.KEY, value);
  }
}
