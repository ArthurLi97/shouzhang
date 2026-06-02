// database/RdbHelper.ets

import { relationalStore, ValuesBucket } from '@kit.ArkData';
import { Sticker } from '../models/Sticker';
import { CanvasProject } from '../models/CanvasProject';
import { Category } from '../models/Category';

const DB_NAME = 'snapsticker.db';
const DB_VERSION = 1;

export class RdbHelper {
  private static instance: RdbHelper | null = null;
  private rdbStore: relationalStore.RdbStore | null = null;

  static getInstance(): RdbHelper {
    if (!RdbHelper.instance) {
      RdbHelper.instance = new RdbHelper();
    }
    return RdbHelper.instance;
  }

  async init(context: Context): Promise<void> {
    try {
      const config: relationalStore.StoreConfig = {
        name: DB_NAME,
        securityLevel: relationalStore.SecurityLevel.S1,
      };
      this.rdbStore = await relationalStore.getRdbStore(context, config);
      await this.createTables();
    } catch (err) {
      console.error('RdbHelper init error:', JSON.stringify(err));
    }
  }

  private async createTables(): Promise<void> {
    if (!this.rdbStore) return;
    try {
      const stickerSql = `CREATE TABLE IF NOT EXISTS stickers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uri TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT '其他',
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        tags TEXT
      )`;

      const categorySql = `CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        icon TEXT,
        count INTEGER NOT NULL DEFAULT 0,
        sortOrder INTEGER NOT NULL DEFAULT 0
      )`;

      const canvasSql = `CREATE TABLE IF NOT EXISTS canvas_projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        thumbnailUri TEXT,
        items TEXT NOT NULL,
        background TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )`;

      await this.rdbStore.executeSql(stickerSql);
      await this.rdbStore.executeSql(categorySql);
      await this.rdbStore.executeSql(canvasSql);

      const result = await this.rdbStore.querySql('SELECT COUNT(*) as count FROM categories');
      let count = 0;
      if (result.goToFirstRow()) {
        count = result.getLong(result.getColumnIndex('count'));
      }
      result.close();
      if (count === 0) {
        await this.insertDefaultCategories();
      }
    } catch (err) {
      console.error('createTables error:', JSON.stringify(err));
    }
  }

  private async insertDefaultCategories(): Promise<void> {
    if (!this.rdbStore) return;
    const defaults = ['全部', '咖啡', '美食', '花草', '宠物', '其他'];
    for (let i = 0; i < defaults.length; i++) {
      try {
        const bucket: ValuesBucket = {
          name: defaults[i],
          sortOrder: i,
        };
        await this.rdbStore.insert('categories', bucket);
      } catch (err) {
        console.error('insertDefaultCategories error:', JSON.stringify(err));
      }
    }
  }

  // ---- Stickers ----
  async insertSticker(sticker: Sticker): Promise<number> {
    if (!this.rdbStore) return -1;
    try {
      const bucket: ValuesBucket = {
        uri: sticker.uri,
        category: sticker.category,
        createdAt: sticker.createdAt,
        updatedAt: sticker.updatedAt,
        tags: sticker.tags ? JSON.stringify(sticker.tags) : '',
      };
      const id = await this.rdbStore.insert('stickers', bucket);
      if (id > 0) {
        await this.updateCategoryCount(sticker.category, 1);
      }
      return id;
    } catch (err) {
      console.error('insertSticker error:', JSON.stringify(err));
      return -1;
    }
  }

  async getStickers(category?: string, limit?: number, offset?: number): Promise<Sticker[]> {
    if (!this.rdbStore) return [];
    try {
      const predicates = new relationalStore.RdbPredicates('stickers');
      if (category && category !== '全部') {
        predicates.equalTo('category', category);
      }
      predicates.orderByDesc('createdAt');
      if (limit !== undefined && limit > 0) {
        predicates.limitAs(limit);
        if (offset !== undefined && offset > 0) {
          predicates.offsetAs(offset);
        }
      }
      const resultSet = await this.rdbStore.query(predicates);
      const list: Sticker[] = [];
      while (resultSet.goToNextRow()) {
        list.push(this.rowToSticker(resultSet));
      }
      resultSet.close();
      return list;
    } catch (err) {
      console.error('getStickers error:', JSON.stringify(err));
      return [];
    }
  }

  async getStickerById(id: number): Promise<Sticker | null> {
    if (!this.rdbStore) return null;
    try {
      const predicates = new relationalStore.RdbPredicates('stickers');
      predicates.equalTo('id', id);
      const resultSet = await this.rdbStore.query(predicates);
      let sticker: Sticker | null = null;
      if (resultSet.goToFirstRow()) {
        sticker = this.rowToSticker(resultSet);
      }
      resultSet.close();
      return sticker;
    } catch (err) {
      console.error('getStickerById error:', JSON.stringify(err));
      return null;
    }
  }

  async deleteSticker(id: number): Promise<void> {
    if (!this.rdbStore) return;
    try {
      const sticker = await this.getStickerById(id);
      if (!sticker) return;
      const predicates = new relationalStore.RdbPredicates('stickers');
      predicates.equalTo('id', id);
      await this.rdbStore.delete(predicates);
      await this.updateCategoryCount(sticker.category, -1);
    } catch (err) {
      console.error('deleteSticker error:', JSON.stringify(err));
    }
  }

  async getStickerCount(): Promise<number> {
    if (!this.rdbStore) return 0;
    try {
      const resultSet = await this.rdbStore.querySql('SELECT COUNT(*) as count FROM stickers');
      let count = 0;
      if (resultSet.goToFirstRow()) {
        count = resultSet.getLong(resultSet.getColumnIndex('count'));
      }
      resultSet.close();
      return count;
    } catch (err) {
      console.error('getStickerCount error:', JSON.stringify(err));
      return 0;
    }
  }

