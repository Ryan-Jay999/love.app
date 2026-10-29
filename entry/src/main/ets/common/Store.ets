import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { AppData, DATA_KEY, emptyAppData, normalizeAppData, RawAppData } from '../model/Types';
import { CryptoUtil, EncryptedBlob } from './CryptoUtil';
import { Logger } from './Logger';

const PLAIN_FILE: string = 'lovedata.json';
const ENC_FILE: string = 'lovedata.bin';
const IMAGE_DIR: string = 'images';
const MAGIC: string = 'LOVE1';
export const LOCK_KEY: string = 'loveAppLocked';

interface EncFile {
  iterations: number;
  saltHex: string;
  ivHex: string;
  tagHex: string;
  cipherHex: string;
}

export class Store {
  private static ctx: common.UIAbilityContext | null = null;
  private static filesRoot: string = '';
  private static cacheRoot: string = '';
  private static key: Uint8Array | null = null;
  private static salt: Uint8Array | null = null;
  private static iterations: number = CryptoUtil.defaultIterations;
  private static lockEnabled: boolean = false;
  private static unlocked: boolean = false;
  private static saveTimer: number = -1;
  private static saving: boolean = false;

  static async init(ctx: common.UIAbilityContext): Promise<void> {
    Store.ctx = ctx;
    Store.filesRoot = ctx.filesDir;
    Store.cacheRoot = ctx.cacheDir;
    Store.ensureDirs();
    Store.lockEnabled = fs.accessSync(Store.encPath());
    try {
      if (!Store.lockEnabled) {
        const data: AppData = Store.readPlain();
        AppStorage.setOrCreate<AppData>(DATA_KEY, data);
        Store.unlocked = true;
      } else {
        // 加密状态下不加载任何业务数据，等待用户解锁。
        Store.unlocked = false;
        AppStorage.setOrCreate<AppData>(DATA_KEY, emptyAppData());
      }
    } catch (err) {
      Logger.error('Store.init failed: ' + JSON.stringify(err));
      AppStorage.setOrCreate<AppData>(DATA_KEY, emptyAppData());
      Store.unlocked = true;
    }
    Store.syncLockState();
  }

  static syncLockState(): void {
    AppStorage.setOrCreate<boolean>(LOCK_KEY, Store.lockEnabled && !Store.unlocked);
  }

  static ensureDirs(): void {
    if (Store.filesRoot === '') {
      return;
    }
    const images: string = Store.filesRoot + '/' + IMAGE_DIR;
    if (!fs.accessSync(images)) {
      fs.mkdirSync(images);
    }
  }

  static get filesDir(): string {
    return Store.filesRoot;
  }

  static context(): common.UIAbilityContext | null {
    return Store.ctx;
  }

  static get cacheDir(): string {
    return Store.cacheRoot;
  }

  static imagesDir(): string {
    return Store.filesRoot + '/' + IMAGE_DIR;
  }

  static imagePath(name: string): string {
    return Store.imagesDir() + '/' + name;
  }

  private static encPath(): string {
    return Store.filesRoot + '/' + ENC_FILE;
  }

  private static plainPath(): string {
    return Store.filesRoot + '/' + PLAIN_FILE;
  }

  static hasLock(): boolean {
    return Store.lockEnabled;
  }

  static isLocked(): boolean {
    return Store.lockEnabled && !Store.unlocked;
  }

  static getData(): AppData {
    const data: AppData | undefined = AppStorage.get<AppData>(DATA_KEY);
    return data === undefined ? emptyAppData() : data;
  }

  /** 唯一写入口：整对象替换，保证 ArkUI 状态刷新。 */
  static commit(mutator: (d: AppData) => void): void {
    const current: AppData = Store.getData();
    const next: AppData = JSON.parse(JSON.stringify(current)) as AppData;
    mutator(next);
    AppStorage.setOrCreate<AppData>(DATA_KEY, next);
    Store.scheduleSave();
  }

  private static scheduleSave(): void {
    if (Store.saveTimer >= 0) {
      clearTimeout(Store.saveTimer);
    }
    Store.saveTimer = setTimeout(() => {
      Store.saveTimer = -1;
      Store.flushNow();
    }, 400);
  }

