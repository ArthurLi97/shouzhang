// components/canvas/StickerPickerSheet.ets

import { Sticker } from '../../models/Sticker';
import { RdbHelper } from '../../database/RdbHelper';
import { StickerDataSource } from '../StickerDataSource';

@Component
export struct StickerPickerSheet {
  onSelectSticker?: (sticker: Sticker) => void;
  @State stickers: Sticker[] = [];
  private db: RdbHelper = RdbHelper.getInstance();
  private dataSource: StickerDataSource = new StickerDataSource([]);

  aboutToAppear(): void {
    this.loadStickers();
  }

  async loadStickers(): Promise<void> {
    try {
      this.stickers = await this.db.getStickers();
      this.dataSource.updateData(this.stickers);
    } catch (err) {
      console.error('loadStickers error:', JSON.stringify(err));
      this.stickers = [];
      this.dataSource.updateData([]);
    }
  }

  build() {
    Column() {
      Text('选择贴纸')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 12, bottom: 8 })
        .fontColor($r('app.color.ink_deep'))

      Grid() {
        LazyForEach(this.dataSource, (sticker: Sticker) => {
          GridItem() {
            Image(sticker.uri)
              .width('100%')
              .aspectRatio(1)
              .objectFit(ImageFit.Cover)
              .borderRadius(8)
          }
          .onClick(() => {
            this.onSelectSticker?.(sticker);
          })
        }, (sticker: Sticker) => sticker.id.toString())
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .columnsGap(8)
      .rowsGap(8)
      .padding(16)
      .height(200)
    }
    .width('100%')
    .backgroundColor('rgba(255,255,255,0.85)')
    .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
    .borderRadius({ topLeft: 20, topRight: 20 })
  }
}
