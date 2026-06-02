// models/CanvasProject.ets

import { CanvasItem } from './CanvasItem';
import { BackgroundConfig } from './BackgroundConfig';

export interface CanvasProject {
  id: number;
  title: string;
  thumbnailUri: string;
  items: CanvasItem[];
  background: BackgroundConfig;
  createdAt: number;
  updatedAt: number;
}
