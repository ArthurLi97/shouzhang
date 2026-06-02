// components/StickerDataSource.ets

import { Sticker } from '../models/Sticker';

export class StickerDataSource implements IDataSource {
  private data: Sticker[] = [];
  private listeners: DataChangeListener[] = [];

  constructor(data: Sticker[]) {
    this.data = data;
  }

  updateData(data: Sticker[]): void {
    this.data = data;
    this.notifyDataReload();
  }

  totalCount(): number {
    return this.data.length;
  }

  getData(index: number): Sticker {
    return this.data[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  private notifyDataReload(): void {
    this.listeners.forEach((listener) => {
      listener.onDataReloaded();
    });
  }
}
