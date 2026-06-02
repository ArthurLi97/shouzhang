// pages/canvas/ExportPage.ets

import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { HdsSnackBar } from '../../components/hds/HdsSnackBar';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { PermissionManager } from '../../utils/PermissionManager';

@Component
export struct ExportPage {
  @Consume('canvasPathStack') pathStack: NavPathStack;
  @State canvasUri: string = '';

  aboutToAppear(): void {
    const params = this.pathStack.getParamByName('ExportPage') as object as Record<string, string>;
    this.canvasUri = params?.items as string ?? '';
  }

  async saveToAlbum(): Promise<void> {
    try {
      if (!this.canvasUri) {
        HdsSnackBar.show({ message: '没有可保存的图片' });
        return;
      }

      const context = this.getUIContext().getHostContext() as common.Context;
      const hasPermission = await PermissionManager.requestPhotoWritePermission(context);
      if (!hasPermission) return;

      const ph = photoAccessHelper.getPhotoAccessHelper(context);
      const asset = await ph.createAsset(photoAccessHelper.PhotoType.IMAGE, 'png');
      const srcPath = this.canvasUri.replace('file://', '');
      fileIo.copyFileSync(srcPath, asset);

      HdsSnackBar.show({ message: '已保存到相册', duration: 3000 });
    } catch (err) {
      console.error('saveToAlbum error:', JSON.stringify(err));
      HdsSnackBar.show({ message: '保存失败，请重试' });
    }
  }

  async share(): Promise<void> {
    try {
      if (!this.canvasUri) {
        HdsSnackBar.show({ message: '没有可分享的图片' });
        return;
      }
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.startAbility({
        action: 'ohos.want.action.SEND',
        type: 'image/png',
        uri: this.canvasUri,
      });
    } catch (err) {
      console.error('share error:', JSON.stringify(err));
      HdsSnackBar.show({ message: '分享失败' });
    }
  }

  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(24)
          .fontColor([$r('app.color.ink_deep')])
          .onClick(() => { this.pathStack.pop(); })

        Blank().layoutWeight(1)

        Text('导出')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.ink_deep'))

        Blank().layoutWeight(1)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      Image(this.canvasUri)
        .width('90%')
        .aspectRatio(4 / 5)
        .borderRadius(12)
        .shadow({ radius: 16, color: $r('app.color.shadow_float'), offsetX: 0, offsetY: 8 })
        .layoutWeight(1)
        .objectFit(ImageFit.Contain)

      Column({ space: 12 }) {
        Button('保存到相册', { type: ButtonType.Capsule })
          .width('90%')
          .height(48)
          .backgroundColor($r('app.color.brand_primary'))
          .fontColor(Color.White)
          .onClick(() => { this.saveToAlbum(); })

        Button('分享', { type: ButtonType.Capsule })
          .width('90%')
          .height(48)
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.ink_mid'))
          .border({ width: 1, color: $r('app.color.divider') })
          .onClick(() => { this.share(); })
      }
      .padding({ bottom: '56vp', top: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_base'))
  }
}