  private rowToSticker(resultSet: relationalStore.ResultSet): Sticker {
    try {
      const tagsStr = resultSet.getString(resultSet.getColumnIndex('tags'));
      return {
        id: resultSet.getLong(resultSet.getColumnIndex('id')),
        uri: resultSet.getString(resultSet.getColumnIndex('uri')),
        category: resultSet.getString(resultSet.getColumnIndex('category')),
        createdAt: resultSet.getLong(resultSet.getColumnIndex('createdAt')),
        updatedAt: resultSet.getLong(resultSet.getColumnIndex('updatedAt')),
        tags: tagsStr ? JSON.parse(tagsStr) : undefined,
      };
    } catch (err) {
      console.error('rowToSticker error:', JSON.stringify(err));
      return {
        id: 0,
        uri: '',
        category: '其他',
        createdAt: 0,
        updatedAt: 0,
      };
    }
  }

  // ---- Categories ----
  async getCategories(): Promise<Category[]> {
    if (!this.rdbStore) return [];
    try {
      const resultSet = await this.rdbStore.querySql('SELECT * FROM categories ORDER BY sortOrder');
      const list: Category[] = [];
      while (resultSet.goToNextRow()) {
        list.push({
          id: resultSet.getLong(resultSet.getColumnIndex('id')),
          name: resultSet.getString(resultSet.getColumnIndex('name')),
          icon: $r('sys.symbol.square_grid_2x2'),
          count: resultSet.getLong(resultSet.getColumnIndex('count')),
          sortOrder: resultSet.getLong(resultSet.getColumnIndex('sortOrder')),
        });
      }
      resultSet.close();
      return list;
    } catch (err) {
      console.error('getCategories error:', JSON.stringify(err));
      return [];
    }
  }

  async updateCategoryCount(name: string, delta: number): Promise<void> {
    if (!this.rdbStore) return;
    try {
      const sql = 'UPDATE categories SET count = MAX(0, count + ?) WHERE name = ?';
      await this.rdbStore.executeSql(sql, [delta, name]);
    } catch (err) {
      console.error('updateCategoryCount error:', JSON.stringify(err));
    }
  }

  async updateCategorySortOrder(id: number, sortOrder: number): Promise<void> {
    if (!this.rdbStore) return;
    try {
      const bucket: ValuesBucket = { sortOrder };
      const predicates = new relationalStore.RdbPredicates('categories');
      predicates.equalTo('id', id);
      await this.rdbStore.update(bucket, predicates);
    } catch (err) {
      console.error('updateCategorySortOrder error:', JSON.stringify(err));
    }
  }

  async deleteCategory(id: number): Promise<void> {
    if (!this.rdbStore) return;
    try {
      const predicates = new relationalStore.RdbPredicates('categories');
      predicates.equalTo('id', id);
      await this.rdbStore.delete(predicates);
    } catch (err) {
      console.error('deleteCategory error:', JSON.stringify(err));
    }
  }

  // ---- Canvas Projects ----
  async insertCanvasProject(project: CanvasProject): Promise<number> {
    if (!this.rdbStore) return -1;
    try {
      const bucket: ValuesBucket = {
        title: project.title,
        thumbnailUri: project.thumbnailUri,
        items: JSON.stringify(project.items),
        background: JSON.stringify(project.background),
        createdAt: project.createdAt,
        updatedAt: project.updatedAt,
      };
      return await this.rdbStore.insert('canvas_projects', bucket);
    } catch (err) {
      console.error('insertCanvasProject error:', JSON.stringify(err));
      return -1;
    }
  }

  async getCanvasProjects(): Promise<CanvasProject[]> {
    if (!this.rdbStore) return [];
    try {
      const resultSet = await this.rdbStore.querySql('SELECT * FROM canvas_projects ORDER BY updatedAt DESC');
      const list: CanvasProject[] = [];
      while (resultSet.goToNextRow()) {
        list.push(this.rowToCanvasProject(resultSet));
      }
      resultSet.close();
      return list;
    } catch (err) {
      console.error('getCanvasProjects error:', JSON.stringify(err));
      return [];
    }
  }

  async getCanvasProjectCount(): Promise<number> {
    if (!this.rdbStore) return 0;
    try {
      const resultSet = await this.rdbStore.querySql('SELECT COUNT(*) as count FROM canvas_projects');
      let count = 0;
      if (resultSet.goToFirstRow()) {
        count = resultSet.getLong(resultSet.getColumnIndex('count'));
      }
      resultSet.close();
      return count;
    } catch (err) {
      console.error('getCanvasProjectCount error:', JSON.stringify(err));
      return 0;
    }
  }

  private rowToCanvasProject(resultSet: relationalStore.ResultSet): CanvasProject {
    try {
      return {
        id: resultSet.getLong(resultSet.getColumnIndex('id')),
        title: resultSet.getString(resultSet.getColumnIndex('title')),
        thumbnailUri: resultSet.getString(resultSet.getColumnIndex('thumbnailUri')),
        items: JSON.parse(resultSet.getString(resultSet.getColumnIndex('items'))),
        background: JSON.parse(resultSet.getString(resultSet.getColumnIndex('background'))),
        createdAt: resultSet.getLong(resultSet.getColumnIndex('createdAt')),
        updatedAt: resultSet.getLong(resultSet.getColumnIndex('updatedAt')),
      };
    } catch (err) {
      console.error('rowToCanvasProject error:', JSON.stringify(err));
      return {
        id: 0,
        title: '',
        thumbnailUri: '',
        items: [],
        background: { type: 'color', value: '#FFF8F0' },
        createdAt: 0,
        updatedAt: 0,
      };
    }
  }
}