  static async flushNow(): Promise<void> {
    if (!Store.unlocked || Store.saving) {
      return;
    }
    Store.saving = true;
    try {
      const data: AppData = Store.getData();
      const text: string = JSON.stringify(data);
      if (Store.lockEnabled && Store.key !== null) {
        await Store.writeEncrypted(text);
        if (fs.accessSync(Store.plainPath())) {
          fs.unlinkSync(Store.plainPath());
        }
      } else {
        Store.writeTextFile(Store.plainPath(), text);
      }
    } catch (err) {
      Logger.error('flushNow failed: ' + JSON.stringify(err));
    } finally {
      Store.saving = false;
    }
  }

  private static writeTextFile(path: string, text: string): void {
    const file = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
    try {
      fs.writeSync(file.fd, text);
    } finally {
      fs.closeSync(file);
    }
  }

  private static readTextFile(path: string): string {
    const file = fs.openSync(path, fs.OpenMode.READ_ONLY);
    try {
      const stat = fs.statSync(file.fd);
      const buffer = new ArrayBuffer(stat.size);
      const readLen: number = fs.readSync(file.fd, buffer);
      const bytes = new Uint8Array(buffer.slice(0, readLen));
      return CryptoUtil.utf8Decode(bytes);
    } finally {
      fs.closeSync(file);
    }
  }

  private static readPlain(): AppData {
    if (!fs.accessSync(Store.plainPath())) {
      return emptyAppData();
    }
    const text: string = Store.readTextFile(Store.plainPath());
    if (text.trim() === '') {
      return emptyAppData();
    }
    const raw: RawAppData = JSON.parse(text) as RawAppData;
    return normalizeAppData(raw);
  }

  private static async writeEncrypted(text: string): Promise<void> {
    if (Store.key === null || Store.salt === null) {
      return;
    }
    const blob = await CryptoUtil.encrypt(Store.key, text);
    const content: string = MAGIC + '\n' + Store.iterations + '\n' +
      CryptoUtil.hex(Store.salt) + '\n' + blob.ivHex + '\n' + blob.tagHex + '\n' + blob.cipherHex;
    Store.writeTextFile(Store.encPath(), content);
  }

  private static parseEncFile(text: string): EncFile | null {
    const lines: string[] = text.split('\n');
    if (lines.length < 6 || lines[0].trim() !== MAGIC) {
      return null;
    }
    const iterations: number = parseInt(lines[1], 10);
    if (isNaN(iterations) || iterations <= 0) {
      return null;
    }
    const parsed: EncFile = {
      iterations: iterations,
      saltHex: lines[2].trim(),
      ivHex: lines[3].trim(),
      tagHex: lines[4].trim(),
      cipherHex: lines[5].trim()
    };
    return parsed;
  }

  /** 解锁。密码错误返回 false。 */
  static async unlock(password: string): Promise<boolean> {
    try {
      const text: string = Store.readTextFile(Store.encPath());
      const enc: EncFile | null = Store.parseEncFile(text);
      if (enc === null) {
        return false;
      }
      const salt: Uint8Array = CryptoUtil.unhex(enc.saltHex);
      const key: Uint8Array = await CryptoUtil.deriveKey(password, salt, enc.iterations);
      const body: EncryptedBlob = { ivHex: enc.ivHex, tagHex: enc.tagHex, cipherHex: enc.cipherHex };
      const plain: string = await CryptoUtil.decrypt(key, body);
      const raw: RawAppData = JSON.parse(plain) as RawAppData;
      const data: AppData = normalizeAppData(raw);
      Store.key = key;
      Store.salt = salt;
      Store.iterations = enc.iterations;
      Store.unlocked = true;
      AppStorage.setOrCreate<AppData>(DATA_KEY, data);
      Store.syncLockState();
      return true;
    } catch (err) {
      Logger.warn('unlock failed: ' + JSON.stringify(err));
      return false;
    }
  }

