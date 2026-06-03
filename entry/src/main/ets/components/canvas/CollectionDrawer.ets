// components/canvas/CollectionDrawer.ets
// MEMO Collection 抽屉 — Paper Craft 层叠文件夹标签 + 贴纸网格
// 每个 Collection 是一个厚纸板文件夹标签，堆叠排列，激活时升高

import { Sticker } from '../../models/Sticker';
import { Collection } from '../../models/Collection';
import { RdbHelper } from '../../database/RdbHelper';
import { getFolderColor, TEXT_PRIMARY, TEXT_SECONDARY, PAPER } from '../../constants/ThemeConstants';
import { getThicknessColor } from '../../utils/ColorUtils';

const TAB_HEIGHT = 44;
const TAB_TOP_RADIUS = 20;
const TAB_BOTTOM_RADIUS = 0;
const FOLDER_TAB_OVERLAP = -14;  // 标签重叠量，形成堆叠感

interface FolderTabParams {
  label: string;
  color: string;
  isActive: boolean;
  onTap: () => void;
}

@Component
export struct CollectionDrawer {
  onSelectSticker?: (sticker: Sticker) => void;
  @Link expanded: boolean;
  onExpandChange?: (expanded: boolean) => void;

  @State collections: Collection[] = [];
  @State stickers: Sticker[] = [];
  @State activeCollectionId: number = 0; // 0 = 全部
  private db: RdbHelper = RdbHelper.getInstance();

  aboutToAppear(): void {
    this.loadCollections();
    this.loadStickers();
  }

  async loadCollections(): Promise<void> {
    try {
      this.collections = await this.db.getCollections();
    } catch (err) {
      console.error('loadCollections error:', JSON.stringify(err));
    }
  }

  async loadStickers(): Promise<void> {
    try {
      const cid = this.activeCollectionId === 0 ? undefined : this.activeCollectionId;
      this.stickers = await this.db.getStickers(cid);
    } catch (err) {
      console.error('loadStickers error:', JSON.stringify(err));
      this.stickers = [];
    }
  }

  onCollectionTap(id: number): void {
    this.activeCollectionId = id;
    this.loadStickers();
  }

  toggleExpand(): void {
    this.expanded = !this.expanded;
    this.onExpandChange?.(this.expanded);
  }

  getCollectionColor(index: number): string {
    return getFolderColor(index);
  }

