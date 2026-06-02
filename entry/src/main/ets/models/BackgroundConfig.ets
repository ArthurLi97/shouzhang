// models/BackgroundConfig.ets

export interface BackgroundConfig {
  type: 'color' | 'texture' | 'pattern' | 'image' | 'grid' | 'dot' | 'paper' | 'matte';
  value: string;
}
