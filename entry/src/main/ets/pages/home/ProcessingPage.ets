// pages/home/ProcessingPage.ets

import { UriParam } from '../../models/PageParams';
import { ImageProcessor } from '../../utils/ImageProcessor';
import { common } from '@kit.AbilityKit';

@Component
export struct ProcessingPage {
  @Consume('rootPathStack') pathStack: NavPathStack;
  @State uri: string = '';
  @State stepText: string = '正在制作贴纸...';
  @State isCancelled: boolean = false;

  aboutToAppear(): void {
    const raw: object | null = this.pathStack.getParamByName('ProcessingPage') as object | null;
    if (raw) {
      const params: UriParam = raw as UriParam;
      this.uri = params.uri;
    }
    this.processImage();
  }

  aboutToDisappear(): void {
    this.isCancelled = true;
  }

  async processImage(): Promise<void> {
    try {
      this.stepText = '正在制作贴纸...';
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const processedUri = await ImageProcessor.processSticker(this.uri, context, 0);

      if (this.isCancelled) return;

      if (!processedUri) {
        this.stepText = '未检测到主体';
        setTimeout(() => {
          if (!this.isCancelled) {
            this.pathStack.replacePathByName('NoSubjectPage', undefined);
          }
        }, 800);
        return;
      }

      this.stepText = '生成完成';
      setTimeout(() => {
        if (!this.isCancelled) {
          const param: UriParam = { uri: processedUri };
          this.pathStack.replacePathByName('StickerPreviewPage', param);
        }
      }, 400);
    } catch (err) {
      console.error('processImage error:', err);
      this.stepText = '处理失败，请重试';
      setTimeout(() => {
        if (!this.isCancelled) {
          this.pathStack.pop();
        }
      }, 2000);
    }
  }

  build() {
    Column({ space: 24 }) {
      // 中间大图预览
      Stack() {
        Image(this.uri)
          .width('70%')
          .aspectRatio(1)
          .objectFit(ImageFit.Cover)
          .borderRadius(20)
          .shadow({ radius: 20, color: 'rgba(0,0,0,0.1)', offsetX: 0, offsetY: 8 })

        // 闪光装饰（用简单动画模拟）
        Column() {
          SymbolGlyph($r('sys.symbol.star'))
            .fontSize(24)
            .fontColor([$r('app.color.brand_primary')])
            .opacity(0.6)
        }
        .position({ x: '75%', y: '10%' })

        Column() {
          SymbolGlyph($r('sys.symbol.star'))
            .fontSize(16)
            .fontColor([$r('app.color.brand_primary')])
            .opacity(0.4)
        }
        .position({ x: '15%', y: '80%' })
      }
      .width('100%')

      // 文字提示
      Column({ space: 8 }) {
        Text(this.stepText)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.ink_deep'))

        Text('请稍候，大约需要1-3秒')
          .fontSize(12)
          .fontColor($r('app.color.ink_light'))
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.bg_base'))
  }
}
