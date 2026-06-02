// pages/home/CategoryPage.ets

import { Sticker } from '../../models/Sticker';
import { RdbHelper } from '../../database/RdbHelper';
import { CategoryParam, IdParam } from '../../models/PageParams';
import { StickerGrid } from '../../components/StickerGrid';
import { EmptyStateView } from '../../components/EmptyStateView';
import { HdsActionBar } from '../../components/hds/HdsActionBar';

@Component
export struct CategoryPage {
  @Consume('homePathStack') pathStack: NavPathStack;
  @State category: string = '';
  @State stickers: Sticker[] = [];
  private db: RdbHelper = RdbHelper.getInstance();

  aboutToAppear(): void {
    const raw: object | null = this.pathStack.getParamByName('CategoryPage') as object | null;
    if (raw) {
      const params: CategoryParam = raw as CategoryParam;
      this.category = params.category;
    }
    this.loadStickers();
  }

  async loadStickers(): Promise<void> {
    this.stickers = await this.db.getStickers(this.category);
  }

  goToStickerDetail(sticker: Sticker): void {
    const param: IdParam = { id: sticker.id };
    this.pathStack.pushPathByName('StickerDetailPage', param);
  }

  build() {
    Column() {
      HdsActionBar({
        startButtons: [
          { icon: $r('sys.symbol.chevron_left'), action: () => { this.pathStack.pop(); } }
        ],
        primaryText: { text: this.category, fontSize: 18, fontWeight: FontWeight.Medium }
      })

      if (this.stickers.length === 0) {
        EmptyStateView({
          icon: $r('sys.symbol.square_grid_2x2'),
          title: '还没有' + this.category + '贴纸',
          subtitle: '去拍一张吧'
        })
      } else {
        StickerGrid({
          stickers: this.stickers,
          onStickerClick: (sticker) => { this.goToStickerDetail(sticker); }
        })
      }
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: '24vp' })
    .backgroundColor($r('app.color.bg_base'))
  }
}
