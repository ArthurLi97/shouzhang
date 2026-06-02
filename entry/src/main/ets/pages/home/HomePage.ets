// pages/home/HomePage.ets

import { Sticker } from '../../models/Sticker';
import { RdbHelper } from '../../database/RdbHelper';
import { StickerGrid } from '../../components/StickerGrid';
import { EmptyStateView } from '../../components/EmptyStateView';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { cameraPicker } from '@kit.CameraKit';
import { camera } from '@kit.CameraKit';
import { UriParam, IdParam } from '../../models/PageParams';
import { HdsSnackBar } from '../../components/hds/HdsSnackBar';
import { PermissionManager } from '../../utils/PermissionManager';
import { common } from '@kit.AbilityKit';

@Component
export struct HomePage {
  @Consume('homePathStack') pathStack: NavPathStack;
  @State stickerList: Sticker[] = [];
  @State isLoading: boolean = true;
  private db: RdbHelper = RdbHelper.getInstance();
  @State showPickerSheet: boolean = false;
  @StorageLink('pending_photo_uri') @Watch('onPendingPhotoChanged') pendingPhotoUri: string = '';
  private photoUriToProcess: string = '';

  aboutToAppear(): void {
    this.loadStickers();
    this.checkAutoOpenPicker();
    this.processPendingUri();
  }

  onPageShow(): void {
    this.loadStickers();
    this.checkAutoOpenPicker();
    this.processPendingUri();
  }

  onPendingPhotoChanged(): void {
    if (this.pendingPhotoUri) {
      this.photoUriToProcess = this.pendingPhotoUri;
      this.processPendingUri();
    }
  }

  processPendingUri(): void {
    if (this.photoUriToProcess) {
      try {
        const uri = this.photoUriToProcess;
        const param: UriParam = { uri };
        this.pathStack.pushPathByName('ProcessingPage', param);
        this.photoUriToProcess = '';
        this.pendingPhotoUri = '';
      } catch (err) {
        console.error('processPendingUri error:', JSON.stringify(err));
      }
    }
  }

  checkAutoOpenPicker(): void {
    const shouldOpen = AppStorage.get<boolean>('auto_open_picker');
    if (shouldOpen) {
      AppStorage.delete('auto_open_picker');
      this.showPickerSheet = true;
    }
  }

  private loadVersion: number = 0;

  async loadStickers(): Promise<void> {
    this.isLoading = true;
    try {
      const version = ++this.loadVersion;
      const list = await this.db.getStickers(undefined);
      if (version === this.loadVersion) {
        this.stickerList = list;
      }
    } catch (err) {
      console.error('loadStickers error:', JSON.stringify(err));
      HdsSnackBar.show({ message: '加载失败，请重试' });
    } finally {
      this.isLoading = false;
    }
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
        const param: UriParam = { uri: result.photoUris[0] };
        this.pathStack.pushPathByName('ProcessingPage', param);
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
        const param: UriParam = { uri: result.resultUri };
        this.pathStack.pushPathByName('ProcessingPage', param);
      }
    } catch (err) {
      const code = (err as Error)?.message ?? '';
      if (!code.includes('cancel') && !code.includes('Cancel')) {
        console.error('cameraPicker error:', JSON.stringify(err));
        HdsSnackBar.show({ message: '拍照失败，请重试' });
      }
    }
  }

  build() {
    Column() {
      // 顶部操作栏
      Row() {
        Text('SnapSticker')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.ink_deep'))

        Blank().layoutWeight(1)

        SymbolGlyph($r('sys.symbol.heart'))
          .fontSize(24)
          .fontColor([$r('app.color.ink_deep')])
          .onClick(() => { HdsSnackBar.show({ message: '功能开发中' }); })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      Scroll() {
        Column({ space: 16 }) {
          // Slogan 区
          Column({ space: 4 }) {
            Text('今天收集了什么？')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.ink_deep'))
              .width('100%')

            Text('每一个小物品都是生活的记录 ✨')
              .fontSize(12)
              .fontColor($r('app.color.ink_light'))
              .width('100%')
          }
          .width('100%')
          .padding({ left: 16, right: 16 })

          // + 拍摄贴纸 大按钮
          Row({ space: 8 }) {
            SymbolGlyph($r('sys.symbol.plus'))
              .fontSize(18)
              .fontColor([Color.White])
            Text('拍摄贴纸')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
          }
          .width('100%')
          .height(48)
          .backgroundColor($r('app.color.brand_primary'))
          .borderRadius(24)
          .justifyContent(FlexAlign.Center)
          .margin({ left: 16, right: 16 })
          .onClick(() => { this.showPickerSheet = true; })

          // 贴纸网格
          if (this.isLoading) {
            LoadingProgress()
              .width(48)
              .height(48)
              .color($r('app.color.brand_primary'))
              .layoutWeight(1)
          } else if (this.stickerList.length === 0) {
            EmptyStateView({
              icon: $r('sys.symbol.square_grid_2x2'),
              title: '还没有贴纸',
              subtitle: '点击上方「拍摄贴纸」开始收集'
            })
          } else {
            StickerGrid({
              stickers: this.stickerList,
              onStickerClick: (sticker: Sticker) => {
                const param: IdParam = { id: sticker.id };
                this.pathStack.pushPathByName('StickerDetailPage', param);
              }
            })
          }
        }
        .width('100%')
        .padding({ top: 8, bottom: 24 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_base'))
    .bindSheet(this.showPickerSheet, this.PickerSheetBuilder(), {
      height: 240,
      showClose: false,
      backgroundColor: 'rgba(255,255,255,0.95)',
    })
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
