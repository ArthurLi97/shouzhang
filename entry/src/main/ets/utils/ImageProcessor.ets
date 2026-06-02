// utils/ImageProcessor.ets
// 图片处理工具：URI→PixelMap、主体分割、白边生成、保存文件

import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { subjectSegmentation } from '@kit.CoreVisionKit';

/** 最大图片尺寸，超过则缩放，防止 OOM */
const MAX_IMAGE_DIMENSION = 2048;

export class ImageProcessor {
  /**
   * 将图片 URI 转为 PixelMap，带大图保护
   */
  static async uriToPixelMap(uri: string): Promise<image.PixelMap | null> {
    let imageSource: image.ImageSource | null = null;
    try {
      imageSource = image.createImageSource(uri);

      // 先读取图片信息，检查尺寸
      const imageInfo = await imageSource.getImageInfo();
      const width = imageInfo.size.width;
      const height = imageInfo.size.height;

      let pixelMap: image.PixelMap;
      if (width > MAX_IMAGE_DIMENSION || height > MAX_IMAGE_DIMENSION) {
        // 计算缩放比例，保持宽高比
        const scale = Math.min(MAX_IMAGE_DIMENSION / width, MAX_IMAGE_DIMENSION / height);
        const desiredWidth = Math.round(width * scale);
        const desiredHeight = Math.round(height * scale);
        console.log(`ImageProcessor: downscale ${width}x${height} -> ${desiredWidth}x${desiredHeight}`);
        pixelMap = await imageSource.createPixelMap({
          desiredSize: { width: desiredWidth, height: desiredHeight },
        });
      } else {
        pixelMap = await imageSource.createPixelMap();
      }

      return pixelMap;
    } catch (err) {
      console.error('uriToPixelMap error:', JSON.stringify(err));
      return null;
    } finally {
      imageSource?.release?.();
    }
  }

