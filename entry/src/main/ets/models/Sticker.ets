// models/Sticker.ets

export interface Sticker {
  id: number;
  uri: string;
  category: string;
  createdAt: number;
  updatedAt: number;
  tags?: string[];
}
