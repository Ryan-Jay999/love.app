/**
 * 全局数据模型：全部为纯 interface，保证 JSON 序列化/反序列化可无损往返。
 * 注意：ArkTS 中 @Observed 只能装饰 class，因此本项目统一采用「整对象替换」的刷新策略。
 */
export const SCHEMA_VERSION: number = 1;
export const DATA_KEY: string = 'loveAppData';

export const CAL_SOLAR: string = 'solar';
export const CAL_LUNAR: string = 'lunar';

export const BOARD_TOGETHER: string = 'together';
export const BOARD_GIFT: string = 'gift';

export interface Settings {
  startDate: string;
  partnerName: string;
  myName: string;
  reminderEnabled: boolean;
}

export interface Anniversary {
  id: string;
  title: string;
  calendar: string;
  month: number;
  day: number;
  isLeapMonth: boolean;
  advanceDays: number;
  emoji: string;
  remind: boolean;
  color: string;
}

export interface Memory {
  id: string;
  date: string;
  place: string;
  activity: string;
  feeling: string;
  note: string;
  images: string[];
  mood: string;
  createdAt: number;
}

export interface SubTask {
  id: string;
  text: string;
  done: boolean;
}

export interface WishItem {
  id: string;
  board: string;
  title: string;
  note: string;
  done: boolean;
  doneDate: string;
  subtasks: SubTask[];
  isTravel: boolean;
  createdAt: number;
}

export interface MemoItem {
  id: string;
  category: string;
  value: string;
  note: string;
}

export interface MoodRecord {
  id: string;
  date: string;
  mood: string;
  note: string;
}

export interface AppData {
  schemaVersion: number;
  settings: Settings;
  anniversaries: Anniversary[];
  memories: Memory[];
  wishes: WishItem[];
  memos: MemoItem[];
  moods: MoodRecord[];
}

export function emptySettings(): Settings {
  const s: Settings = {
    startDate: '',
    partnerName: 'TA',
    myName: '我',
    reminderEnabled: false
  };
  return s;
}

export function emptyAppData(): AppData {
  const d: AppData = {
    schemaVersion: SCHEMA_VERSION,
    settings: emptySettings(),
    anniversaries: [],
    memories: [],
    wishes: [],
    memos: [],
    moods: []
  };
  return d;
}

/** 备份/本地文件读取出来的原始对象，字段可能缺失。 */
export interface RawAppData {
  schemaVersion?: number;
  settings?: Settings;
  anniversaries?: Anniversary[];
  memories?: Memory[];
  wishes?: WishItem[];
  memos?: MemoItem[];
  moods?: MoodRecord[];
}

/** 从任意 JSON 对象补齐缺失字段，避免旧备份/半成品数据导致崩溃。 */
export function normalizeAppData(raw: RawAppData): AppData {
  const base = emptyAppData();
  const d: AppData = {
    schemaVersion: SCHEMA_VERSION,
    settings: {
      startDate: raw.settings?.startDate ?? base.settings.startDate,
      partnerName: raw.settings?.partnerName ?? base.settings.partnerName,
      myName: raw.settings?.myName ?? base.settings.myName,
      reminderEnabled: raw.settings?.reminderEnabled ?? base.settings.reminderEnabled
    },
    anniversaries: raw.anniversaries ?? [],
    memories: raw.memories ?? [],
    wishes: raw.wishes ?? [],
    memos: raw.memos ?? [],
    moods: raw.moods ?? []
  };
  return d;
}
