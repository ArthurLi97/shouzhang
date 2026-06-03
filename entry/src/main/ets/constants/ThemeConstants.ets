// constants/ThemeConstants.ets
// MEMO Design System v1.0 — Color System

// Background
export const BG_BASE            = '#FAF8F4';   // 暖白纸色 — 应用主背景
export const PAPER              = '#F5EFE8';   // 画布颜色 — 纸张色

// Collection Folder Colors
export const DUST_PINK          = '#F3D6D8';   // Collection 文件夹颜色 1
export const CREAM              = '#F4E7D5';   // Collection 文件夹颜色 2
export const LAVENDER           = '#E4E0F3';   // Collection 文件夹颜色 3
export const SAGE               = '#DDE7D8';   // Collection 文件夹颜色 4

// Text
export const TEXT_PRIMARY       = '#2F2A28';   // 主文字
export const TEXT_SECONDARY     = '#8C847E';   // 辅助文字
export const TEXT_TERTIARY      = '#B8AFA8';   // 第三级文字

// UI Elements
export const CARD_BG            = '#FFFFFF';   // 卡片背景
export const DIVIDER            = '#E8E2DA';   // 分割线
export const CHIP_BG            = '#F2F0EC';   // 标签/Chip 背景
export const BOUNDING           = '#B8AFA8';   // 选中虚线框
export const DANGER             = '#FF3B30';   // 删除/危险色

// Shadows
export const SHADOW_STICKER     = 'rgba(0,0,0,0.08)';   // 贴纸阴影
export const SHADOW_PAPER       = 'rgba(0,0,0,0.08)';   // 纸张阴影
export const SHADOW_FOLDER      = 'rgba(0,0,0,0.06)';   // 文件夹阴影
export const SHADOW_FLOAT       = 'rgba(0,0,0,0.10)';   // 浮层面板阴影

// Helper: 根据 Collection 索引获取文件夹颜色
export function getFolderColor(index: number): string {
  const colors = [DUST_PINK, CREAM, LAVENDER, SAGE];
  return colors[index % colors.length];
}
