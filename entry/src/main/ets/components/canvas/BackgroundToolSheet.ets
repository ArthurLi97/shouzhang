// components/canvas/BackgroundToolSheet.ets

import { BackgroundConfig } from '../../models/BackgroundConfig';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { PermissionManager } from '../../utils/PermissionManager';
import { HdsSnackBar } from '../../components/hds/HdsSnackBar';
import { common } from '@kit.AbilityKit';

@Component
export struct BackgroundToolSheet {
  onChangeBackground?: (config: BackgroundConfig) => void;
  @State activeTab: number = 0;
  private colors: string[] = ['#FFFFFF', '#F8F8F6', '#FFE4E1', '#E0F7FA', '#F0EDFF', '#FFF8E1', '#1A1A1A'];
  private textures: string[] = ['网格', '点阵', '纸张', '磨砂'];
  private patterns: string[] = ['波点', '条纹', '方格', '斜纹'];

  async pickBgImage(): Promise<void> {
    // 权限检查
    const context = this.getUIContext().getHostContext() as common.Context;
    const hasPermission = await PermissionManager.requestPhotoReadPermission(context);
    if (!hasPermission) return;

    const picker = new photoAccessHelper.PhotoViewPicker();
    try {
      const result = await picker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1,
      });
      if (result.photoUris && result.photoUris.length > 0) {
        this.onChangeBackground?.({ type: 'image', value: result.photoUris[0] });
      }
    } catch (err) {
      const code = (err as Error)?.message ?? '';
      if (!code.includes('cancel') && !code.includes('Cancel')) {
        console.error('PhotoViewPicker error:', JSON.stringify(err));
        HdsSnackBar.show({ message: '选择图片失败，请重试' });
      }
    }
  }

  build() {
    Column({ space: 0 }) {
      // 标签切换
      Row() {
        ForEach(['颜色', '纹理', '图案', '图片'], (tab: string, index: number) => {
          Text(tab)
            .fontSize(14)
            .fontWeight(this.activeTab === index ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(this.activeTab === index ? $r('app.color.brand_primary') : $r('app.color.ink_mid'))
            .backgroundColor(this.activeTab === index ? $r('app.color.brand_primary_light') : Color.Transparent)
            .padding({ top: 4, bottom: 4, left: 12, right: 12 })
            .borderRadius(12)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .onClick(() => { this.activeTab = index; })
        })
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })

      // 颜色页
      if (this.activeTab === 0) {
        Row({ space: 12 }) {
          ForEach(this.colors, (color: string) => {
            Stack()
              .width(40)
              .height(40)
              .backgroundColor(color)
              .borderRadius(20)
              .border({ width: 2, color: $r('app.color.divider') })
              .onClick(() => {
                this.onChangeBackground?.({ type: 'color', value: color });
              })
          })
        }
        .width('100%')
        .padding(16)
        .justifyContent(FlexAlign.Center)
      }

      // 纹理页
      if (this.activeTab === 1) {
        Row({ space: 16 }) {
          ForEach(this.textures, (name: string) => {
            Column({ space: 8 }) {
              Stack()
                .width(64)
                .height(64)
                .backgroundColor($r('app.color.card_bg'))
                .borderRadius(12)
                .border({ width: 1, color: $r('app.color.divider') })
              Text(name)
                .fontSize(12)
                .fontColor($r('app.color.ink_mid'))
            }
            .onClick(() => {
              // 纹理直接映射到 CanvasBackground 支持的绘制类型
              const typeMap: Record<string, 'color' | 'grid' | 'dot' | 'paper' | 'matte' | 'pattern' | 'image'> = {
                '网格': 'grid',
                '点阵': 'dot',
                '纸张': 'paper',
                '磨砂': 'matte'
              };
              this.onChangeBackground?.({ type: typeMap[name] || 'color', value: name });
            })
          })
        }
        .width('100%')
        .padding(16)
        .justifyContent(FlexAlign.Center)
      }

      // 图案页
      if (this.activeTab === 2) {
        Row({ space: 16 }) {
          ForEach(this.patterns, (name: string) => {
            Column({ space: 8 }) {
              Stack()
                .width(64)
                .height(64)
                .backgroundColor($r('app.color.brand_primary_light'))
                .borderRadius(12)
                .border({ width: 1, color: $r('app.color.divider') })
              Text(name)
                .fontSize(12)
                .fontColor($r('app.color.ink_mid'))
            }
            .onClick(() => {
              this.onChangeBackground?.({ type: 'pattern', value: name });
            })
          })
        }
        .width('100%')
        .padding(16)
        .justifyContent(FlexAlign.Center)
      }

      // 图片页
      if (this.activeTab === 3) {
        Column({ space: 12 }) {
          Button('从相册选择', { type: ButtonType.Capsule })
            .width('80%')
            .height(40)
            .backgroundColor($r('app.color.brand_primary'))
            .fontColor(Color.White)
            .onClick(() => { this.pickBgImage(); })
        }
        .width('100%')
        .padding(16)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .padding({ bottom: 16 })
    .backgroundColor('rgba(255,255,255,0.85)')
    .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
    .borderRadius({ topLeft: 20, topRight: 20 })
  }
}
