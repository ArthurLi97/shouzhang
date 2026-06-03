// pages/journal/JournalDetailPage.ets
// 手账详情页

import { CanvasProject } from '../../models/CanvasProject';
import { RdbHelper } from '../../database/RdbHelper';
import { HdsSnackBar } from '../../components/hds/HdsSnackBar';

@Component
export struct JournalDetailPage {
  @Consume('rootPathStack') pathStack: NavPathStack;
  @State project: CanvasProject | null = null;

  aboutToAppear(): void {
    const params = this.pathStack.getParamByName('JournalDetailPage') as object as Record<string, number>;
    if (params?.id) {
      this.loadProject(params.id);
    }
  }

  async loadProject(id: number): Promise<void> {
    try {
      const db = RdbHelper.getInstance();
      const projects = await db.getCanvasProjects();
      this.project = projects.find(p => p.id === id) || null;
    } catch (err) {
      console.error('loadProject error:', JSON.stringify(err));
    }
  }

  formatDate(ts: number): string {
    const d = new Date(ts);
    return `${d.getFullYear()}.${String(d.getMonth() + 1).padStart(2, '0')}.${String(d.getDate()).padStart(2, '0')}`;
  }

  continueEdit(): void {
    if (!this.project) return;
    // 将项目数据设置到 AppStorage，CanvasEditPage 加载
    AppStorage.setOrCreate('journal_project_data', JSON.stringify(this.project));
    this.pathStack.clear();
    HdsSnackBar.show({ message: '已加载到手账，继续创作吧' });
  }

  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([$r('app.color.ink_deep')])
          .onClick(() => { this.pathStack.pop(); })

        Blank().layoutWeight(1)

        Text('手账详情')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.ink_deep'))

        Blank().layoutWeight(1)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      if (!this.project) {
        Column({ space: 8 }) {
          Text('加载中...')
            .fontSize(14)
            .fontColor($r('app.color.ink_mid'))
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 16 }) {
            Image(this.project.thumbnailUri || '')
              .width('90%')
              .aspectRatio(4 / 5)
              .borderRadius(16)
              .objectFit(ImageFit.Cover)
              .shadow({ radius: 16, color: 'rgba(0,0,0,0.08)', offsetY: 8 })

            Column({ space: 6 }) {
              Text(this.project.title || '未命名手账')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.ink_deep'))

              Text(this.formatDate(this.project.createdAt))
                .fontSize(14)
                .fontColor($r('app.color.ink_mid'))

              Text(`${this.project.items?.length || 0} 张贴纸`)
                .fontSize(14)
                .fontColor($r('app.color.ink_mid'))
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
          .padding(16)
        }
        .layoutWeight(1)

        Button('继续编辑', { type: ButtonType.Capsule })
          .width('90%')
          .height(48)
          .backgroundColor($r('app.color.brand_primary'))
          .fontColor(Color.White)
          .margin({ bottom: 32 })
          .onClick(() => { this.continueEdit(); })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_base'))
  }
}
