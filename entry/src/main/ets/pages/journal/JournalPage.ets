// pages/journal/JournalPage.ets
// 我的手账列表

import { CanvasProject } from '../../models/CanvasProject';
import { RdbHelper } from '../../database/RdbHelper';
import { HdsSnackBar } from '../../components/hds/HdsSnackBar';

interface JournalDetailParam {
  id: number;
}

@Component
export struct JournalPage {
  @Consume('rootPathStack') pathStack: NavPathStack;
  @State projects: CanvasProject[] = [];
  @State isLoading: boolean = true;

  aboutToAppear(): void {
    this.loadProjects();
  }

  onPageShow(): void {
    this.loadProjects();
  }

  async loadProjects(): Promise<void> {
    this.isLoading = true;
    try {
      const db = RdbHelper.getInstance();
      this.projects = await db.getCanvasProjects();
    } catch (err) {
      console.error('loadProjects error:', JSON.stringify(err));
      this.projects = [];
    } finally {
      this.isLoading = false;
    }
  }

  formatDate(ts: number): string {
    const d = new Date(ts);
    return `${d.getFullYear()}.${String(d.getMonth() + 1).padStart(2, '0')}.${String(d.getDate()).padStart(2, '0')}`;
  }

  build() {
    Column() {
      // 顶部栏
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([$r('app.color.ink_deep')])
          .onClick(() => { this.pathStack.pop(); })

        Blank().layoutWeight(1)

        Text('我的手账')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.ink_deep'))

        Blank().layoutWeight(1)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      if (this.isLoading) {
        LoadingProgress()
          .width(48)
          .height(48)
          .color($r('app.color.brand_primary'))
          .layoutWeight(1)
      } else if (this.projects.length === 0) {
        Column({ space: 12 }) {
          SymbolGlyph($r('sys.symbol.doc_text'))
            .fontSize(48)
            .fontColor([$r('app.color.ink_light')])

          Text('还没有手账')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.ink_mid'))

          Text('去创作吧，把生活收集成贴纸 ✨')
            .fontSize(13)
            .fontColor($r('app.color.ink_light'))
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.projects, (project: CanvasProject) => {
            ListItem() {
              Row({ space: 16 }) {
                Image(project.thumbnailUri || '')
                  .width(80)
                  .height(100)
                  .borderRadius(12)
                  .objectFit(ImageFit.Cover)
                  .backgroundColor($r('app.color.bg_base'))

                Column({ space: 6 }) {
                  Text(project.title || '未命名手账')
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.ink_deep'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(this.formatDate(project.createdAt))
                    .fontSize(12)
                    .fontColor($r('app.color.ink_light'))

                  Text(`${project.items?.length || 0} 张贴纸`)
                    .fontSize(12)
                    .fontColor($r('app.color.ink_mid'))
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize(16)
                  .fontColor([$r('app.color.ink_light')])
              }
              .width('100%')
              .padding(16)
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(16)
            }
            .onClick(() => {
              const param: JournalDetailParam = { id: project.id ?? 0 };
              this.pathStack.pushPathByName('JournalDetailPage', param);
            })
          })
        }
        .padding(16)
        .layoutWeight(1)
        .divider({ strokeWidth: 0.5, color: $r('app.color.divider') })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_base'))
  }
}
