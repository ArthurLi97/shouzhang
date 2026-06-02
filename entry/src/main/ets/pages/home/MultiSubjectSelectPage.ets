// pages/home/MultiSubjectSelectPage.ets
// 异常状态：多主体选择

import { HdsActionBar } from '../../components/hds/HdsActionBar';

interface SubjectOption {
  id: number;
  uri: string;
  label: string;
}

@Component
export struct MultiSubjectSelectPage {
  @Consume('homePathStack') pathStack: NavPathStack;
  @State selectedIds: number[] = [];
  @State subjects: SubjectOption[] = [
    { id: 1, uri: '', label: '主体 1' },
    { id: 2, uri: '', label: '主体 2' },
    { id: 3, uri: '', label: '主体 3' },
  ];

  toggleSelect(id: number): void {
    const idx = this.selectedIds.indexOf(id);
    if (idx >= 0) {
      this.selectedIds.splice(idx, 1);
    } else {
      this.selectedIds.push(id);
    }
  }

  confirm(): void {
    // 确认选择后进入编辑页
    this.pathStack.pop();
  }

  build() {
    Column() {
      HdsActionBar({
        startButtons: [
          { icon: $r('sys.symbol.chevron_left'), action: () => { this.pathStack.pop(); } }
        ],
        primaryText: { text: '多主体选择', fontSize: 18, fontWeight: FontWeight.Medium }
      })

      Text('请选择要保留的主体')
        .fontSize(14)
        .fontColor($r('app.color.ink_mid'))
        .margin({ top: 16, bottom: 8 })
        .width('100%')
        .textAlign(TextAlign.Center)

      Text(`最多选择1个`)
        .fontSize(12)
        .fontColor($r('app.color.ink_light'))
        .margin({ bottom: 16 })

      List() {
        ForEach(this.subjects, (subject: SubjectOption) => {
          ListItem() {
            Row({ space: 16 }) {
              Stack() {
                Image(subject.uri || $r('app.media.startIcon'))
                  .width(80)
                  .height(80)
                  .borderRadius(12)
                  .objectFit(ImageFit.Cover)

                if (this.selectedIds.includes(subject.id)) {
                  Stack() {
                    SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
                      .fontSize(28)
                      .fontColor([$r('app.color.brand_primary')])
                  }
                  .width(80)
                  .height(80)
                  .backgroundColor('rgba(255,255,255,0.4)')
                  .borderRadius(12)
                  .align(Alignment.Center)
                }
              }

              Text(subject.label)
                .fontSize(16)
                .fontColor($r('app.color.ink_deep'))
                .layoutWeight(1)
            }
            .width('100%')
            .padding(16)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(16)
            .margin({ left: 16, right: 16, bottom: 12 })
          }
          .onClick(() => { this.toggleSelect(subject.id); })
        })
      }
      .layoutWeight(1)

      Button(`确认 (${this.selectedIds.length})`, { type: ButtonType.Capsule })
        .width('90%')
        .height(48)
        .backgroundColor(this.selectedIds.length > 0 ? $r('app.color.brand_primary') : $r('app.color.ink_light'))
        .fontColor(Color.White)
        .margin({ bottom: 32, top: 16 })
        .enabled(this.selectedIds.length > 0)
        .onClick(() => { this.confirm(); })
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: '24vp' })
    .backgroundColor($r('app.color.bg_base'))
  }
}
