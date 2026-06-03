// pages/home/PrivacyPolicyPage.ets
// 隐私政策页面

import { HdsActionBar } from '../../components/hds/HdsActionBar';

@Component
export struct PrivacyPolicyPage {
  @Consume('homePathStack') pathStack: NavPathStack;

  build() {
    Column() {
      HdsActionBar({
        startButtons: [
          { icon: $r('sys.symbol.chevron_left'), action: () => { this.pathStack.pop(); } }
        ],
        primaryText: { text: '隐私政策', fontSize: 18, fontWeight: FontWeight.Medium }
      })

      Scroll() {
        Column({ space: 16 }) {
          Text('MEMO 隐私政策')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.ink_deep'))
            .width('100%')

          Text('最后更新日期：2026年6月1日')
            .fontSize(12)
            .fontColor($r('app.color.ink_light'))
            .width('100%')

          this.SectionTitle('1. 我们收集的信息')
          this.SectionBody(
            '当您使用 MEMO 时，我们可能会收集以下信息：\n' +
            '• 图片数据：您拍摄或从相册选择的照片，用于生成贴纸。\n' +
            '• 创作内容：您在画布中组合的贴纸、文字和背景配置。\n' +
            '• 设备信息：用于优化应用性能和兼容性。'
          )

          this.SectionTitle('2. 权限说明')
          this.SectionBody(
            '应用需要以下权限以提供核心功能：\n' +
            '• 相机权限：用于拍摄照片生成贴纸。\n' +
            '• 读取相册权限：用于从相册选择图片。\n' +
            '• 写入相册权限：用于保存贴纸和作品到系统相册。\n\n' +
            '以上权限仅在您主动使用时申请，不会后台静默调用。'
          )

          this.SectionTitle('3. 数据存储')
          this.SectionBody(
            '您的所有数据（包括贴纸、画布作品）均存储在设备本地，不会上传至任何服务器。' +
            '您随时可以删除应用以清除所有本地数据。'
          )

          this.SectionTitle('4. 数据安全')
          this.SectionBody(
            '我们采用业界标准的安全措施保护您的数据。所有图片处理均在本地完成，' +
            '不会将您的照片传输到第三方服务。'
          )

          this.SectionTitle('5. 联系我们')
          this.SectionBody(
            '如您对隐私政策有任何疑问，请通过「设置」→「反馈与帮助」与我们联系。'
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