  build() {
    // 外层厚纸板容器
    Stack({ alignContent: Alignment.TopStart }) {
      // 厚度层：略深色偏移，模拟厚纸板侧面
      Stack()
        .width('100%')
        .height('100%')
        .backgroundColor('#E4E2DE')
        .borderRadius({ topLeft: 20, topRight: 20 })
        .offset({ x: 0, y: 2 })

      // 环境柔化 shadow
      Stack()
        .width('100%')
        .height('100%')
        .backgroundColor(Color.White)
        .borderRadius({ topLeft: 20, topRight: 20 })
        .shadow({
          radius: 20,
          color: 'rgba(0,0,0,0.05)',
          offsetX: 0,
          offsetY: -6
        })

      // 核心贴底 shadow
      Stack()
        .width('100%')
        .height('100%')
        .backgroundColor(Color.White)
        .borderRadius({ topLeft: 20, topRight: 20 })
        .shadow({
          radius: 6,
          color: 'rgba(0,0,0,0.06)',
          offsetX: 0,
          offsetY: -2
        })

      // 主色层
      Stack()
        .width('100%')
        .height('100%')
        .backgroundColor(Color.White)
        .borderRadius({ topLeft: 20, topRight: 20 })

      // 顶部高光边
      Stack()
        .width('100%')
        .height('100%')
        .borderRadius({ topLeft: 20, topRight: 20 })
        .border({
          width: { top: 0.5, left: 0.5, right: 0.5, bottom: 0 },
          color: 'rgba(255,255,255,0.6)',
          style: BorderStyle.Solid
        })

      // 内容层
      Column({ space: 0 }) {
        // 拖拽把手
        Row() {
          Column({ space: 2 }) {
            Stack()
              .width(32)
              .height(4)
              .backgroundColor($r('app.color.divider'))
              .borderRadius(2)
            SymbolGlyph(this.expanded ? $r('sys.symbol.chevron_down') : $r('sys.symbol.chevron_up'))
              .fontSize(12)
              .fontColor([$r('app.color.ink_light')])
          }
          .width('100%')
          .padding({ top: 6, bottom: 2 })
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .height(28)
        .onClick(() => this.toggleExpand())

        // 层叠文件夹标签栏
        Stack({ alignContent: Alignment.BottomStart }) {
          Row({ space: FOLDER_TAB_OVERLAP }) {
            this.FolderTab({
              label: '全部',
              color: PAPER,
              isActive: this.activeCollectionId === 0,
              onTap: () => this.onCollectionTap(0)
            })

            ForEach(this.collections, (col: Collection, index: number) => {
              this.FolderTab({
                label: col.name,
                color: this.getCollectionColor(index),
                isActive: this.activeCollectionId === col.id,
                onTap: () => this.onCollectionTap(col.id)
              })
            }, (col: Collection) => col.id.toString())
          }
          .padding({ left: 16, right: 16 })
          .alignItems(VerticalAlign.Bottom)
        }
        .width('100%')
        .height(TAB_HEIGHT)

        // 展开后的贴纸网格区域
        if (this.expanded) {
          Stack() {
            if (this.stickers.length === 0) {
              Column({ space: 8 }) {
                SymbolGlyph($r('sys.symbol.square_grid_2x2'))
                  .fontSize(36)
                  .fontColor([$r('app.color.ink_light')])
                Text('Collect your first sticker')
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(TEXT_PRIMARY)
                Text('Tap + to capture something you love')
                  .fontSize(15)
                  .fontColor(TEXT_SECONDARY)
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
            } else {
              Grid() {
                ForEach(this.stickers, (sticker: Sticker) => {
                  GridItem() {
                    // 贴纸缩略图：厚纸板白边效果
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
                  .onClick(() => { this.onSelectSticker?.(sticker); })
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
          .layoutWeight(1)
          .shadow({ radius: 1, color: 'rgba(0,0,0,0.03)', offsetY: -1 })
        }
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height(this.expanded ? 320 : 96)
    .animation({ duration: 450, curve: Curve.FastOutSlowIn })
  }

  @Builder
  FolderTab(params: FolderTabParams): void {
    // 厚纸板文件夹标签
    Stack({ alignContent: Alignment.Bottom }) {
      // 厚度层
      Stack()
        .width('100%')
        .height('100%')
        .backgroundColor(getThicknessColor(params.color))
        .borderRadius({
          topLeft: TAB_TOP_RADIUS,
          topRight: TAB_TOP_RADIUS,
          bottomLeft: TAB_BOTTOM_RADIUS,
          bottomRight: TAB_BOTTOM_RADIUS
        })
        .offset({ x: 0, y: params.isActive ? 3 : 2 })

      // 环境柔化 shadow
      Stack()
        .width('100%')
        .height('100%')
        .backgroundColor(params.color)
        .borderRadius({
          topLeft: TAB_TOP_RADIUS,
          topRight: TAB_TOP_RADIUS,
          bottomLeft: TAB_BOTTOM_RADIUS,
          bottomRight: TAB_BOTTOM_RADIUS
        })
        .shadow({
          radius: params.isActive ? 12 : 6,
          color: 'rgba(0,0,0,0.06)',
          offsetX: 0,
          offsetY: params.isActive ? 4 : 2
        })

      // 核心贴底 shadow
      Stack()
        .width('100%')
        .height('100%')
        .backgroundColor(params.color)
        .borderRadius({
          topLeft: TAB_TOP_RADIUS,
          topRight: TAB_TOP_RADIUS,
          bottomLeft: TAB_BOTTOM_RADIUS,
          bottomRight: TAB_BOTTOM_RADIUS
        })
        .shadow({
          radius: 3,
          color: 'rgba(0,0,0,0.08)',
          offsetX: 0,
          offsetY: 1
        })

      // 主色层
      Stack()
        .width('100%')
        .height('100%')
        .backgroundColor(params.color)
        .borderRadius({
          topLeft: TAB_TOP_RADIUS,
          topRight: TAB_TOP_RADIUS,
          bottomLeft: TAB_BOTTOM_RADIUS,
          bottomRight: TAB_BOTTOM_RADIUS
        })

      // 顶部高光边
      Stack()
        .width('100%')
        .height('100%')
        .borderRadius({
          topLeft: TAB_TOP_RADIUS,
          topRight: TAB_TOP_RADIUS,
          bottomLeft: TAB_BOTTOM_RADIUS,
          bottomRight: TAB_BOTTOM_RADIUS
        })
        .border({
          width: { top: 0.5, left: 0.5, right: 0, bottom: 0 },
          color: 'rgba(255,255,255,0.45)',
          style: BorderStyle.Solid
        })

      // 文字内容
      Text(params.label)
        .fontSize(13)
        .fontWeight(params.isActive ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(params.isActive ? TEXT_PRIMARY : TEXT_SECONDARY)
        .padding({ top: 10, bottom: 10, left: 20, right: 20 })
        .onClick(params.onTap)
    }
    .height(params.isActive ? TAB_HEIGHT + 6 : TAB_HEIGHT)
    .zIndex(params.isActive ? 100 : 1)
    .animation({ duration: 200, curve: Curve.EaseInOut })
  }
}