  /**
   * VisionKit 主体分割
   * 使用 @kit.CoreVisionKit 的 subjectSegmentation 实现真实抠图
   * @returns 抠好的主体 PixelMap（透明背景），或 null 表示失败/无主体
   */
  /** 带超时的 Promise 包装 */
  private static withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
    return new Promise<T>((resolve: (value: T) => void, reject: (reason: Error) => void) => {
      const timer = setTimeout(() => reject(new Error('timeout')), ms);
      promise.then((result: T) => {
        clearTimeout(timer);
        resolve(result);
      }).catch((err: Error) => {
        clearTimeout(timer);
        reject(err);
      });
    });
  }

  static async segmentSubject(pixelMap: image.PixelMap): Promise<image.PixelMap | null> {
    // 检测设备是否支持主体分割能力
    if (!canIUse('SystemCapability.AI.Vision.SubjectSegmentation')) {
      console.warn('segmentSubject: device does not support SystemCapability.AI.Vision.SubjectSegmentation');
      return null;
    }

    try {
      // 初始化分割服务（超时 5 秒）
      const inited = await ImageProcessor.withTimeout(subjectSegmentation.init(), 5000);
      if (!inited) {
        console.warn('subjectSegmentation init failed, fallback to no-segmentation');
        return null;
      }

      const info = await pixelMap.getImageInfo();
      const width = info.size.width;
      const height = info.size.height;

      // 执行分割（超时 10 秒）
      const result = await ImageProcessor.withTimeout(
        subjectSegmentation.doSegmentation(
          { pixelMap },
          {
            maxCount: 1,
            enableSubjectDetails: false,
            enableSubjectForegroundImage: true,
          }
        ),
        10000
      );

      // 释放服务
      try { await subjectSegmentation.release(); } catch (_) { /* ignore */ }

      if (!result || result.subjectCount === 0 || !result.fullSubject) {
        console.warn('subjectSegmentation: no subject detected');
        return null;
      }

      // 优先使用 SDK 直接返回的 foregroundImage（已抠好，带透明背景）
      const foreground = result.fullSubject.foregroundImage;
      if (foreground) {
        console.log('subjectSegmentation: using foregroundImage');
        return foreground;
      }

      // fallback：使用 mattingList 手动生成 mask，再应用
      console.warn('subjectSegmentation: foregroundImage empty, fallback to mattingList');
      const matting = result.fullSubject.mattingList;
      const maskBuffer = new ArrayBuffer(width * height);
      const maskView = new Uint8Array(maskBuffer);
      for (let i = 0; i < matting.length; i++) {
        maskView[i] = matting[i] > 0 ? 255 : 0;
      }

      const masked = await ImageProcessor.applyMask(pixelMap, maskBuffer);
      return masked;
    } catch (err) {
      console.error('subjectSegmentation error:', JSON.stringify(err));
      // 确保释放服务
      try { await subjectSegmentation.release(); } catch (_) { /* ignore */ }
      return null;
    }
  }

  /**
   * 使用 PixelMap 和 mask 生成透明背景图
   * @param pixelMap 原图 PixelMap
   * @param mask VisionKit 返回的 mask (ArrayBuffer)
   */
  static async applyMask(
    pixelMap: image.PixelMap,
    mask: ArrayBuffer
  ): Promise<image.PixelMap | null> {
    try {
      const info = await pixelMap.getImageInfo();
      const width = info.size.width;
      const height = info.size.height;

      // 读取原图像素数据
      const srcBuffer = new ArrayBuffer(width * height * 4);
      await pixelMap.readPixelsToBuffer(srcBuffer);
      const srcView = new Uint8Array(srcBuffer);

      // mask 数据
      const maskView = new Uint8Array(mask);

      // 创建输出像素数据 (RGBA)
      const outBuffer = new ArrayBuffer(width * height * 4);
      const outView = new Uint8Array(outBuffer);

      for (let i = 0; i < width * height; i++) {
        const m = maskView[i] ?? 0;
        outView[i * 4] = srcView[i * 4];       // R
        outView[i * 4 + 1] = srcView[i * 4 + 1]; // G
        outView[i * 4 + 2] = srcView[i * 4 + 2]; // B
        outView[i * 4 + 3] = m > 128 ? srcView[i * 4 + 3] : 0; // A
      }

      // 从像素数据创建新的 PixelMap
      const newPixelMap = await image.createPixelMap(outBuffer, {
        size: { width, height },
        pixelFormat: image.PixelMapFormat.RGBA_8888,
      });
      return newPixelMap;
    } catch (err) {
      console.error('applyMask error:', JSON.stringify(err));
      return null;
    } finally {
      // 无论成功失败，原图都不再需要
      pixelMap.release?.();
    }
  }

  /**
   * 使用 PixelMap 处理 mask 并生成白边
   * @param pixelMap 原图 PixelMap
   * @param mask VisionKit 返回的 mask (ArrayBuffer)
   * @param borderSize 白边大小 (0-2)
   */
  static async applyMaskAndBorder(
    pixelMap: image.PixelMap,
    mask: ArrayBuffer,
    borderSize: number = 0
  ): Promise<image.PixelMap | null> {
    try {
      const info = await pixelMap.getImageInfo();
      const width = info.size.width;
      const height = info.size.height;

      // 读取原图像素数据
      const srcBuffer = new ArrayBuffer(width * height * 4);
      await pixelMap.readPixelsToBuffer(srcBuffer);
      const srcView = new Uint8Array(srcBuffer);

      // mask 数据
      const maskView = new Uint8Array(mask);

      // 创建输出像素数据 (RGBA)
      const outBuffer = new ArrayBuffer(width * height * 4);
      const outView = new Uint8Array(outBuffer);

      // 膨胀半径（根据 borderSize 0/1/2 对应 0/4/8 像素）
      const dilateRadius = borderSize * 4;

      // 如果不需要白边，直接应用 mask
      if (dilateRadius === 0) {
        for (let i = 0; i < width * height; i++) {
          const m = maskView[i] ?? 0;
          outView[i * 4] = srcView[i * 4];       // R
          outView[i * 4 + 1] = srcView[i * 4 + 1]; // G
          outView[i * 4 + 2] = srcView[i * 4 + 2]; // B
          outView[i * 4 + 3] = m > 128 ? srcView[i * 4 + 3] : 0; // A
        }
      } else {
        // 先生成膨胀后的白边 mask
        const dilatedMask = ImageProcessor.dilateMask(maskView, width, height, dilateRadius);

        for (let i = 0; i < width * height; i++) {
          const origM = maskView[i] ?? 0;
          const dilatedM = dilatedMask[i];

          if (origM > 128) {
            // 主体区域：使用原图颜色
            outView[i * 4] = srcView[i * 4];
            outView[i * 4 + 1] = srcView[i * 4 + 1];
            outView[i * 4 + 2] = srcView[i * 4 + 2];
            outView[i * 4 + 3] = srcView[i * 4 + 3];
          } else if (dilatedM > 0) {
            // 白边区域：白色
            outView[i * 4] = 255;
            outView[i * 4 + 1] = 255;
            outView[i * 4 + 2] = 255;
            outView[i * 4 + 3] = 255;
          } else {
            // 背景：透明
            outView[i * 4] = 0;
            outView[i * 4 + 1] = 0;
            outView[i * 4 + 2] = 0;
            outView[i * 4 + 3] = 0;
          }
        }
      }

      // 从像素数据创建新的 PixelMap
      const newPixelMap = await image.createPixelMap(outBuffer, {
        size: { width, height },
        pixelFormat: image.PixelMapFormat.RGBA_8888,
      });
      return newPixelMap;
    } catch (err) {
      console.error('applyMaskAndBorder error:', JSON.stringify(err));
      return null;
    } finally {
      // 无论成功失败，原图都不再需要
      pixelMap.release?.();
    }
  }

  /**
   * 二值 mask 膨胀（正方形结构元素）
   */
  private static dilateMask(mask: Uint8Array, width: number, height: number, radius: number): Uint8Array {
    const result = new Uint8Array(width * height);
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        const idx = y * width + x;
        if (mask[idx] > 128) {
          result[idx] = 255;
          continue;
        }
        // 检查邻域
        let found = false;
        for (let dy = -radius; dy <= radius && !found; dy++) {
          for (let dx = -radius; dx <= radius && !found; dx++) {
            const ny = y + dy;
            const nx = x + dx;
            if (ny >= 0 && ny < height && nx >= 0 && nx < width) {
              if (mask[ny * width + nx] > 128) {
                found = true;
              }
            }
          }
        }
        result[idx] = found ? 255 : 0;
      }
    }
    return result;
  }

  /**
   * 将 PixelMap 保存为 PNG 文件到应用私有目录
   * @returns 保存后的文件 URI
   */
  static async savePixelMapToFile(
    pixelMap: image.PixelMap,
    context: Context,
    fileName?: string
  ): Promise<string | null> {
    try {
      const dir = context.filesDir + '/stickers';
      try {
        fileIo.accessSync(dir);
      } catch {
        fileIo.mkdirSync(dir);
      }

      const name = fileName ?? `sticker_${Date.now()}.png`;
      const filePath = dir + '/' + name;

      const imagePacker = image.createImagePacker();
      const packOpts: image.PackingOption = {
        format: 'image/png',
        quality: 100,
      };
      const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
      await imagePacker.packToFile(pixelMap, file.fd, packOpts);
      imagePacker.release?.();
      fileIo.closeSync(file);

      return `file://${filePath}`;
    } catch (err) {
      console.error('savePixelMapToFile error:', JSON.stringify(err));
      return null;
    } finally {
      pixelMap.release?.();
    }
  }

  /**
   * 完整流程：URI → 主体分割 → 保存文件
   * @returns 处理后的贴纸文件 URI，或 null 表示失败
   */
  static async processSticker(
    uri: string,
    context: Context,
    borderSize: number = 0
  ): Promise<string | null> {
    // 1. URI → PixelMap
    const pixelMap = await ImageProcessor.uriToPixelMap(uri);
    if (!pixelMap) {
      console.error('processSticker: uriToPixelMap failed');
      return null;
    }

    // 2. VisionKit 主体分割
    const foreground = await ImageProcessor.segmentSubject(pixelMap);
    if (!foreground) {
      console.warn('processSticker: segmentation failed or no subject, fallback to original image');
      // 分割失败或无主体，返回原图（降级）
      return await ImageProcessor.savePixelMapToFile(pixelMap, context);
    }

    // 3. 如果需要白边，对 foregroundImage 应用白边
    if (borderSize > 0) {
      // 生成 mask：foregroundImage 中非透明区域即为 mask
      const info = await foreground.getImageInfo();
      const w = info.size.width;
      const h = info.size.height;
      const fgBuffer = new ArrayBuffer(w * h * 4);
      await foreground.readPixelsToBuffer(fgBuffer);
      const fgView = new Uint8Array(fgBuffer);
      const maskBuffer = new ArrayBuffer(w * h);
      const maskView = new Uint8Array(maskBuffer);
      for (let i = 0; i < w * h; i++) {
        maskView[i] = fgView[i * 4 + 3] > 0 ? 255 : 0;
      }
      const bordered = await ImageProcessor.applyMaskAndBorder(foreground, maskBuffer, borderSize);
      if (bordered) {
        return await ImageProcessor.savePixelMapToFile(bordered, context);
      }
      // 白边失败，直接保存前景图
      return await ImageProcessor.savePixelMapToFile(foreground, context);
    }

    // 4. 保存为 PNG
    return await ImageProcessor.savePixelMapToFile(foreground, context);
  }
}
