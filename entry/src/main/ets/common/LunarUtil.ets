const LUNAR_INFO: number[] = [
  0x04bd8, 0x04ae0, 0x0a570, 0x054d5, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2,
  0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977,
  0x04970, 0x0a4b0, 0x0b4b5, 0x06a50, 0x06d40, 0x1ab54, 0x02b60, 0x09570, 0x052f2, 0x04970,
  0x06566, 0x0d4a0, 0x0ea50, 0x16a95, 0x05ad0, 0x02b60, 0x186e3, 0x092e0, 0x1c8d7, 0x0c950,
  0x0d4a0, 0x1d8a6, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2, 0x0a950, 0x0b557,
  0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5b0, 0x14573, 0x052b0, 0x0a9a8, 0x0e950, 0x06aa0,
  0x0aea6, 0x0ab50, 0x04b60, 0x0aae4, 0x0a570, 0x05260, 0x0f263, 0x0d950, 0x05b57, 0x056a0,
  0x096d0, 0x04dd5, 0x04ad0, 0x0a4d0, 0x0d4d4, 0x0d250, 0x0d558, 0x0b540, 0x0b6a0, 0x195a6,
  0x095b0, 0x049b0, 0x0a974, 0x0a4b0, 0x0b27a, 0x06a50, 0x06d40, 0x0af46, 0x0ab60, 0x09570,
  0x04af5, 0x04970, 0x064b0, 0x074a3, 0x0ea50, 0x06b58, 0x055c0, 0x0ab60, 0x096d5, 0x092e0,
  0x0c960, 0x0d954, 0x0d4a0, 0x0da50, 0x07552, 0x056a0, 0x0abb7, 0x025d0, 0x092d0, 0x0cab5,
  0x0a950, 0x0b4a0, 0x0baa4, 0x0ad50, 0x055d9, 0x04ba0, 0x0a5b0, 0x15176, 0x052b0, 0x0a930,
  0x07954, 0x06aa0, 0x0ad50, 0x05b52, 0x04b60, 0x0a6e6, 0x0a4e0, 0x0d260, 0x0ea65, 0x0d530,
  0x05aa0, 0x076a3, 0x096d0, 0x04afb, 0x04ad0, 0x0a4d0, 0x1d0b6, 0x0d250, 0x0d520, 0x0dd45,
  0x0b5a0, 0x056d0, 0x055b2, 0x049b0, 0x0a577, 0x0a4b0, 0x0aa50, 0x1b255, 0x06d20, 0x0ada0,
  0x14b63, 0x09370, 0x049f8, 0x04970, 0x064b0, 0x168a6, 0x0ea50, 0x06b20, 0x1a6c4, 0x0aae0,
  0x0a2e0, 0x0d2e3, 0x0c960, 0x0d557, 0x0d4a0, 0x0da50, 0x05d55, 0x056a0, 0x0a6d0, 0x055d4,
  0x052d0, 0x0a9b8, 0x0a950, 0x0b4a0, 0x0b6a6, 0x0ad50, 0x055a0, 0x0aba4, 0x0a5b0, 0x052b0,
  0x0b273, 0x06930, 0x07337, 0x06aa0, 0x0ad50, 0x14b55, 0x04b60, 0x0a570, 0x054e4, 0x0d160,
  0x0e968, 0x0d520, 0x0daa0, 0x16aa6, 0x056d0, 0x04ae0, 0x0a9d4, 0x0a2d0, 0x0d150, 0x0f252,
  0x0d520
];

