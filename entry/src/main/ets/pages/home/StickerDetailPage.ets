// pages/home/StickerDetailPage.ets

import { Sticker } from '../../models/Sticker';
import { RdbHelper } from '../../database/RdbHelper';
import { IdParam } from '../../models/PageParams';
import { HdsSnackBar } from '../../components/hds/HdsSnackBar';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';

@Component
export struct StickerDetailPage {
  @Consume('homePathStack') pathStack: NavPathStack;
  @State sticker: Sticker | null = null;
  @State showMoreMenu: boolean = false;
  private db: RdbHelper = RdbHelper.getInstance();

  aboutToAppear(): void {
    const raw: object | null = this.pathStack.getParamByName('StickerDetailPage') as object | null;
    if (raw) {
      const params: IdParam = raw as IdParam;
      if (params.id) {
        this.loadSticker(params.id);
      }
    }
  }

  async loadSticker(id: number): Promise<void> {
    try {
      this.sticker = await this.db.getStickerById(id);
    } catch (err) {
      console.error('loadSticker error:', JSON.stringify(err));
      HdsSnackBar.show({ message: '加载贴纸失败' });
    }
  }

  confirmDelete(): void {
    promptAction.showDialog({
      title: '删除贴纸',
      message: '确定要删除这张贴纸吗？此操作不可恢复。',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '删除', color: '#FF3B30' }
      ]
    }).then(async (data) => {
      if (data.index === 1 && this.sticker) {
        await this.db.deleteSticker(this.sticker.id);
        HdsSnackBar.show({ message: '已删除' });
        this.pathStack.pop();
      }
    }).catch(() => {});
  }

  async shareSticker(): Promise<void> {
    if (!this.sticker) return;
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.startAbility({
        action: 'ohos.want.action.SEND',
        type: 'image/png',
        uri: this.sticker.uri,
      });
    } catch (err) {
      console.error('shareSticker error:', JSON.stringify(err));
      HdsSnackBar.show({ message: '分享失败' });
    }
  }

  addToCanvas(): void {
    if (!this.sticker) return;
    AppStorage.setOrCreate('pending_canvas_sticker', this.sticker.uri);
    HdsSnackBar.show({ message: '已加入画布，请切换到创作板' });
  }

  formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    return `${date.getFullYear()}.${(date.getMonth() + 1).toString().padStart(2, '0')}.${date.getDate().toString().padStart(2, '0')}`;
  }

  build() {
    Column() {
      // 顶部操作栏
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([$r('app.color.ink_deep')])
          .onClick(() => { this.pathStack.pop(); })

        Blank().layoutWeight(1)

        Text('贴纸详情')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.ink_deep'))

        Blank().layoutWeight(1)

        SymbolGlyph($r('sys.symbol.gearshape'))
          .fontSize(24)
          .fontColor([$r('app.color.ink_deep')])
          .onClick(() => { this.showMoreMenu = true; })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      if (this.sticker) {
        // 大图预览
        Image(this.sticker.uri)
          .width('90%')
          .layoutWeight(1)
          .objectFit(ImageFit.Contain)
          .borderRadius(16)

        // 信息卡片
        Column({ space: 0 }) {
          // 创建时间
          Row({ space: 8 }) {
            SymbolGlyph($r('sys.symbol.calendar'))
              .fontSize(16)
              .fontColor([$r('app.color.ink_light')])
            Text('创建时间')
              .fontSize(14)
              .fontColor($r('app.color.ink_mid'))
              .layoutWeight(1)
            Text(this.formatDate(this.sticker.createdAt))
              .fontSize(14)
              .fontColor($r('app.color.ink_deep'))
          }
          .width('100%')
          .padding({ top: 14, bottom: 14 })

          Divider().strokeWidth(0.5).color($r('app.color.divider'))

          // 分类
          Row({ space: 8 }) {
            SymbolGlyph($r('sys.symbol.doc_text'))
              .fontSize(16)
              .fontColor([$r('app.color.ink_light')])
            Text('分类')
              .fontSize(14)
              .fontColor($r('app.color.ink_mid'))
              .layoutWeight(1)
            Text(this.sticker.category)
              .fontSize(14)
              .fontColor($r('app.color.ink_deep'))
          }
          .width('100%')
          .padding({ top: 14, bottom: 14 })

          Divider().strokeWidth(0.5).color($r('app.color.divider'))

          // 收藏数
          Row({ space: 8 }) {
            SymbolGlyph($r('sys.symbol.heart'))
              .fontSize(16)
              .fontColor([$r('app.color.ink_light')])
            Text('收藏')
              .fontSize(14)
              .fontColor($r('app.color.ink_mid'))
              .layoutWeight(1)
            Text('12')
              .fontSize(14)
              .fontColor($r('app.color.ink_deep'))
          }
          .width('100%')
          .padding({ top: 14, bottom: 14 })

          Divider().strokeWidth(0.5).color($r('app.color.divider'))

          // 编辑贴纸效果
          Row({ space: 8 }) {
            SymbolGlyph($r('sys.symbol.paintbrush'))
              .fontSize(16)
              .fontColor([$r('app.color.ink_light')])
            Text('编辑贴纸效果')
              .fontSize(14)
              .fontColor($r('app.color.ink_deep'))
              .layoutWeight(1)
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(14)
              .fontColor([$r('app.color.ink_light')])
          }
          .width('100%')
          .padding({ top: 14, bottom: 14 })
          .onClick(() => {
            const param: IdParam = { id: this.sticker!.id };
            HdsSnackBar.show({ message: '功能开发中' });
          })

          Divider().strokeWidth(0.5).color($r('app.color.divider'))

          // 加入画布
          Row({ space: 8 }) {
            SymbolGlyph($r('sys.symbol.plus'))
              .fontSize(16)
              .fontColor([$r('app.color.ink_light')])
            Text('加入画布')
              .fontSize(14)
              .fontColor($r('app.color.ink_deep'))
              .layoutWeight(1)
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(14)
              .fontColor([$r('app.color.ink_light')])
          }
          .width('100%')
          .padding({ top: 14, bottom: 14 })
          .onClick(() => { this.addToCanvas(); })

          Divider().strokeWidth(0.5).color($r('app.color.divider'))

          // 删除贴纸
          Row({ space: 8 }) {
            SymbolGlyph($r('sys.symbol.trash'))
              .fontSize(16)
              .fontColor(['#FF3B30'])
            Text('删除贴纸')
              .fontSize(14)
              .fontColor('#FF3B30')
              .layoutWeight(1)
          }
          .width('100%')
          .padding({ top: 14, bottom: 14 })
          .onClick(() => { this.confirmDelete(); })
        }
        .padding(16)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius({ topLeft: 20, topRight: 20 })
        .shadow({ radius: 16, color: $r('app.color.shadow_float'), offsetX: 0, offsetY: -4 })
      }
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: '24vp' })
    .backgroundColor($r('app.color.bg_base'))
    .bindSheet(this.showMoreMenu, this.MoreMenuBuilder(), {
      height: 300,
      showClose: false,
      backgroundColor: 'rgba(255,255,255,0.95)',
    })
  }

  @Builder
  MoreMenuBuilder(): void {
    Column({ space: 0 }) {
      Text('更多')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.ink_deep'))
        .margin({ top: 16, bottom: 8 })
        .width('100%')
        .textAlign(TextAlign.Center)

      Divider().strokeWidth(0.5).color($r('app.color.divider'))

      List() {
        ListItem() {
          Row({ space: 12 }) {
            SymbolGlyph($r('sys.symbol.gearshape'))
              .fontSize(20)
              .fontColor([$r('app.color.ink_deep')])
            Text('设置')
              .fontSize(16)
              .fontColor($r('app.color.ink_deep'))
              .layoutWeight(1)
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(14)
              .fontColor([$r('app.color.ink_light')])
          }
          .width('100%')
          .padding(16)
        }
        .onClick(() => {
          this.showMoreMenu = false;
          this.pathStack.pushPathByName('SettingsPage', undefined);
        })

        ListItem() {
          Row({ space: 12 }) {
            SymbolGlyph($r('sys.symbol.lock'))
              .fontSize(20)
              .fontColor([$r('app.color.ink_deep')])
            Text('隐私政策')
              .fontSize(16)
              .fontColor($r('app.color.ink_deep'))
              .layoutWeight(1)
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(14)
              .fontColor([$r('app.color.ink_light')])
          }
          .width('100%')
          .padding(16)
        }
        .onClick(() => {
          this.showMoreMenu = false;
          this.pathStack.pushPathByName('PrivacyPolicyPage', undefined);
        })

        ListItem() {
          Row({ space: 12 }) {
            SymbolGlyph($r('sys.symbol.doc_text'))
              .fontSize(20)
              .fontColor([$r('app.color.ink_deep')])
            Text('用户协议')
              .fontSize(16)
              .fontColor($r('app.color.ink_deep'))
              .layoutWeight(1)
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(14)
              .fontColor([$r('app.color.ink_light')])
          }
          .width('100%')
          .padding(16)
        }
        .onClick(() => {
          this.showMoreMenu = false;
          this.pathStack.pushPathByName('UserAgreementPage', undefined);
        })

        ListItem() {
          Row({ space: 12 }) {
            SymbolGlyph($r('sys.symbol.info_circle'))
              .fontSize(20)
              .fontColor([$r('app.color.ink_deep')])
            Text('关于我们')
              .fontSize(16)
              .fontColor($r('app.color.ink_deep'))
              .layoutWeight(1)
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(14)
              .fontColor([$r('app.color.ink_light')])
          }
          .width('100%')
          .padding(16)
        }
      }
      .divider({ strokeWidth: 0.5, color: $r('app.color.divider') })
      .layoutWeight(1)

      Button('取消', { type: ButtonType.Capsule })
        .width('80%')
        .height(44)
        .backgroundColor($r('app.color.card_bg'))
        .fontColor($r('app.color.ink_mid'))
        .margin({ bottom: 16 })
        .onClick(() => { this.showMoreMenu = false; })
    }
    .width('100%')
    .height('100%')
  }
}
