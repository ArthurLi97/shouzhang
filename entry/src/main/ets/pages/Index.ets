// pages/Index.ets

import { HomeNavStack } from './home/HomeNavStack';
import { CanvasNavStack } from './canvas/CanvasNavStack';
import { RdbHelper } from '../database/RdbHelper';
import { PreferencesHelper } from '../database/PreferencesHelper';
import { deviceInfo } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { PrivacyDialog, PrivacyConsent } from '../components/PrivacyDialog';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { cameraPicker } from '@kit.CameraKit';
import { camera } from '@kit.CameraKit';
import { PermissionManager } from '../utils/PermissionManager';
import { HdsSnackBar } from '../components/hds/HdsSnackBar';
import {
  HdsTabs,
  HdsTabsController,
} from '@kit.UIDesignKit';

type PrivacyViewMode = 'dialog' | 'privacy' | 'agreement';

@Entry
@Component
struct RootPage {
  private tabController: HdsTabsController = new HdsTabsController();
  @State activeTab: number = 0;
  @State previousTab: number = 0;
  @StorageLink('tab_bar_height') tabBarHeight: number = 60;
  @StorageLink('editor_exit') @Watch('onEditorExitChange') editorExit: boolean = false;
  @State useApi23: boolean = false;
  @State showPrivacyDialog: boolean = false;
  @State privacyChecked: boolean = false;
  @State privacyViewMode: PrivacyViewMode = 'dialog';
  @State showPickerSheet: boolean = false;

  aboutToAppear(): void {
    this.useApi23 = deviceInfo.sdkApiVersion >= 23;
    this.initializeApp();
  }

  async initializeApp(): Promise<void> {
    const context = this.getUIContext().getHostContext() as common.Context;
    await RdbHelper.getInstance().init(context);
    await PreferencesHelper.getInstance().init(context);
    const consented = await PrivacyConsent.hasConsented();
    if (consented) {
      this.privacyChecked = true;
    } else {
      this.showPrivacyDialog = true;
    }
  }

  onEditorExitChange(): void {
    if (this.editorExit) {
      this.editorExit = false;
      this.previousTab = this.activeTab;
      this.activeTab = 0;
      this.tabController.changeIndex(0);
    }
  }

  onPrivacyAgree(): void {
    this.showPrivacyDialog = false;
    PrivacyConsent.setConsented(true);
    this.privacyChecked = true;
  }

  onPrivacyDisagree(): void {
    this.showPrivacyDialog = false;
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    try {
      context.terminateSelf();
    } catch (err) {
      console.error('terminateSelf error:', JSON.stringify(err));
    }
  }

