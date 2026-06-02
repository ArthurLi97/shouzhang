// pages/home/SaveSuccessPage.ets

import { UriParam } from '../../models/PageParams';
import { ConfettiCanvas } from '../../components/ConfettiCanvas';

@Component
export struct SaveSuccessPage {
  @Consume('homePathStack') pathStack: NavPathStack;
  @State stickerUri: string = '';

  aboutToAppear(): void {
    const raw: object | null = this.pathStack.getParamByName('SaveSuccessPage') as object | null;
    if (raw) {
      const params: UriParam = raw as UriParam;
      this.stickerUri = params.uri;
    }
  }

  build() {
    Column({ space: 24 }) {
      ConfettiCanvas()
        .position({ x: 0, y: 0 })
        .width('100%')
        .height(200)

      Image(this.stickerUri)
        .width(240)
        .aspectRatio(1)
        .borderRadius(20)
        .shadow({ radius: 20, color: 'rgba(0,0,0,0.1)', offsetX: 0, offsetY: 8 })

      Text('已加入贴纸库！')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.ink_deep'))

      Text('你可以在贴纸库中找到它')
        .fontSize(14)
        .fontColor($r('app.color.ink_mid'))

      Button('查看贴纸库', { type: ButtonType.Capsule })
        .width('80%')
        .height(48)
        .backgroundColor($r('app.color.brand_primary'))
        .fontColor(Color.White)
        .onClick(() => { this.pathStack.clear(); })

      Text('再来一张')
        .fontSize(14)
        .fontColor($r('app.color.brand_primary'))
        .fontWeight(FontWeight.Medium)
        .onClick(() => {
          AppStorage.setOrCreate('auto_open_picker', true);
          this.pathStack.clear();
        })
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: '24vp' })
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.bg_base'))
  }
}
