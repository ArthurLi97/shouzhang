// pages/home/CategoryManagePage.ets

import { Category } from '../../models/Category';
import { RdbHelper } from '../../database/RdbHelper';
import { HdsActionBar } from '../../components/hds/HdsActionBar';
import { HdsListItem } from '../../components/hds/HdsListItem';
import { HdsSnackBar } from '../../components/hds/HdsSnackBar';

@Component
export struct CategoryManagePage {
  @Consume('homePathStack') pathStack: NavPathStack;
  @State categories: Category[] = [];
  @State isEditMode: boolean = false;
  private db: RdbHelper = RdbHelper.getInstance();

  aboutToAppear(): void {
    this.loadCategories();
  }

  async loadCategories(): Promise<void> {
    this.categories = await this.db.getCategories();
  }

  toggleEditMode(): void {
    this.isEditMode = !this.isEditMode;
  }

  build() {
    Column() {
      HdsActionBar({
        startButtons: [
          { icon: $r('sys.symbol.chevron_left'), action: () => { this.pathStack.pop(); } }
        ],
        primaryText: { text: '分类管理', fontSize: 18, fontWeight: FontWeight.Medium },
        endButtons: [
          { text: this.isEditMode ? '完成' : '编辑', textColor: $r('app.color.brand_primary'), action: () => { this.toggleEditMode(); } }
        ]
      })

      List() {
        ForEach(this.categories, (cat: Category) => {
          ListItem() {
            HdsListItem({
              primaryText: cat.name,
              primaryTextFontSize: 16,
              showPrefixSymbol: true,
              primaryPrefixSymbol: cat.icon,
              suffixType: this.isEditMode ? 'badge' : 'arrow',
              suffixBadgeText: this.isEditMode ? `${cat.count}` : ''
            })
          }
          .swipeAction({
            end: this.isEditMode ? {
              builder: () => {
                this.DeleteButton(cat);
              }
            } : undefined
          })
        })
      }
      .divider({ strokeWidth: 0.5, color: $r('app.color.divider') })
      .layoutWeight(1)
      .backgroundColor($r('app.color.bg_base'))

      // 底部添加分类按钮
      Row({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize(16)
          .fontColor([$r('app.color.ink_mid')])
        Text('添加分类')
          .fontSize(14)
          .fontColor($r('app.color.ink_mid'))
      }
      .width('100%')
      .padding(16)
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(16)
      .margin({ left: 16, right: 16, bottom: 16 })
      .onClick(() => {
        HdsSnackBar.show({ message: '添加分类功能开发中' });
      })
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: '24vp' })
    .backgroundColor($r('app.color.bg_base'))
  }

  private readonly defaultCategories: string[] = ['全部', '咖啡', '美食', '花草', '宠物', '其他'];

  async deleteCategory(cat: Category): Promise<void> {
    if (this.defaultCategories.includes(cat.name)) {
      HdsSnackBar.show({ message: '默认分类不可删除' });
      return;
    }
    await this.db.deleteCategory(cat.id);
    HdsSnackBar.show({ message: '已删除分类' });
    await this.loadCategories();
  }

  @Builder
  DeleteButton(cat: Category): void {
    Column() {
      SymbolGlyph($r('sys.symbol.trash'))
        .fontSize(20)
        .fontColor([Color.White])
    }
    .width(60)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.danger'))
    .onClick(async () => {
      await this.deleteCategory(cat);
    })
  }
}