  build() {
    Stack() {
      if (this.privacyChecked) {
        HdsTabs({ controller: this.tabController }) {
          TabContent() {
            HomeNavStack()
          }
          .tabBar(this.TabBarBuilder('贴纸库', $r('sys.symbol.house'), 0))

          TabContent() {
            Column() {}
          }
          .tabBar(this.CameraTabBuilder())

          TabContent() {
            CanvasNavStack()
          }
          .tabBar(this.TabBarBuilder('创作板', $r('sys.symbol.paintbrush'), 2))
        }
        .barPosition(BarPosition.End)
        .vertical(false)
        .barMode(BarMode.Fixed)
        .barHeight(this.activeTab === 2 ? 0 : this.tabBarHeight)
        .barOverlap(true)
        .scrollable(this.activeTab !== 2)

        .onChange((index: number) => {
          if (index === 1) {
            this.showPickerSheet = true;
            this.tabController.changeIndex(this.activeTab);
            return;
          }
          this.previousTab = this.activeTab;
          this.activeTab = index;
        })
        .backgroundColor($r('app.color.bg_base'))
      }

      if (this.showPrivacyDialog) {
        Column() {
          Blank()
            .backgroundColor('rgba(0,0,0,0.5)')
            .layoutWeight(1)
            .width('100%')

          if (this.privacyViewMode === 'dialog') {
            PrivacyDialog({
              onAgree: () => { this.onPrivacyAgree(); },
              onDisagree: () => { this.onPrivacyDisagree(); },
              onPrivacyClick: () => { this.privacyViewMode = 'privacy'; },
              onAgreementClick: () => { this.privacyViewMode = 'agreement'; }
            })
            .padding(24)
          } else {
            this.PrivacyContentBuilder()
          }
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
    .bindSheet(this.showPickerSheet, this.PickerSheetBuilder(), {
      height: 240,
      showClose: false,
      backgroundColor: 'rgba(255,255,255,0.95)',
    })
  }

  @Builder
  PrivacyContentBuilder(): void {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([$r('app.color.ink_deep')])
          .onClick(() => { this.privacyViewMode = 'dialog'; })
        Text(this.privacyViewMode === 'privacy' ? '隐私政策' : '用户协议')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.ink_deep'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Blank().width(24)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      Scroll() {
        Column({ space: 16 }) {
          Text(this.privacyViewMode === 'privacy' ? 'SnapSticker 隐私政策' : 'SnapSticker 用户协议')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.ink_deep'))
            .width('100%')

          Text('最后更新日期：2026年6月1日')
            .fontSize(12)
            .fontColor($r('app.color.ink_light'))
            .width('100%')

          if (this.privacyViewMode === 'privacy') {
            this.SectionTitle('1. 我们收集的信息')
            this.SectionBody(
              '当您使用 SnapSticker 时，我们可能会收集以下信息：\n' +
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
          } else {
            this.SectionTitle('1. 协议接受')
            this.SectionBody(
              '欢迎使用 SnapSticker！当您下载、安装或使用本应用时，即表示您已阅读并同意本用户协议的全部条款。' +
              '如您不同意本协议，请勿使用本应用。'
            )
            this.SectionTitle('2. 服务说明')
            this.SectionBody(
              'SnapSticker 是一款生活贴纸收集与创作工具，提供以下核心功能：\n' +
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
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)

      Row({ space: 12 }) {
        Button('不同意', { type: ButtonType.Capsule })
          .layoutWeight(1)
          .height(44)
          .backgroundColor($r('app.color.card_bg'))
          .fontColor($r('app.color.ink_mid'))
          .onClick(() => { this.onPrivacyDisagree(); })

        Button('同意', { type: ButtonType.Capsule })
          .layoutWeight(1)
          .height(44)
          .backgroundColor($r('app.color.brand_primary'))
          .fontColor(Color.White)
          .onClick(() => { this.onPrivacyAgree(); })
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .height('100%')
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

  @Builder
  TabBarBuilder(title: string, icon: Resource, index: number): void {
    Column({ space: 4 }) {
      SymbolGlyph(icon)
        .fontSize(22)
        .fontColor([
          this.activeTab === index
            ? $r('app.color.brand_primary')
            : $r('app.color.ink_mid')
        ])
      Text(title)
        .fontSize(10)
        .fontColor(
          this.activeTab === index
            ? $r('app.color.brand_primary')
            : $r('app.color.ink_mid')
        )
        .fontWeight(this.activeTab === index ? FontWeight.Medium : FontWeight.Normal)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 6, bottom: 6 })
  }

  @Builder
  CameraTabBuilder(): void {
    Column({ space: 4 }) {
      Stack() {
        SymbolGlyph($r('sys.symbol.camera'))
          .fontSize(26)
          .fontColor([Color.White])
      }
      .width(52)
      .height(52)
      .backgroundColor($r('app.color.brand_primary'))
      .borderRadius(26)
      .shadow({
        radius: 10,
        color: 'rgba(255, 138, 128, 0.4)',
        offsetX: 0,
        offsetY: 3
      })

      Text('拍照')
        .fontSize(10)
        .fontColor($r('app.color.ink_mid'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 2, bottom: 6 })
  }

  async onPickFromAlbum(): Promise<void> {
    this.showPickerSheet = false;
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const hasPermission = await PermissionManager.requestPhotoReadPermission(context);
    if (!hasPermission) return;

    const picker = new photoAccessHelper.PhotoViewPicker();
    try {
      const result = await picker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1,
      });
      if (result.photoUris && result.photoUris.length > 0) {
        AppStorage.setOrCreate('pending_photo_uri', result.photoUris[0]);
        this.tabController.changeIndex(0);
      }
    } catch (err) {
      const code = (err as Error)?.message ?? '';
      if (!code.includes('cancel') && !code.includes('Cancel')) {
        console.error('PhotoViewPicker error:', JSON.stringify(err));
        HdsSnackBar.show({ message: '选择图片失败，请重试' });
      }
    }
  }

  async onTakePhoto(): Promise<void> {
    this.showPickerSheet = false;
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const hasPermission = await PermissionManager.requestCameraPermission(context);
    if (!hasPermission) return;

    try {
      const result = await cameraPicker.pick(context, [cameraPicker.PickerMediaType.PHOTO], {
        cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK,
      });
      if (result.resultCode === 0 && result.resultUri) {
        AppStorage.setOrCreate('pending_photo_uri', result.resultUri);
        this.tabController.changeIndex(0);
      }
    } catch (err) {
      const code = (err as Error)?.message ?? '';
      if (!code.includes('cancel') && !code.includes('Cancel')) {
        console.error('cameraPicker error:', JSON.stringify(err));
        HdsSnackBar.show({ message: '拍照失败，请重试' });
      }
    }
  }

  @Builder
  PickerSheetBuilder(): void {
    Column({ space: 16 }) {
      Text('新建贴纸')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.ink_deep'))
        .margin({ top: 8 })

      Row({ space: 24 }) {
        Column({ space: 8 }) {
          Stack() {
            SymbolGlyph($r('sys.symbol.camera'))
              .fontSize(32)
              .fontColor([$r('app.color.brand_primary')])
          }
          .width(64)
          .height(64)
          .backgroundColor($r('app.color.brand_primary_light'))
          .borderRadius(32)

          Text('拍照')
            .fontSize(14)
            .fontColor($r('app.color.ink_mid'))
        }
        .onClick(() => { this.onTakePhoto(); })

        Column({ space: 8 }) {
          Stack() {
            SymbolGlyph($r('sys.symbol.camera_fill'))
              .fontSize(32)
              .fontColor([$r('app.color.brand_primary')])
          }
          .width(64)
          .height(64)
          .backgroundColor($r('app.color.brand_primary_light'))
          .borderRadius(32)

          Text('相册')
            .fontSize(14)
            .fontColor($r('app.color.ink_mid'))
        }
        .onClick(() => { this.onPickFromAlbum(); })
      }
      .margin({ top: 8, bottom: 16 })

      Button('取消', { type: ButtonType.Capsule })
        .width('80%')
        .height(44)
        .backgroundColor($r('app.color.card_bg'))
        .fontColor($r('app.color.ink_mid'))
        .onClick(() => { this.showPickerSheet = false; })
    }
    .width('100%')
    .padding(16)
  }
}
