// pages/home/UserAgreementPage.ets
// 用户协议页面

import { HdsActionBar } from '../../components/hds/HdsActionBar';

@Component
export struct UserAgreementPage {
  @Consume('homePathStack') pathStack: NavPathStack;

  build() {
    Column() {
      HdsActionBar({
        startButtons: [
          { icon: $r('sys.symbol.chevron_left'), action: () => { this.pathStack.pop(); } }
        ],
        primaryText: { text: '用户协议', fontSize: 18, fontWeight: FontWeight.Medium }
      })

      Scroll() {
        Column({ space: 16 }) {
          Text('MEMO 用户协议')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.ink_deep'))
            .width('100%')

          Text('最后更新日期：2026年6月1日')
            .fontSize(12)
            .fontColor($r('app.color.ink_light'))
            .width('100%')

          this.SectionTitle('1. 协议接受')
          this.SectionBody(
            '欢迎使用 MEMO！当您下载、安装或使用本应用时，即表示您已阅读并同意本用户协议的全部条款。' +
            '如您不同意本协议，请勿使用本应用。'
          )

          this.SectionTitle('2. 服务说明')
          this.SectionBody(
            'MEMO 是一款生活手账与贴纸创作工具，提供以下核心功能：\n' +
            '• 拍照/相册导入生成贴纸\n' +
            '• 贴纸库管理与分类浏览\n' +
            '• 画布创作与自由组合\n' +
            '• 作品导出与分享'
          )

          this.SectionTitle('3. 用户行为规范')
          this.SectionBody(
            '您承诺在使用本应用时遵守法律法规，不得利用本应用制作、传播违法违规内容。' +
            '您应对自己创作和分享的内容承担全部责任。'
          )

          this.SectionTitle('4. 知识产权')
          this.SectionBody(
            '您使用本应用创作的作品版权归您所有。本应用的软件著作权、商标权等知识产权归开发者所有。'
          )

          this.SectionTitle('5. 免责声明')
          this.SectionBody(
            '本应用按"现状"提供，开发者不对因使用本应用而导致的任何直接或间接损失承担责任，' +
            '除非该损失由开发者的故意或重大过失造成。'
          )

          this.SectionTitle('6. 协议变更')
          this.SectionBody(
            '开发者有权根据需要修改本协议。修改后的协议将在应用内公示，继续使用视为接受修改。'
          )
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: '24vp' })
    .backgroundColor($r('app.color.bg_base'))
  }

  @Builder
  SectionTitle(text: string): void {
    Text(text)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('app.color.ink_deep'))
      .width('100%')
      .margin({ top: 8 })
  }

  @Builder
  SectionBody(text: string): void {
    Text(text)
      .fontSize(14)
      .fontColor($r('app.color.ink_mid'))
      .width('100%')
      .lineHeight(22)
  }
}
