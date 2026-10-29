import { Anniversary, CAL_LUNAR } from '../model/Types';
import { LunarDate, LunarUtil } from './LunarUtil';

export interface AnniversaryNext {
  date: Date;
  dateStr: string;
  daysLeft: number;
  lunar: LunarDate;
  lunarText: string;
  years: number;
}

function pad2(n: number): string {
  return n < 10 ? '0' + n : '' + n;
}

function dateOnlyMs(y: number, m: number, d: number): number {
  return Date.UTC(y, m - 1, d);
}

function daysInMonth(y: number, m: number): number {
  return new Date(Date.UTC(y, m, 0)).getUTCDate();
}

export class DateUtil {
  static today(): Date {
    return new Date();
  }

  static toDateStr(date: Date): string {
    return date.getFullYear() + '-' + pad2(date.getMonth() + 1) + '-' + pad2(date.getDate());
  }

  static todayStr(): string {
    return DateUtil.toDateStr(new Date());
  }

  static makeDate(y: number, m: number, d: number): Date {
    return new Date(y, m - 1, d);
  }

  static parseDateStr(s: string): Date {
    const parts: string[] = s.split('-');
    if (parts.length < 3) {
      return new Date();
    }
    const y: number = parseInt(parts[0], 10);
    const m: number = parseInt(parts[1], 10);
    const d: number = parseInt(parts[2], 10);
    if (isNaN(y) || isNaN(m) || isNaN(d)) {
      return new Date();
    }
    return new Date(y, m - 1, d);
  }

  static formatCn(date: Date): string {
    return date.getFullYear() + '年' + (date.getMonth() + 1) + '月' + date.getDate() + '日';
  }

  static formatShort(date: Date): string {
    return (date.getMonth() + 1) + '月' + date.getDate() + '日';
  }

  static weekdayCn(date: Date): string {
    const names: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return names[date.getDay()];
  }

  /** 相差整天数（dateB - dateA）。 */
  static daysBetween(a: Date, b: Date): number {
    const msA: number = dateOnlyMs(a.getFullYear(), a.getMonth() + 1, a.getDate());
    const msB: number = dateOnlyMs(b.getFullYear(), b.getMonth() + 1, b.getDate());
    return Math.round((msB - msA) / 86400000);
  }

  /** 今天是相恋第几天（起始当天算第 1 天）。 */
  static daysTogether(startDate: string): number {
    if (startDate === '') {
      return 0;
    }
    return DateUtil.daysBetween(DateUtil.parseDateStr(startDate), new Date()) + 1;
  }

  /** 下一次公历周年日期（当天也算"今天"）。 */
  static nextSolar(month: number, day: number, from: Date): Date {
    let y: number = from.getFullYear();
    let d: number = Math.min(day, daysInMonth(y, month));
    let candidate = new Date(y, month - 1, d);
    if (DateUtil.daysBetween(from, candidate) < 0) {
      y += 1;
      d = Math.min(day, daysInMonth(y, month));
      candidate = new Date(y, month - 1, d);
    }
    return candidate;
  }

  /** 下一次农历日期（当天也算"今天"）。返回公历日期与对应农历年。 */
  static nextLunar(month: number, day: number, isLeap: boolean, from: Date): SolarDateInfo {
    const todayLunar: LunarDate = LunarUtil.solarToLunar(from.getFullYear(), from.getMonth() + 1, from.getDate());
    let lunarYear: number = todayLunar.year;
    let solar = LunarUtil.lunarToSolar(lunarYear, month, day, isLeap);
    let candidate = new Date(solar.year, solar.month - 1, solar.day);
    if (DateUtil.daysBetween(from, candidate) < 0) {
      lunarYear += 1;
      solar = LunarUtil.lunarToSolar(lunarYear, month, day, isLeap);
      candidate = new Date(solar.year, solar.month - 1, solar.day);
    }
    const info: SolarDateInfo = { date: candidate, lunarYear: lunarYear, isLeap: isLeap };
    return info;
  }

  static nextOf(ann: Anniversary, from: Date): AnniversaryNext {
    let date: Date;
    let lunar: LunarDate;
    let years: number = 0;
    if (ann.calendar === CAL_LUNAR) {
      const info: SolarDateInfo = DateUtil.nextLunar(ann.month, ann.day, ann.isLeapMonth, from);
      date = info.date;
      lunar = { year: info.lunarYear, month: ann.month, day: ann.day, isLeap: info.isLeap };
      years = info.lunarYear - LunarUtil.solarToLunar(from.getFullYear(), from.getMonth() + 1, from.getDate()).year;
    } else {
      date = DateUtil.nextSolar(ann.month, ann.day, from);
      lunar = LunarUtil.solarToLunar(date.getFullYear(), date.getMonth() + 1, date.getDate());
      years = date.getFullYear() - from.getFullYear();
    }
    const next: AnniversaryNext = {
      date: date,
      dateStr: DateUtil.formatShort(date),
      daysLeft: DateUtil.daysBetween(from, date),
      lunar: lunar,
      lunarText: LunarUtil.format(lunar),
      years: Math.max(years, 0)
    };
    return next;
  }

  /** 该回忆是否属于"那年今日"。 */
  static isSameMonthDay(dateStr: string, today: Date): boolean {
    const d: Date = DateUtil.parseDateStr(dateStr);
    return d.getMonth() === today.getMonth() && d.getDate() === today.getDate() &&
      d.getFullYear() !== today.getFullYear();
  }

  static yearsAgo(dateStr: string, today: Date): number {
    return today.getFullYear() - DateUtil.parseDateStr(dateStr).getFullYear();
  }

  static monthKey(dateStr: string): string {
    return dateStr.length >= 7 ? dateStr.substring(0, 7) : dateStr;
  }

  static yearKey(dateStr: string): string {
    return dateStr.length >= 4 ? dateStr.substring(0, 4) : dateStr;
  }
}

export interface SolarDateInfo {
  date: Date;
  lunarYear: number;
  isLeap: boolean;
}
