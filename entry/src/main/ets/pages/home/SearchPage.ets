// pages/home/SearchPage.ets

import { Sticker } from '../../models/Sticker';
import { RdbHelper } from '../../database/RdbHelper';
import { StickerGrid } from '../../components/StickerGrid';
import { HdsActionBar } from '../../components/hds/HdsActionBar';
import { IdParam } from '../../models/PageParams';

@Component
export struct SearchPage {
  @Consume('homePathStack') pathStack: NavPathStack;
  @State keyword: string = '';
  @State results: Sticker[] = [];
  @State history: string[] = ['咖啡', '猫咪', '花朵'];
  @State hotSearch: string[] = ['咖啡', '花', '花束', '蛋糕', '猫'];
  private db: RdbHelper = RdbHelper.getInstance();

  async search(): Promise<void> {
    if (!this.keyword.trim()) {
      this.results = [];
      return;
    }
    // 简单搜索：加载所有贴纸再过滤
    const all = await this.db.getStickers();
    this.results = all.filter((s) =>
      s.category.includes(this.keyword) ||
      (s.tags && s.tags.some((t) => t.includes(this.keyword)))
    );
  }

  build() {
    Column() {
      HdsActionBar({
        startButtons: [
          { icon: $r('sys.symbol.chevron_left'), action: () => { this.pathStack.pop(); } }
        ]
      }) {
        Search({ placeholder: '搜索贴纸', value: this.keyword })
          .width('100%')
          .height(40)
          .backgroundColor($r('app.color.search_bg'))
          .borderRadius(20)
          .onChange((v) => {
            this.keyword = v;
            this.search();
          })
      }

      if (this.keyword.length === 0) {
        Column() {
          // 热门搜索
          Text('热门搜索')
            .fontSize(14)
            .fontColor($r('app.color.ink_mid'))
            .margin({ left: 16, right: 16, top: 16 })
            .width('100%')

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.hotSearch, (h: string) => {
              Text(h)
                .fontSize(12)
                .padding({ top: 4, bottom: 4, left: 10, right: 10 })
                .backgroundColor($r('app.color.chip_bg'))
                .borderRadius(12)
                .margin({ right: 8, bottom: 8 })
                .onClick(() => {
                  this.keyword = h;
                  this.search();
                })
            })
          }
          .padding(16)
          .width('100%')

          // 最近搜索
          Text('最近搜索')
            .fontSize(14)
            .fontColor($r('app.color.ink_mid'))
            .margin({ left: 16, right: 16, top: 8 })
            .width('100%')

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.history, (h: string) => {
              Text(h)
                .fontSize(12)
                .padding({ top: 4, bottom: 4, left: 10, right: 10 })
                .backgroundColor($r('app.color.chip_bg'))
                .borderRadius(12)
                .margin({ right: 8, bottom: 8 })
                .onClick(() => {
                  this.keyword = h;
                  this.search();
                })
            })
          }
          .padding(16)
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      } else {
        if (this.results.length === 0) {
          Text('未找到相关贴纸')
            .fontSize(14)
            .fontColor($r('app.color.ink_mid'))
            .layoutWeight(1)
        } else {
          StickerGrid({
            stickers: this.results,
            onStickerClick: (sticker: Sticker) => {
              const param: IdParam = { id: sticker.id };
              this.pathStack.pushPathByName('StickerDetailPage', param);
            }
          })
        }
      }
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: '24vp' })
    .backgroundColor($r('app.color.bg_base'))
  }
}