const MONTH_NAMES: string[] = ['正月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '冬月', '腊月'];
const DAY_NAMES: string[] = [
  '初一', '初二', '初三', '初四', '初五', '初六', '初七', '初八', '初九', '初十',
  '十一', '十二', '十三', '十四', '十五', '十六', '十七', '十八', '十九', '二十',
  '廿一', '廿二', '廿三', '廿四', '廿五', '廿六', '廿七', '廿八', '廿九', '三十'
];
const GAN: string[] = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
const ZHI: string[] = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
const ZODIAC: string[] = ['鼠', '牛', '虎', '兔', '龙', '蛇', '马', '羊', '猴', '鸡', '狗', '猪'];

const BASE_UTC: number = Date.UTC(1900, 0, 31);
const MIN_YEAR: number = 1900;
const MAX_YEAR: number = 2099;

export interface LunarDate {
  year: number;
  month: number;
  day: number;
  isLeap: boolean;
}

export interface SolarDate {
  year: number;
  month: number;
  day: number;
}

export class LunarUtil {
  static leapMonth(year: number): number {
    if (year < MIN_YEAR || year > MAX_YEAR) {
      return 0;
    }
    return LUNAR_INFO[year - MIN_YEAR] & 0xf;
  }

  static leapDays(year: number): number {
    if (LunarUtil.leapMonth(year) === 0) {
      return 0;
    }
    return (LUNAR_INFO[year - MIN_YEAR] & 0x10000) !== 0 ? 30 : 29;
  }

  static monthDays(year: number, month: number): number {
    if (year < MIN_YEAR || year > MAX_YEAR || month < 1 || month > 12) {
      return 29;
    }
    return (LUNAR_INFO[year - MIN_YEAR] & (0x10000 >> month)) !== 0 ? 30 : 29;
  }

  static yearDays(year: number): number {
    if (year < MIN_YEAR || year > MAX_YEAR) {
      return 354;
    }
    let sum: number = 348;
    let bit: number = 0x8000;
    while (bit > 0x8) {
      if ((LUNAR_INFO[year - MIN_YEAR] & bit) !== 0) {
        sum += 1;
      }
      bit >>= 1;
    }
    return sum + LunarUtil.leapDays(year);
  }

  /** 公历 → 农历。支持 1900-01-31 ~ 2099-12-31。 */
  static solarToLunar(year: number, month: number, day: number): LunarDate {
    let offset: number = Math.floor((Date.UTC(year, month - 1, day) - BASE_UTC) / 86400000);
    let y: number = MIN_YEAR;
    let span: number = 0;
    while (y <= MAX_YEAR && offset > 0) {
      span = LunarUtil.yearDays(y);
      offset -= span;
      y += 1;
    }
    if (offset < 0) {
      offset += span;
      y -= 1;
    }
    const leap: number = LunarUtil.leapMonth(y);
    let isLeap: boolean = false;
    let m: number = 1;
    let monthSpan: number = 0;
    while (m < 13 && offset > 0) {
      if (leap > 0 && m === leap + 1 && !isLeap) {
        m -= 1;
        isLeap = true;
        monthSpan = LunarUtil.leapDays(y);
      } else {
        monthSpan = LunarUtil.monthDays(y, m);
      }
      if (isLeap && m === leap + 1) {
        isLeap = false;
      }
      offset -= monthSpan;
      m += 1;
    }
    if (offset === 0 && leap > 0 && m === leap + 1) {
      if (isLeap) {
        isLeap = false;
      } else {
        isLeap = true;
        m -= 1;
      }
    }
    if (offset < 0) {
      offset += monthSpan;
      m -= 1;
    }
    const result: LunarDate = { year: y, month: m, day: offset + 1, isLeap: isLeap };
    return result;
  }

  /** 农历 → 公历。若该农历年没有指定闰月，则自动降级为非闰月。 */
  static lunarToSolar(year: number, month: number, day: number, isLeap: boolean): SolarDate {
    let offset: number = 0;
    for (let i = MIN_YEAR; i < year; i++) {
      offset += LunarUtil.yearDays(i);
    }
    const leap: number = LunarUtil.leapMonth(year);
    for (let m = 1; m < month; m++) {
      offset += LunarUtil.monthDays(year, m);
      if (leap > 0 && m === leap) {
        offset += LunarUtil.leapDays(year);
      }
    }
    if (isLeap && leap === month) {
      offset += LunarUtil.monthDays(year, month);
    }
    offset += day - 1;
    const dt = new Date(BASE_UTC + offset * 86400000);
    const result: SolarDate = {
      year: dt.getUTCFullYear(),
      month: dt.getUTCMonth() + 1,
      day: dt.getUTCDate()
    };
    return result;
  }

  /** 该农历年是否存在闰月，返回闰月月份（0 表示无闰月）。 */
  static leapMonthOf(year: number): number {
    return LunarUtil.leapMonth(year);
  }

  static ganzhiYear(lunarYear: number): string {
    const idx: number = (lunarYear - 4) % 60;
    const gan: number = idx % 10;
    const zhi: number = idx % 12;
    return GAN[gan] + ZHI[zhi];
  }

  static zodiac(lunarYear: number): string {
    return ZODIAC[(lunarYear - 4) % 12];
  }

  static monthName(month: number, isLeap: boolean): string {
    const name: string = MONTH_NAMES[Math.min(Math.max(month, 1), 12) - 1];
    return isLeap ? '闰' + name : name;
  }

  static dayName(day: number): string {
    return DAY_NAMES[Math.min(Math.max(day, 1), 30) - 1];
  }

  /** 例如：乙巳年 正月初五 */
  static format(lunar: LunarDate): string {
    return LunarUtil.ganzhiYear(lunar.year) + '年 ' + LunarUtil.monthName(lunar.month, lunar.isLeap) +
      LunarUtil.dayName(lunar.day);
  }

  /** 该农历年某月（含闰月）的最大天数。 */
  static daysOfLunarMonth(year: number, month: number, isLeap: boolean): number {
    const leap: number = LunarUtil.leapMonth(year);
    if (isLeap && leap === month) {
      return LunarUtil.leapDays(year);
    }
    return LunarUtil.monthDays(year, month);
  }
}
