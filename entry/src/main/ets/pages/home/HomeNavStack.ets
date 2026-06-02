// pages/home/HomeNavStack.ets

import { HomePage } from './HomePage';
import { ProcessingPage } from './ProcessingPage';
import { StickerEditPage } from './StickerEditPage';
import { SaveSuccessPage } from './SaveSuccessPage';
import { StickerDetailPage } from './StickerDetailPage';
import { NoSubjectPage } from './NoSubjectPage';
import { BlurSubjectPage } from './BlurSubjectPage';
import { MultiSubjectSelectPage } from './MultiSubjectSelectPage';
import { SettingsPage } from './SettingsPage';
import { PrivacyPolicyPage } from './PrivacyPolicyPage';
import { UserAgreementPage } from './UserAgreementPage';

@Component
export struct HomeNavStack {
  @Provide('homePathStack') pathStack: NavPathStack = new NavPathStack();

  build() {
    Navigation(this.pathStack) {
      HomePage()
    }
    .hideTitleBar(true)
    .navDestination(this.navDestinationBuilder)
  }

  @Builder
  navDestinationBuilder(name: string, param: object) {
    NavDestination() {
      if (name === 'ProcessingPage') {
        ProcessingPage()
      } else if (name === 'StickerEditPage') {
        StickerEditPage()
      } else if (name === 'SaveSuccessPage') {
        SaveSuccessPage()
      } else if (name === 'StickerDetailPage') {
        StickerDetailPage()
      } else if (name === 'NoSubjectPage') {
        NoSubjectPage()
      } else if (name === 'BlurSubjectPage') {
        BlurSubjectPage()
      } else if (name === 'MultiSubjectSelectPage') {
        MultiSubjectSelectPage()
      } else if (name === 'SettingsPage') {
        SettingsPage()
      } else if (name === 'PrivacyPolicyPage') {
        PrivacyPolicyPage()
      } else if (name === 'UserAgreementPage') {
        UserAgreementPage()
      }
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg_base'))
  }
}
