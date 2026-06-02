// pages/home/SettingsPage.ets

import { HdsActionBar } from '../../components/hds/HdsActionBar';
import { HdsListItem } from '../../components/hds/HdsListItem';

@Component
export struct SettingsPage {
  @Consume('homePathStack') pathStack: NavPathStack;

  build() {
    Column() {
      HdsActionBar({
        startButtons: [
          { icon: $r('sys.symbol.chevron_left'), action: () => { this.pathStack.pop(); } }
        ],
        primaryText: { text: '设置', fontSize: 18, fontWeight: FontWeight.Medium }
      })

      List() {
        ListItem() {
          HdsListItem({
            primaryText: '隐私政策',
            primaryTextFontSize: 16,
            showPrefixSymbol: true,
            primaryPrefixSymbol: $r('sys.symbol.lock'),
            suffixType: 'arrow'
          })
        }
        .onClick(() => { this.pathStack.pushPathByName('PrivacyPolicyPage', undefined); })

        ListItem() {
          HdsListItem({
            primaryText: '用户协议',
            primaryTextFontSize: 16,
            showPrefixSymbol: true,
            primaryPrefixSymbol: $r('sys.symbol.doc_text'),
            suffixType: 'arrow'
          })
        }
        .onClick(() => { this.pathStack.pushPathByName('UserAgreementPage', undefined); })

        ListItem() {
          HdsListItem({
            primaryText: '反馈与帮助',
            primaryTextFontSize: 16,
            showPrefixSymbol: true,
            primaryPrefixSymbol: $r('sys.symbol.questionmark_circle'),
            suffixType: 'arrow'
          })
        }

        ListItem() {
          HdsListItem({
            primaryText: '关于我们',
            primaryTextFontSize: 16,
            showPrefixSymbol: true,
            primaryPrefixSymbol: $r('sys.symbol.info_circle'),
            suffixType: 'arrow'
          })
        }
      }
      .divider({ strokeWidth: 0.5, color: $r('app.color.divider') })
      .margin({ top: 16 })
      .layoutWeight(1)
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(16)
      .margin(16)
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: '24vp' })
    .backgroundColor($r('app.color.bg_base'))
  }
}
