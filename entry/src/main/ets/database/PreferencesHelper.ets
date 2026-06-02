// database/PreferencesHelper.ets

import { preferences } from '@kit.ArkData';

const PREF_NAME = 'snapsticker_prefs';

export class PreferencesHelper {
  private static instance: PreferencesHelper | null = null;
  private pref: preferences.Preferences | null = null;

  static getInstance(): PreferencesHelper {
    if (!PreferencesHelper.instance) {
      PreferencesHelper.instance = new PreferencesHelper();
    }
    return PreferencesHelper.instance;
  }

  async init(context: Context): Promise<void> {
    try {
      this.pref = await preferences.getPreferences(context, PREF_NAME);
    } catch (err) {
      console.error('PreferencesHelper init error:', JSON.stringify(err));
    }
  }

  async setString(key: string, value: string): Promise<void> {
    try {
      await this.pref?.put(key, value);
      await this.pref?.flush();
    } catch (err) {
      console.error('setString error:', JSON.stringify(err));
    }
  }

  getString(key: string, defaultValue: string = ''): string {
    try {
      return this.pref?.getSync(key, defaultValue) as string ?? defaultValue;
    } catch (err) {
      console.error('getString error:', JSON.stringify(err));
      return defaultValue;
    }
  }

  async setNumber(key: string, value: number): Promise<void> {
    try {
      await this.pref?.put(key, value);
      await this.pref?.flush();
    } catch (err) {
      console.error('setNumber error:', JSON.stringify(err));
    }
  }

  getNumber(key: string, defaultValue: number = 0): number {
    try {
      return this.pref?.getSync(key, defaultValue) as number ?? defaultValue;
    } catch (err) {
      console.error('getNumber error:', JSON.stringify(err));
      return defaultValue;
    }
  }

  async setBoolean(key: string, value: boolean): Promise<void> {
    try {
      await this.pref?.put(key, value);
      await this.pref?.flush();
    } catch (err) {
      console.error('setBoolean error:', JSON.stringify(err));
    }
  }

  getBoolean(key: string, defaultValue: boolean = false): boolean {
    try {
      return this.pref?.getSync(key, defaultValue) as boolean ?? defaultValue;
    } catch (err) {
      console.error('getBoolean error:', JSON.stringify(err));
      return defaultValue;
    }
  }
}
