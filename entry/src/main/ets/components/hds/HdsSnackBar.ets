// components/hds/HdsSnackBar.ets
// HDS 风格底部提示封装（基础 ArkUI 实现，未来可无缝替换为真实 HDS Kit）

import { promptAction } from '@kit.ArkUI';

export interface SnackBarAction {
  text: string;
  callback: () => void;
}

export interface SnackBarConfig {
  message: string;
  action?: SnackBarAction;
  duration?: number;
}

export class HdsSnackBar {
  static show(config: SnackBarConfig): void {
    // MVP 阶段使用系统 Toast 对齐行为
    // 未来可替换为自定义底部浮层实现（带 Action 按钮）
    let msg = config.message;
    if (config.action) {
      msg += ` [${config.action.text}]`;
    }
    try {
      promptAction.showToast({
        message: msg,
        duration: config.duration ?? 3000,
      });
    } catch (err) {
      console.error('showToast error:', JSON.stringify(err));
    }
  }
}
