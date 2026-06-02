// pages/canvas/BackgroundPage.ets
// 画布背景选择页（独立页面）

import { BackgroundConfig } from '../../models/BackgroundConfig';
import { HdsActionBar } from '../../components/hds/HdsActionBar';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

interface TextureItem {
  name: string;
  preview: string;
}

@Component
export struct BackgroundPage {
  @Consume('canvasPathStack') pathStack: NavPathStack;
  @State activeTab: number = 0;
  @State selectedColor: string = '#FFFFFF';
  @State selectedTexture: string = '';
  @State selectedPattern: string = '';
  @State selectedImage: string = '';

  aboutToAppear(): void {
  }

  private colors: string[] = ['#FFFFFF', '#F8F8F6', '#FFE4E1', '#E0F7FA', '#F0EDFF', '#FFF8E1', '#1A1A1A', '#FFD93D', '#FF6B9D'];
  private textures: TextureItem[] = [
    { name: '网格', preview: '#E5E5E5' },
    { name: '点阵', preview: '#F0F0F0' },
    { name: '纸张', preview: '#FAFAFA' },
    { name: '磨砂', preview: '#F5F5F5' },
  ];
  private patterns: TextureItem[] = [
    { name: '波点', preview: '#FFE4E1' },
    { name: '条纹', preview: '#E0F7FA' },
    { name: '方格', preview: '#F0EDFF' },
    { name: '斜纹', preview: '#FFF8E1' },
  ];

  onChangeBackground(config: BackgroundConfig): void {
    // 返回结果给上一页
    this.pathStack.pop();
  }

  async pickImage(): Promise<void> {
    const picker = new photoAccessHelper.PhotoViewPicker();
    try {
      const result = await picker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1,
      });
      if (result.photoUris && result.photoUris.length > 0) {
        this.selectedImage = result.photoUris[0];
        this.onChangeBackground({ type: 'image', value: this.selectedImage });
      }
    } catch (err) {
      // 用户取消
    }
  }

  @Builder
  ColorTab(): void {
    Grid() {
      ForEach(this.colors, (color: string) => {
        GridItem() {
          Stack() {
            Stack()
              .width(48)
              .height(48)
              .backgroundColor(color)
              .borderRadius(24)
              .border({
                width: this.selectedColor === color ? 3 : 1,
                color: this.selectedColor === color ? $r('app.color.brand_primary') : $r('app.color.divider')
              })
          }
          .width(56)
          .height(56)
          .align(Alignment.Center)
        }
        .onClick(() => {
          this.selectedColor = color;
          this.onChangeBackground({ type: 'color', value: color });
        })
      })
    }
    .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
    .columnsGap(12)
    .rowsGap(12)
    .padding(16)
    .layoutWeight(1)
  }

  @Builder
  TextureTab(): void {
    Grid() {
      ForEach(this.textures, (item: TextureItem) => {
        GridItem() {
          Column({ space: 8 }) {
            Stack()
              .width('100%')
              .aspectRatio(1)
              .backgroundColor(item.preview)
              .borderRadius(12)
              .border({
                width: this.selectedTexture === item.name ? 3 : 1,
                color: this.selectedTexture === item.name ? $r('app.color.brand_primary') : $r('app.color.divider')
              })
            Text(item.name)
              .fontSize(12)
              .fontColor($r('app.color.ink_mid'))
          }
        }
        .onClick(() => {
          this.selectedTexture = item.name;
          this.onChangeBackground({ type: 'texture', value: item.name });
        })
      })
    }
    .columnsTemplate('1fr 1fr')
    .columnsGap(12)
    .rowsGap(12)
    .padding(16)
    .layoutWeight(1)
  }

  @Builder
  PatternTab(): void {
    Grid() {
      ForEach(this.patterns, (item: TextureItem) => {
        GridItem() {
          Column({ space: 8 }) {
            Stack()
              .width('100%')
              .aspectRatio(1)
              .backgroundColor(item.preview)
              .borderRadius(12)
              .border({
                width: this.selectedPattern === item.name ? 3 : 1,
                color: this.selectedPattern === item.name ? $r('app.color.brand_primary') : $r('app.color.divider')
              })
            Text(item.name)
              .fontSize(12)
              .fontColor($r('app.color.ink_mid'))
          }
        }
        .onClick(() => {
          this.selectedPattern = item.name;
          this.onChangeBackground({ type: 'pattern', value: item.name });
        })
      })
    }
    .columnsTemplate('1fr 1fr')
    .columnsGap(12)
    .rowsGap(12)
    .padding(16)
    .layoutWeight(1)
  }

  @Builder
  ImageTab(): void {
    Column({ space: 16 }) {
      if (this.selectedImage) {
        Image(this.selectedImage)
          .width('90%')
          .aspectRatio(4 / 5)
          .borderRadius(12)
          .objectFit(ImageFit.Cover)
      } else {
        Column({ space: 12 }) {
          SymbolGlyph($r('sys.symbol.camera'))
            .fontSize(48)
            .fontColor([$r('app.color.ink_light')])
          Text('从相册选择背景图片')
            .fontSize(14)
            .fontColor($r('app.color.ink_mid'))
        }
        .width('90%')
        .aspectRatio(4 / 5)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(12)
        .justifyContent(FlexAlign.Center)
        .border({ width: 1, color: $r('app.color.divider'), style: BorderStyle.Dashed })
      }

      Button(this.selectedImage ? '更换图片' : '选择图片', { type: ButtonType.Capsule })
        .width('60%')
        .height(44)
        .backgroundColor($r('app.color.brand_primary'))
        .fontColor(Color.White)
        .onClick(() => { this.pickImage(); })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      HdsActionBar({
        startButtons: [
          { icon: $r('sys.symbol.chevron_left'), action: () => { this.pathStack.pop(); } }
        ],
        primaryText: { text: '背景', fontSize: 18, fontWeight: FontWeight.Medium },
        endButtons: [
          { icon: $r('sys.symbol.gearshape'), action: () => { /* 更多操作预留 */ } }
        ]
      })

      Tabs({ barPosition: BarPosition.Start }) {
        TabContent() { this.ColorTab() }
          .tabBar('颜色')

        TabContent() { this.TextureTab() }
          .tabBar('纹理')

        TabContent() { this.PatternTab() }
          .tabBar('图案')

        TabContent() { this.ImageTab() }
          .tabBar('图片')
      }
      .barMode(BarMode.Fixed)
      .barHeight(40)
      .onChange((index: number) => { this.activeTab = index; })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: '24vp' })
    .backgroundColor($r('app.color.bg_base'))
  }
}
