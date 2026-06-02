// components/StickerGrid.ets

import { Sticker } from '../models/Sticker';
import { StickerDataSource } from './StickerDataSource';

@Component
export struct StickerGrid {
  @Prop stickers: Sticker[];
  onStickerClick?: (sticker: Sticker) => void;
  private gridScroller: Scroller = new Scroller();
  private dataSource: StickerDataSource = new StickerDataSource([]);

  aboutToAppear(): void {
    this.dataSource.updateData(this.stickers);
  }

  aboutToUpdate(): void {
    this.dataSource.updateData(this.stickers);
  }

  build() {
    Grid(this.gridScroller) {
      LazyForEach(this.dataSource, (sticker: Sticker) => {
        GridItem() {
          Image(sticker.uri)
            .width('100%')
            .aspectRatio(1)
            .objectFit(ImageFit.Cover)
            .borderRadius(12)
            .shadow({
              radius: 8,
              color: $r('app.color.shadow_card'),
              offsetX: 0,
              offsetY: 2
            })
        }
        .onClick(() => {
          this.onStickerClick?.(sticker);
        })
      }, (sticker: Sticker) => sticker.id.toString())
    }
    .columnsTemplate('1fr 1fr 1fr')
    .columnsGap(8)
    .rowsGap(8)
    .padding(16)
    .layoutWeight(1)
    .cachedCount(2)
  }
}
