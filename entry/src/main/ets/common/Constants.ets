export interface OptionItem {
  key: string;
  label: string;
}

/** 心情打卡选项（key 用作存储值与展示 emoji 的索引）。 */
export const MOODS: OptionItem[] = [
  { key: 'happy', label: '😊 开心' },
  { key: 'love', label: '🥰 想你' },
  { key: 'calm', label: '😌 平静' },
  { key: 'tired', label: '😮‍💨 有点累' },
  { key: 'sad', label: '🥺 有点小情绪' },
  { key: 'angry', label: '😤 生气' },
  { key: 'miss', label: '💌 想见面' },
  { key: 'excited', label: '🤩 超级期待' }
];

export const MEMO_CATEGORIES: OptionItem[] = [
  { key: '忌口', label: '忌口' },
  { key: '过敏', label: '过敏' },
  { key: '口味', label: '口味偏好' },
  { key: '尺码', label: '尺码' },
  { key: '喜好', label: '喜欢的东西' },
  { key: '讨厌', label: '讨厌的东西' },
  { key: '习惯', label: '生活习惯' },
  { key: '其他', label: '其他' }
];

export const MEMO_PRESETS: OptionItem[] = [
  { key: '忌口', label: '不吃香菜' },
  { key: '忌口', label: '不吃葱姜蒜' },
  { key: '忌口', label: '不吃内脏' },
  { key: '过敏', label: '芒果过敏' },
  { key: '过敏', label: '海鲜过敏' },
  { key: '过敏', label: '乳糖不耐受' },
  { key: '口味', label: '爱吃辣' },
  { key: '口味', label: '喜欢甜食' },
  { key: '尺码', label: '鞋码' },
  { key: '尺码', label: '衣服尺码' },
  { key: '尺码', label: '戒指圈号' },
  { key: '讨厌', label: '讨厌下雨天' },
  { key: '讨厌', label: '不喜欢被催' }
];

export const ANNIVERSARY_EMOJIS: string[] = [
  '💖', '🎂', '🌹', '✈️', '🍲', '🎬', '🎁', '🏖️', '🎓', '🐱', '☕', '🎉'
];

export const ANNIVERSARY_COLORS: string[] = [
  '#FF6B81', '#FF9F43', '#54A0FF', '#5FD068', '#A66CFF', '#FF7FB6'
];

export interface PresetAnniversary {
  title: string;
  emoji: string;
}

export const PRESET_ANNIVERSARIES: PresetAnniversary[] = [
  { title: '在一起纪念日', emoji: '💖' },
  { title: '第一次见面', emoji: '🌹' },
  { title: 'TA的生日', emoji: '🎂' },
  { title: '我的生日', emoji: '🎉' },
  { title: '领证纪念日', emoji: '💍' },
  { title: '第一次旅行', emoji: '✈️' }
];

export function moodLabel(key: string): string {
  for (let i = 0; i < MOODS.length; i++) {
    if (MOODS[i].key === key) {
      return MOODS[i].label;
    }
  }
  return key;
}

export function moodEmoji(key: string): string {
  const parts: string[] = moodLabel(key).split(' ');
  return parts.length > 0 ? parts[0] : '🙂';
}
