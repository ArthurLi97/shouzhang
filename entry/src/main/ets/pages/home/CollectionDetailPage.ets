// pages/home/CollectionDetailPage.ets
// Collection 贴纸详情页 — 浏览某分类下的所有贴纸

import { Sticker } from '../../models/Sticker';
import { CollectionDetailParam } from '../../models/PageParams';
import { RdbHelper } from '../../database/RdbHelper';
import { HdsSnackBar } from '../../components/hds/HdsSnackBar';
import { TEXT_PRIMARY, TEXT_SECONDARY, BG_BASE } from '../../constants/ThemeConstants';

@Component
export struct CollectionDetailPage {
  @Consume('rootPathStack') pathStack: NavPathStack;
  @State stickers: Sticker[] = [];
  @State collectionName: string = '';
  @State collectionColor: string = '#F3D6D8';
  private collectionId: number = 0;
  private db: RdbHelper = RdbHelper.getInstance();

  aboutToAppear(): void {
    const raw: object | null = this.pathStack.getParamByName('CollectionDetailPage') as object | null;
    if (raw) {
      const params: CollectionDetailParam = raw as CollectionDetailParam;
      this.collectionId = params.collectionId;
      this.collectionName = params.collectionName;
      this.collectionColor = params.collectionColor;
      this.loadStickers();
    }
  }

  async loadStickers(): Promise<void> {
    try {
      this.stickers = await this.db.getStickers(this.collectionId);
    } catch (err) {
      console.error('loadStickers error:', JSON.stringify(err));
      this.stickers = [];
    }
  }

  onStickerTap(sticker: Sticker): void {
    // 设置待添加的贴纸，返回首页后自动添加到 Canvas
    AppStorage.setOrCreate('pending_sticker_id', sticker.id ?? 0);
    AppStorage.setOrCreate('pending_canvas_sticker', sticker.image);
    this.pathStack.pop();
    HdsSnackBar.show({ message: '贴纸已添加到画布' });
  }

  @Builder
  TopBar(): void {
    Row() {
      SymbolGlyph($r('sys.symbol.chevron_left'))
        .fontSize(24)
        .fontColor([TEXT_PRIMARY])
        .onClick(() => { this.pathStack.pop(); })

      Column({ space: 2 }) {
        Text(this.collectionName)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(TEXT_PRIMARY)

        Text(`${this.stickers.length} sticker${this.stickers.length === 1 ? '' : 's'}`)
          .fontSize(12)
          .fontColor(TEXT_SECONDARY)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      Blank().width(24)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  EmptyState(): void {
    Column({ space: 12 }) {
      SymbolGlyph($r('sys.symbol.square_grid_2x2'))
        .fontSize(40)
        .fontColor([$r('app.color.ink_light')])

      Text(`0 stickers in ${this.collectionName}`)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_PRIMARY)

      Text('Tap Capture to add your first sticker')
        .fontSize(14)
        .fontColor(TEXT_SECONDARY)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Stack() {
      Column({ space: 0 }) {
        this.TopBar()

        if (this.stickers.length === 0) {
          this.EmptyState()
        } else {
          Grid() {
            ForEach(this.stickers, (sticker: Sticker) => {
              GridItem() {
                Stack({ alignContent: Alignment.Center }) {
                  Image(sticker.image)
                    .width('100%')
                    .height('100%')
                    .objectFit(ImageFit.Cover)
                    .borderRadius(16)
                }
                .padding(8)
                .backgroundColor(Color.White)
                .borderRadius(24)
                .shadow({
                  radius: 12,
                  color: 'rgba(0,0,0,0.06)',
                  offsetX: 0,
                  offsetY: 3
                })
              }
              .onClick(() => this.onStickerTap(sticker))
            }, (sticker: Sticker) => (sticker.id ?? 0).toString())
          }
          .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
          .columnsGap(10)
          .rowsGap(10)
          .padding(16)
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(BG_BASE)
    }
    .width('100%')
    .height('100%')
  }
}
