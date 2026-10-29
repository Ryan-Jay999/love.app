import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';

const ITERATIONS: number = 120000;
const IV_LEN: number = 12;
const TAG_LEN: number = 16;
const SALT_LEN: number = 16;
const KEY_LEN: number = 32;

export interface EncryptedBlob {
  ivHex: string;
  tagHex: string;
  cipherHex: string;
}

function toHex(data: Uint8Array): string {
  let out: string = '';
  for (let i = 0; i < data.length; i++) {
    const v: number = data[i];
    out += (v < 16 ? '0' : '') + v.toString(16);
  }
  return out;
}

function fromHex(hex: string): Uint8Array {
  const len: number = Math.floor(hex.length / 2);
  const out = new Uint8Array(len);
  for (let i = 0; i < len; i++) {
    out[i] = parseInt(hex.substring(i * 2, i * 2 + 2), 16);
  }
  return out;
}

export class CryptoUtil {
  static readonly defaultIterations: number = ITERATIONS;
  static readonly saltLength: number = SALT_LEN;

  static hex(data: Uint8Array): string {
    return toHex(data);
  }

  static unhex(hex: string): Uint8Array {
    return fromHex(hex);
  }

  static randomBytes(len: number): Uint8Array {
    const random = cryptoFramework.createRandom();
    const blob: cryptoFramework.DataBlob = random.generateRandomSync(len);
    return blob.data;
  }

  static utf8Encode(text: string): Uint8Array {
    const encoder = new util.TextEncoder();
    return encoder.encodeInto(text);
  }

  static utf8Decode(data: Uint8Array): string {
    const decoder = new util.TextDecoder();
    return decoder.decodeToString(data);
  }

  /** PBKDF2|SHA256 派生 32 字节密钥。必须用异步接口，避免阻塞主线程。 */
  static async deriveKey(password: string, salt: Uint8Array, iterations: number): Promise<Uint8Array> {
    const kdf = cryptoFramework.createKdf('PBKDF2|SHA256');
    const spec: cryptoFramework.PBKDF2Spec = {
      algName: 'PBKDF2|SHA256',
      password: password,
      salt: salt,
      iterations: iterations,
      keySize: KEY_LEN
    };
    const secret: cryptoFramework.DataBlob = await kdf.generateSecret(spec);
    return secret.data;
  }

  /** AES-256-GCM 加密；输出密文与 16 字节 authTag 分离保存。 */
  static async encrypt(key: Uint8Array, plainText: string): Promise<EncryptedBlob> {
    const keyBlob: cryptoFramework.DataBlob = { data: key };
    const ivBlob: cryptoFramework.DataBlob = { data: CryptoUtil.randomBytes(IV_LEN) };
    const aadBlob: cryptoFramework.DataBlob = { data: new Uint8Array(0) };
    const tagBlob: cryptoFramework.DataBlob = { data: new Uint8Array(TAG_LEN) };
    const params: cryptoFramework.GcmParamsSpec = {
      algName: 'GcmParamsSpec',
      iv: ivBlob,
      aad: aadBlob,
      authTag: tagBlob
    };
    const gen = cryptoFramework.createSymKeyGenerator('AES256');
    const symKey: cryptoFramework.SymKey = await gen.convertKey(keyBlob);
    const cipher = cryptoFramework.createCipher('AES256|GCM|NoPadding');
    await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, symKey, params);
    const input: cryptoFramework.DataBlob = { data: CryptoUtil.utf8Encode(plainText) };
    const output: cryptoFramework.DataBlob = await cipher.doFinal(input);
    const full: Uint8Array = output.data;
    const cipherPart = new Uint8Array(full.length - TAG_LEN);
    cipherPart.set(full.subarray(0, full.length - TAG_LEN), 0);
    const tagPart = new Uint8Array(TAG_LEN);
    tagPart.set(full.subarray(full.length - TAG_LEN), 0);
    const result: EncryptedBlob = {
      ivHex: toHex(ivBlob.data),
      tagHex: toHex(tagPart),
      cipherHex: toHex(cipherPart)
    };
    return result;
  }

  /** AES-256-GCM 解密；密码错误时认证失败会抛出异常。 */
  static async decrypt(key: Uint8Array, blob: EncryptedBlob): Promise<string> {
    const keyBlob: cryptoFramework.DataBlob = { data: key };
    const ivBlob: cryptoFramework.DataBlob = { data: fromHex(blob.ivHex) };
    const aadBlob: cryptoFramework.DataBlob = { data: new Uint8Array(0) };
    const tagBlob: cryptoFramework.DataBlob = { data: fromHex(blob.tagHex) };
    const params: cryptoFramework.GcmParamsSpec = {
      algName: 'GcmParamsSpec',
      iv: ivBlob,
      aad: aadBlob,
      authTag: tagBlob
    };
    const gen = cryptoFramework.createSymKeyGenerator('AES256');
    const symKey: cryptoFramework.SymKey = await gen.convertKey(keyBlob);
    const cipher = cryptoFramework.createCipher('AES256|GCM|NoPadding');
    await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, symKey, params);
    const input: cryptoFramework.DataBlob = { data: fromHex(blob.cipherHex) };
    const output: cryptoFramework.DataBlob = await cipher.doFinal(input);
    return CryptoUtil.utf8Decode(output.data);
  }
}
