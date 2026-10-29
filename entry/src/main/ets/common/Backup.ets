import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { picker } from '@kit.CoreFileKit';
import { zlib } from '@kit.BasicServicesKit';
import { AppData, RawAppData } from '../model/Types';
import { DateUtil } from './DateUtil';
import { Logger } from './Logger';
import { Store } from './Store';

export interface BackupResult {
  ok: boolean;
  message: string;
}

/** 以流式读写拷贝，兼容沙箱路径与 picker 返回的文档 URI。 */
function copyAll(src: string, dest: string): void {
  const input = fs.openSync(src, fs.OpenMode.READ_ONLY);
  const output = fs.openSync(dest, fs.OpenMode.CREATE | fs.OpenMode.TRUNC | fs.OpenMode.WRITE_ONLY);
  try {
    const buffer: ArrayBuffer = new ArrayBuffer(64 * 1024);
    let readLen: number = fs.readSync(input.fd, buffer);
    while (readLen > 0) {
      fs.writeSync(output.fd, buffer, { length: readLen });
      readLen = fs.readSync(input.fd, buffer);
    }
  } finally {
    fs.closeSync(input);
    fs.closeSync(output);
  }
}

/** 在解压目录里递归查找指定文件名，返回完整路径；找不到返回空串。 */
function findFile(dir: string, name: string, depth: number): string {
  if (depth > 12) {
    return '';
  }
  let names: string[] = [];
  try {
    names = fs.listFileSync(dir);
  } catch (err) {
    return '';
  }
  for (let i = 0; i < names.length; i++) {
    const path: string = dir + '/' + names[i];
    let isDir: boolean = false;
    try {
      isDir = fs.statSync(path).isDirectory();
    } catch (err) {
      continue;
    }
    if (isDir) {
      const found: string = findFile(path, name, depth + 1);
      if (found !== '') {
        return found;
      }
    } else if (names[i] === name) {
      return path;
    }
  }
  return '';
}

export class Backup {
  /** 把数据与全部照片打包到 cache 目录，返回 zip 路径。 */
  static async exportZip(): Promise<string> {
    const stamp: string = '' + Date.now();
    const stage: string = Store.cacheDir + '/love_stage_' + stamp;
    fs.mkdirSync(stage, true);
    const data: AppData = Store.getData();
    Store.writeTextTo(stage + '/data.json', JSON.stringify(data));
    for (let i = 0; i < data.memories.length; i++) {
      const images: string[] = data.memories[i].images;
      for (let j = 0; j < images.length; j++) {
        const src: string = Store.imagePath(images[j]);
        if (fs.accessSync(src)) {
          copyAll(src, stage + '/' + images[j]);
        }
      }
    }
    const zipPath: string = Store.cacheDir + '/love-backup-' + DateUtil.todayStr() + '.zip';
    if (fs.accessSync(zipPath)) {
      fs.unlinkSync(zipPath);
    }
    const options: zlib.Options = {};
    // 压缩整个暂存目录，保证 zip 内是相对路径，解压更稳定
    await zlib.compressFiles([stage], zipPath, options);
    Logger.info('exportZip done: ' + zipPath);
    return zipPath;
  }

  /** 让用户选择保存位置，并把 zip 写到该位置。 */
  static async saveToUserFile(ctx: common.UIAbilityContext, zipPath: string): Promise<BackupResult> {
    try {
      const documentPicker = new picker.DocumentViewPicker(ctx);
      const options = new picker.DocumentSaveOptions();
      options.newFileNames = ['拾年-' + DateUtil.todayStr() + '.zip'];
      options.fileSuffixChoices = ['.zip'];
      const uris: string[] = await documentPicker.save(options);
      if (uris.length === 0) {
        const cancelled: BackupResult = { ok: false, message: '已取消' };
        return cancelled;
      }
      const dest = fs.openSync(uris[0], fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
      fs.closeSync(dest);
      copyAll(zipPath, uris[0]);
      const ok: BackupResult = { ok: true, message: '备份已保存' };
      return ok;
    } catch (err) {
      Logger.error('saveToUserFile failed: ' + JSON.stringify(err));
      const failed: BackupResult = { ok: false, message: '保存失败，请重试' };
      return failed;
    }
  }

  /** 从用户选择的 zip 中还原全部数据。 */
  static async importFromUser(ctx: common.UIAbilityContext): Promise<BackupResult> {
    try {
      const documentPicker = new picker.DocumentViewPicker(ctx);
      const options = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      options.fileSuffixFilters = ['.zip'];
      const uris: string[] = await documentPicker.select(options);
      if (uris.length === 0) {
        const cancelled: BackupResult = { ok: false, message: '已取消' };
        return cancelled;
      }
      const restoreDir: string = Store.cacheDir + '/love_restore_' + Date.now();
      fs.mkdirSync(restoreDir, true);
      // decompressFile 不能直接处理 picker 的文档 URI，先拷贝到沙箱缓存再解压
      const localZip: string = Store.cacheDir + '/love_restore_' + Date.now() + '.zip';
      copyAll(uris[0], localZip);
      const zipSize: number = fs.statSync(localZip).size;
      Logger.info('import zip: ' + uris[0] + ' size=' + zipSize);
      if (zipSize === 0) {
        const empty: BackupResult = { ok: false, message: '备份文件为空' };
        return empty;
      }
      await zlib.decompressFile(localZip, restoreDir);
      const dataPath: string = findFile(restoreDir, 'data.json', 0);
      if (dataPath === '') {
        const bad: BackupResult = { ok: false, message: '备份文件无效：缺少 data.json' };
        return bad;
      }
      const baseDir: string = dataPath.substring(0, dataPath.lastIndexOf('/'));
      const raw: RawAppData = JSON.parse(Store.readTextFrom(dataPath)) as RawAppData;
      const data: AppData = Store.normalize(raw);
      for (let i = 0; i < data.memories.length; i++) {
        const images: string[] = data.memories[i].images;
        for (let j = 0; j < images.length; j++) {
          const src: string = baseDir + '/' + images[j];
          const dest: string = Store.imagePath(images[j]);
          if (fs.accessSync(src) && !fs.accessSync(dest)) {
            copyAll(src, dest);
          }
        }
      }
      await Store.replaceData(raw);
      const ok: BackupResult = { ok: true, message: '已恢复备份' };
      return ok;
    } catch (err) {
      Logger.error('importFromUser failed: ' + JSON.stringify(err));
      const failed: BackupResult = { ok: false, message: '恢复失败，文件可能已损坏' };
      return failed;
    }
  }

}
