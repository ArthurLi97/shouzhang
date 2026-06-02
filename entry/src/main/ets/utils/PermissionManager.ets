// utils/PermissionManager.ets
// 运行时权限管理封装

import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { HdsSnackBar } from '../components/hds/HdsSnackBar';

const PERM_CAMERA: Permissions = 'ohos.permission.CAMERA';
const PERM_READ_IMAGEVIDEO: Permissions = 'ohos.permission.READ_IMAGEVIDEO';
const PERM_WRITE_IMAGEVIDEO: Permissions = 'ohos.permission.WRITE_IMAGEVIDEO';

export enum PermissionType {
  CAMERA = 'camera',
  PHOTO_READ = 'photo_read',
  PHOTO_WRITE = 'photo_write',
}

export class PermissionManager {
  /**
   * 检查单个权限是否已授予
   */
  static checkPermission(permission: Permissions): boolean {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const tokenID = AppStorage.get<number>('app_token_id') ?? 0;
      if (tokenID === 0) {
        // 如果无法获取 tokenID，通过 context 方式检查
        return false;
      }
      const status = atManager.verifyAccessTokenSync(tokenID, permission);
      return status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (err) {
      console.error('checkPermission error:', JSON.stringify(err));
      return false;
    }
  }

  /**
   * 请求权限列表
   * @returns 是否所有请求的权限都已授予
   */
  static async requestPermissions(context: Context, permissions: Permissions[]): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(context, permissions);
      return result.authResults.every((r: number) => r === 0);
    } catch (err) {
      console.error('requestPermissions error:', JSON.stringify(err));
      return false;
    }
  }

  /**
   * 请求相机权限
   */
  static async requestCameraPermission(context: Context): Promise<boolean> {
    const granted = await PermissionManager.requestPermissions(context, [PERM_CAMERA]);
    if (!granted) {
      HdsSnackBar.show({ message: '需要相机权限才能拍照，请前往设置开启' });
    }
    return granted;
  }

  /**
   * 请求相册读取权限
   */
  static async requestPhotoReadPermission(context: Context): Promise<boolean> {
    const granted = await PermissionManager.requestPermissions(context, [PERM_READ_IMAGEVIDEO]);
    if (!granted) {
      HdsSnackBar.show({ message: '需要相册权限才能选择图片，请前往设置开启' });
    }
    return granted;
  }

  /**
   * 请求相册写入权限
   */
  static async requestPhotoWritePermission(context: Context): Promise<boolean> {
    const granted = await PermissionManager.requestPermissions(context, [PERM_WRITE_IMAGEVIDEO]);
    if (!granted) {
      HdsSnackBar.show({ message: '需要存储权限才能保存到相册，请前往设置开启' });
    }
    return granted;
  }

  /**
   * 请求相机+读相册权限（拍照和选图前的组合申请）
   */
  static async requestMediaPermissions(context: Context): Promise<boolean> {
    const granted = await PermissionManager.requestPermissions(context, [PERM_CAMERA, PERM_READ_IMAGEVIDEO]);
    if (!granted) {
      HdsSnackBar.show({ message: '需要相机和相册权限才能继续，请前往设置开启' });
    }
    return granted;
  }
}
