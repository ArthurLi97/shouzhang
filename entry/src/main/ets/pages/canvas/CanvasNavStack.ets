// pages/canvas/CanvasNavStack.ets

import { CanvasEditPage } from './CanvasEditPage';
import { ExportPage } from './ExportPage';
import { BackgroundPage } from './BackgroundPage';

@Component
export struct CanvasNavStack {
  @Provide('canvasPathStack') pathStack: NavPathStack = new NavPathStack();

  build() {
    Navigation(this.pathStack) {
      CanvasEditPage()
    }
    .hideTitleBar(true)
    .navDestination(this.navDestinationBuilder)
  }

  @Builder
  navDestinationBuilder(name: string, param: object) {
    NavDestination() {
      if (name === 'ExportPage') {
        ExportPage()
      } else if (name === 'BackgroundPage') {
        BackgroundPage()
      }
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg_base'))
  }
}