  /** 首次开启应用锁：用当前明文数据加密落盘，并删除明文文件。 */
  static async enableLock(password: string): Promise<void> {
    const salt: Uint8Array = CryptoUtil.randomBytes(CryptoUtil.saltLength);
    const key: Uint8Array = await CryptoUtil.deriveKey(password, salt, CryptoUtil.defaultIterations);
    Store.key = key;
    Store.salt = salt;
    Store.iterations = CryptoUtil.defaultIterations;
    Store.lockEnabled = true;
    Store.unlocked = true;
    await Store.writeEncrypted(JSON.stringify(Store.getData()));
    if (fs.accessSync(Store.plainPath())) {
      fs.unlinkSync(Store.plainPath());
    }
    Store.syncLockState();
  }

  /** 修改密码：成功返回 true。 */
  static async changePassword(oldPassword: string, newPassword: string): Promise<boolean> {
    try {
      const text: string = Store.readTextFile(Store.encPath());
      const enc: EncFile | null = Store.parseEncFile(text);
      if (enc === null) {
        return false;
      }
      const oldSalt: Uint8Array = CryptoUtil.unhex(enc.saltHex);
      const oldKey: Uint8Array = await CryptoUtil.deriveKey(oldPassword, oldSalt, enc.iterations);
      const body: EncryptedBlob = { ivHex: enc.ivHex, tagHex: enc.tagHex, cipherHex: enc.cipherHex };
      const plain: string = await CryptoUtil.decrypt(oldKey, body);
      const newSalt: Uint8Array = CryptoUtil.randomBytes(CryptoUtil.saltLength);
      const newKey: Uint8Array = await CryptoUtil.deriveKey(newPassword, newSalt, CryptoUtil.defaultIterations);
      Store.key = newKey;
      Store.salt = newSalt;
      Store.iterations = CryptoUtil.defaultIterations;
      Store.lockEnabled = true;
      Store.unlocked = true;
      await Store.writeEncrypted(plain);
      Store.syncLockState();
      return true;
    } catch (err) {
      Logger.warn('changePassword failed: ' + JSON.stringify(err));
      return false;
    }
  }

  /** 关闭密码锁：解密后改写为明文。成功返回 true。 */
  static async disableLock(password: string): Promise<boolean> {
    try {
      const text: string = Store.readTextFile(Store.encPath());
      const enc: EncFile | null = Store.parseEncFile(text);
      if (enc === null) {
        return false;
      }
      const salt: Uint8Array = CryptoUtil.unhex(enc.saltHex);
      const key: Uint8Array = await CryptoUtil.deriveKey(password, salt, enc.iterations);
      const body: EncryptedBlob = { ivHex: enc.ivHex, tagHex: enc.tagHex, cipherHex: enc.cipherHex };
      const plain: string = await CryptoUtil.decrypt(key, body);
      Store.writeTextFile(Store.plainPath(), plain);
      if (fs.accessSync(Store.encPath())) {
        fs.unlinkSync(Store.encPath());
      }
      Store.lockEnabled = false;
      Store.unlocked = true;
      Store.key = null;
      Store.salt = null;
      AppStorage.setOrCreate<AppData>(DATA_KEY, normalizeAppData(JSON.parse(plain) as RawAppData));
      Store.syncLockState();
      return true;
    } catch (err) {
      Logger.warn('disableLock failed: ' + JSON.stringify(err));
      return false;
    }
  }

  /** 导入备份：整体替换数据并立即落盘。 */
  static async replaceData(raw: RawAppData): Promise<void> {
    const data: AppData = normalizeAppData(raw);
    Store.unlocked = true;
    AppStorage.setOrCreate<AppData>(DATA_KEY, data);
    await Store.flushNow();
  }

  static lockNow(): void {
    if (!Store.lockEnabled) {
      return;
    }
    Store.unlocked = false;
    Store.key = null;
    Store.salt = null;
    AppStorage.setOrCreate<AppData>(DATA_KEY, emptyAppData());
    Store.syncLockState();
  }

  /** 备份工具使用的通用文本读写。 */
  static writeTextTo(path: string, text: string): void {
    Store.writeTextFile(path, text);
  }

  static readTextFrom(path: string): string {
    return Store.readTextFile(path);
  }

  static normalize(raw: RawAppData): AppData {
    return normalizeAppData(raw);
  }
}
