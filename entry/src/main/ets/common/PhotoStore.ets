import { fileIo as fs } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { Logger } from './Logger';
import { newId } from './Ids';
import { Store } from './Store';

export class PhotoStore {
  /** 打开系统相册选择图片，返回临时 uri 列表。 */
  static async pickImages(maxCount: number): Promise<string[]> {
    try {
      const picker = new photoAccessHelper.PhotoViewPicker();
      const options = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = maxCount;
      const result: photoAccessHelper.PhotoSelectResult = await picker.select(options);
      Logger.info('picked ' + result.photoUris.length + ' photo uri(s)');
      return result.photoUris;
    } catch (err) {
      Logger.warn('pickImages failed: ' + JSON.stringify(err));
      return [];
    }
  }

  private static extOf(uri: string): string {
    let path: string = uri;
    const q: number = path.indexOf('?');
    if (q >= 0) {
      path = path.substring(0, q);
    }
    const dot: number = path.lastIndexOf('.');
    if (dot < 0) {
      return 'jpg';
    }
    const ext: string = path.substring(dot + 1).toLowerCase();
    if (ext === 'png' || ext === 'jpg' || ext === 'jpeg' || ext === 'webp' || ext === 'heic' || ext === 'gif') {
      return ext;
    }
    return 'jpg';
  }

  /** 把 uri 指向的图片拷贝到应用沙箱，返回保存的文件名。授权 uri 不可持久化。 */
  static importUri(uri: string): string {
    Store.ensureDirs();
    const name: string = newId() + '.' + PhotoStore.extOf(uri);
    const dest: string = Store.imagePath(name);
    let src: fs.File | null = null;
    let out: fs.File | null = null;
    let ok: boolean = false;
    try {
      src = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      out = fs.openSync(dest, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      const buffer: ArrayBuffer = new ArrayBuffer(64 * 1024);
      let readLen: number = fs.readSync(src.fd, buffer);
      let total: number = 0;
      while (readLen > 0) {
        // 不传 offset，让 filePointer 依次后移，否则每块都会覆盖到文件开头
        fs.writeSync(out.fd, buffer, { length: readLen });
        total += readLen;
        readLen = fs.readSync(src.fd, buffer);
      }
      ok = total > 0;
      return ok ? name : '';
    } catch (err) {
      Logger.error('copy image failed: ' + JSON.stringify(err) + ' uri=' + uri);
      return '';
    } finally {
      if (out !== null) {
        try {
          fs.closeSync(out);
        } catch (e) {
        }
      }
      if (src !== null) {
        try {
          fs.closeSync(src);
        } catch (e) {
        }
      }
      if (!ok) {
        PhotoStore.remove(name);
      }
    }
  }

  static importUris(uris: string[]): string[] {
    const names: string[] = [];
    for (let i = 0; i < uris.length; i++) {
      const name: string = PhotoStore.importUri(uris[i]);
      if (name !== '') {
        names.push(name);
      }
    }
    return names;
  }

  static displayPath(name: string): string {
    return 'file://' + Store.imagePath(name);
  }

  static exists(name: string): boolean {
    return fs.accessSync(Store.imagePath(name));
  }

  static remove(name: string): void {
    try {
      if (fs.accessSync(Store.imagePath(name))) {
        fs.unlinkSync(Store.imagePath(name));
      }
    } catch (err) {
      Logger.warn('remove image failed: ' + JSON.stringify(err));
    }
  }
}
