// utils/ColorUtils.ets
// 颜色处理工具函数

/**
 * 将 hex 颜色变暗指定数值（每个通道减去固定值）
 */
export function darkenHex(hex: string, amount: number): string {
  const clean = hex.replace('#', '');
  const num = parseInt(clean, 16);
  const r = Math.max(0, Math.min(255, (num >> 16) - amount));
  const g = Math.max(0, Math.min(255, ((num >> 8) & 0x00FF) - amount));
  const b = Math.max(0, Math.min(255, (num & 0x0000FF) - amount));
  return '#' + ((r << 16) | (g << 8) | b).toString(16).padStart(6, '0');
}

/**
 * 为常用纸张颜色获取厚度色（略深版本）
 */
export function getThicknessColor(baseColor: string): string {
  const map: Record<string, string> = {
    '#F3D6D8': '#E5C5C7',
    '#F4E7D5': '#E6D7C5',
    '#E4E0F3': '#D6D2E5',
    '#DDE7D8': '#CFD9CA',
    '#F2F0EC': '#E4E2DE',
    '#F5EFE8': '#E7E1DA',
    '#FAF8F4': '#ECEAE6',
    '#FFFFFF': '#F2F0EC',
  };
  return map[baseColor.toUpperCase()] || darkenHex(baseColor, 12);
}
