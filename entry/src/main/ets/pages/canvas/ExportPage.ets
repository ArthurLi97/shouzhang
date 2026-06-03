// pages/canvas/ExportPage.ets
// 导出页 — 保存到相册 + 保存到手账

import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { HdsSnackBar } from '../../components/hds/HdsSnackBar';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { PermissionManager } from '../../utils/PermissionManager';
import { RdbHelper } from '../../database/RdbHelper';
import { CanvasItem } from '../../models/CanvasItem';

@Component
export struct ExportPage {
  @Consume('rootPathStack') pathStack: NavPathStack;
  @State canvasUri: string = '';
  @State stage: 'saving' | 'saved' | 'error' = 'saving';
  @State progress: number = 0;
  @State saveToJournal: boolean = false;

  aboutToAppear(): void {
    const params = this.pathStack.getParamByName('ExportPage') as object as Record<string, string>;
    this.canvasUri = params?.items as string ?? '';
    this.startSave();
  }

  async startSave(): Promise<void> {
    if (!this.canvasUri) {
      this.stage = 'error';
      return;
    }

    // 模拟进度动画
    const interval = setInterval(() => {
      if (this.progress < 90) {
        this.progress += 10;
      }
    }, 150);

    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      const hasPermission = await PermissionManager.requestPhotoWritePermission(context);
      if (!hasPermission) {
        clearInterval(interval);
        this.stage = 'error';
        return;
      }

      const ph = photoAccessHelper.getPhotoAccessHelper(context);
      const asset = await ph.createAsset(photoAccessHelper.PhotoType.IMAGE, 'png');
      const srcPath = this.canvasUri.replace('file://', '');
      fileIo.copyFileSync(srcPath, asset);

      clearInterval(interval);
      this.progress = 100;
      this.stage = 'saved';
    } catch (err) {
      clearInterval(interval);
      console.error('startSave error:', JSON.stringify(err));
      this.stage = 'error';
    }
  }

  async saveAsJournal(): Promise<void> {
    if (!this.canvasUri) return;
    try {
      const db = RdbHelper.getInstance();
      const params = this.pathStack.getParamByName('ExportPage') as object as Record<string, string>;
      const bgStr = params?.background ?? '{}';
      await db.insertCanvasProject({
        title: `手账 ${new Date().toLocaleDateString()}`,
        thumbnailUri: this.canvasUri,
        items: [] as CanvasItem[],
        background: JSON.parse(bgStr),
        createdAt: Date.now(),
        updatedAt: Date.now(),
      });
      HdsSnackBar.show({ message: '已保存到手账' });
    } catch (err) {
      console.error('saveAsJournal error:', JSON.stringify(err));
      HdsSnackBar.show({ message: '保存失败' });
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

      // 预览图
      Image(this.canvasUri)
        .width('85%')
        .aspectRatio(4 / 5)
        .borderRadius(16)
        .shadow({ radius: 16, color: 'rgba(0,0,0,0.08)', offsetY: 8 })
        .layoutWeight(1)
        .objectFit(ImageFit.Contain)

      // 状态区域
      Column({ space: 16 }) {
        if (this.stage === 'saving') {
          Column({ space: 8 }) {
            Progress({ value: this.progress, total: 100, type: ProgressType.Ring })
              .width(48)
              .height(48)
              .color($r('app.color.brand_primary'))
              .backgroundColor($r('app.color.brand_primary_light'))

            Text(`正在生成图片... ${this.progress}%`)
              .fontSize(14)
              .fontColor($r('app.color.ink_mid'))
          }
        } else if (this.stage === 'saved') {
          Column({ space: 12 }) {
            SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
              .fontSize(48)
              .fontColor([$r('app.color.brand_primary')])

            Text('已保存到相册')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.ink_deep'))

            Button('保存到手账', { type: ButtonType.Capsule })
              .width('90%')
              .height(44)
              .backgroundColor($r('app.color.brand_primary_light'))
              .fontColor($r('app.color.brand_primary'))
              .onClick(() => { this.saveAsJournal(); })

            Button('完成', { type: ButtonType.Capsule })
              .width('90%')
              .height(44)
              .backgroundColor($r('app.color.card_bg'))
              .fontColor($r('app.color.ink_mid'))
              .onClick(() => { this.pathStack.pop(); })
          }
        } else {
          Column({ space: 8 }) {
            Text('保存失败')
              .fontSize(16)
              .fontColor('#FF3B30')

            Button('重试', { type: ButtonType.Capsule })
              .width('60%')
              .height(44)
              .backgroundColor($r('app.color.brand_primary'))
              .fontColor(Color.White)
              .onClick(() => {
                this.stage = 'saving';
                this.progress = 0;
                this.startSave();
              })
          }
        }
      }
      .padding({ bottom: 32, top: 16 })
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_base'))
  }
}
