// database/RdbHelper.ets

import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Sticker } from '../models/Sticker';
import { Collection } from '../models/Collection';
import { Journal } from '../models/Journal';
import { CanvasProject } from '../models/CanvasProject';

export class RdbHelper {
  private static instance: RdbHelper;
  private rdbStore: relationalStore.RdbStore | null = null;

  static getInstance(): RdbHelper {
    if (!RdbHelper.instance) {
      RdbHelper.instance = new RdbHelper();
    }
    return RdbHelper.instance;
  }

  async init(context: common.Context): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: 'memo.db',
      securityLevel: relationalStore.SecurityLevel.S1,
    };
    this.rdbStore = await relationalStore.getRdbStore(context, config);
    await this.createTables();
    await this.initDefaultCollections();
  }

  private async createTables(): Promise<void> {
    if (!this.rdbStore) return;

    await this.rdbStore.executeSql(`
      CREATE TABLE IF NOT EXISTS collections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    `);

    await this.rdbStore.executeSql(`
      CREATE TABLE IF NOT EXISTS stickers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image TEXT NOT NULL,
        collectionId INTEGER NOT NULL
      )
    `);

    await this.rdbStore.executeSql(`
      CREATE TABLE IF NOT EXISTS journals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        canvasSnapshot TEXT NOT NULL
      )
    `);

    await this.rdbStore.executeSql(`
      CREATE TABLE IF NOT EXISTS canvas_projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        thumbnailUri TEXT NOT NULL,
        items TEXT NOT NULL,
        background TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    `);
  }

  private async initDefaultCollections(): Promise<void> {
    const defaults = ['Coffee', 'Food', 'Flower', 'Pets'];
    for (const name of defaults) {
      try {
        await this.rdbStore?.executeSql(
          `INSERT OR IGNORE INTO collections (name) VALUES (?)`,
          [name]
        );
      } catch (e) {
        // ignore
      }
    }
  }

  // Collections
  async getCollections(): Promise<Collection[]> {
    if (!this.rdbStore) return [];
    const resultSet = await this.rdbStore.querySql('SELECT * FROM collections ORDER BY id');
    const list: Collection[] = [];
    while (resultSet.goToNextRow()) {
      list.push({
        id: resultSet.getLong(resultSet.getColumnIndex('id')),
        name: resultSet.getString(resultSet.getColumnIndex('name')),
      });
    }
    resultSet.close();
    return list;
  }

  // Stickers
  async insertSticker(sticker: Sticker): Promise<number> {
    if (!this.rdbStore) return -1;
    const bucket: relationalStore.ValuesBucket = {
      image: sticker.image,
      collectionId: sticker.collectionId,
    };
    return await this.rdbStore.insert('stickers', bucket);
  }

  async getStickers(collectionId?: number): Promise<Sticker[]> {
    if (!this.rdbStore) return [];
    let sql = 'SELECT * FROM stickers';
    const args: relationalStore.ValueType[] = [];
    if (collectionId !== undefined) {
      sql += ' WHERE collectionId = ?';
      args.push(collectionId);
    }
    sql += ' ORDER BY id DESC';
    const resultSet = await this.rdbStore.querySql(sql, args);
    const list: Sticker[] = [];
    while (resultSet.goToNextRow()) {
      list.push({
        id: resultSet.getLong(resultSet.getColumnIndex('id')),
        image: resultSet.getString(resultSet.getColumnIndex('image')),
        collectionId: resultSet.getLong(resultSet.getColumnIndex('collectionId')),
      });
    }
    resultSet.close();
    return list;
  }

  async deleteSticker(id: number): Promise<void> {
    if (!this.rdbStore) return;
    const predicates = new relationalStore.RdbPredicates('stickers');
    predicates.equalTo('id', id);
    await this.rdbStore.delete(predicates);
  }

  async getStickerCountByCollection(collectionId: number): Promise<number> {
    if (!this.rdbStore) return 0;
    const resultSet = await this.rdbStore.querySql(
      'SELECT COUNT(*) as cnt FROM stickers WHERE collectionId = ?',
      [collectionId]
    );
    let count = 0;
    if (resultSet.goToNextRow()) {
      count = resultSet.getLong(resultSet.getColumnIndex('cnt'));
    }
    resultSet.close();
    return count;
  }

  async getTotalStickerCount(): Promise<number> {
    if (!this.rdbStore) return 0;
    const resultSet = await this.rdbStore.querySql('SELECT COUNT(*) as cnt FROM stickers');
    let count = 0;
    if (resultSet.goToNextRow()) {
      count = resultSet.getLong(resultSet.getColumnIndex('cnt'));
    }
    resultSet.close();
    return count;
  }

  // Journals
  async insertJournal(journal: Journal): Promise<number> {
    if (!this.rdbStore) return -1;
    const bucket: relationalStore.ValuesBucket = {
      title: journal.title,
      canvasSnapshot: journal.canvasSnapshot,
    };
    return await this.rdbStore.insert('journals', bucket);
  }

  async getJournals(): Promise<Journal[]> {
    if (!this.rdbStore) return [];
    const resultSet = await this.rdbStore.querySql('SELECT * FROM journals ORDER BY id DESC');
    const list: Journal[] = [];
    while (resultSet.goToNextRow()) {
      list.push({
        id: resultSet.getLong(resultSet.getColumnIndex('id')),
        title: resultSet.getString(resultSet.getColumnIndex('title')),
        canvasSnapshot: resultSet.getString(resultSet.getColumnIndex('canvasSnapshot')),
      });
    }
    resultSet.close();
    return list;
  }

  // Canvas Projects
  async insertCanvasProject(project: CanvasProject): Promise<number> {
    if (!this.rdbStore) return -1;
    const bucket: relationalStore.ValuesBucket = {
      title: project.title,
      thumbnailUri: project.thumbnailUri,
      items: JSON.stringify(project.items),
      background: JSON.stringify(project.background),
      createdAt: project.createdAt,
      updatedAt: project.updatedAt,
    };
    return await this.rdbStore.insert('canvas_projects', bucket);
  }

  async getCanvasProjects(): Promise<CanvasProject[]> {
    if (!this.rdbStore) return [];
    const resultSet = await this.rdbStore.querySql(
      'SELECT * FROM canvas_projects ORDER BY updatedAt DESC'
    );
    const list: CanvasProject[] = [];
    while (resultSet.goToNextRow()) {
      list.push(this.parseCanvasProject(resultSet));
    }
    resultSet.close();
    return list;
  }

  async getLatestCanvasProject(): Promise<CanvasProject | null> {
    if (!this.rdbStore) return null;
    const resultSet = await this.rdbStore.querySql(
      'SELECT * FROM canvas_projects ORDER BY updatedAt DESC LIMIT 1'
    );
    let project: CanvasProject | null = null;
    if (resultSet.goToNextRow()) {
      project = this.parseCanvasProject(resultSet);
    }
    resultSet.close();
    return project;
  }

  private parseCanvasProject(resultSet: relationalStore.ResultSet): CanvasProject {
    return {
      id: resultSet.getLong(resultSet.getColumnIndex('id')),
      title: resultSet.getString(resultSet.getColumnIndex('title')),
      thumbnailUri: resultSet.getString(resultSet.getColumnIndex('thumbnailUri')),
      items: JSON.parse(resultSet.getString(resultSet.getColumnIndex('items'))),
      background: JSON.parse(resultSet.getString(resultSet.getColumnIndex('background'))),
      createdAt: resultSet.getLong(resultSet.getColumnIndex('createdAt')),
      updatedAt: resultSet.getLong(resultSet.getColumnIndex('updatedAt')),
    };
  }
}
