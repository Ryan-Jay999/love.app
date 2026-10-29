import { Anniversary, CAL_LUNAR, CAL_SOLAR } from '../../model/Types';
import { newId } from '../../common/Ids';
import { ANNIVERSARY_COLORS, ANNIVERSARY_EMOJIS } from '../../common/Constants';
import { LunarUtil } from '../../common/LunarUtil';
import { Theme } from '../common/Widgets';

@Component
export struct AnniversaryEditor {
  initial: Anniversary | null = null;
  onCancel: () => void = () => {
  };
  onSave: (item: Anniversary) => void = () => {
  };
  onDelete: () => void = () => {
  };

  @State title: string = '';
  @State calendar: string = CAL_SOLAR;
  @State month: number = 1;
  @State day: number = 1;
  @State isLeapMonth: boolean = false;
  @State emoji: string = '💖';
  @State color: string = ANNIVERSARY_COLORS[0];

  aboutToAppear(): void {
    if (this.initial !== null) {
      this.title = this.initial.title;
      this.calendar = this.initial.calendar;
      this.month = this.initial.month;
      this.day = this.initial.day;
      this.isLeapMonth = this.initial.isLeapMonth;
      this.emoji = this.initial.emoji;
      this.color = this.initial.color;
    }
  }

  private maxDay(): number {
    if (this.calendar === CAL_LUNAR) {
      return 30;
    }
    const year: number = new Date().getFullYear();
    return new Date(year, this.month, 0).getDate();
  }

  private bumpDay(delta: number): void {
    let next: number = this.day + delta;
    if (next < 1) {
      next = 1;
    }
    if (next > this.maxDay()) {
      next = this.maxDay();
    }
    this.day = next;
  }

  private bumpMonth(delta: number): void {
    let next: number = this.month + delta;
    if (next < 1) {
      next = 1;
    }
    if (next > 12) {
      next = 12;
    }
    this.month = next;
    if (this.day > this.maxDay()) {
      this.day = this.maxDay();
    }
  }

  private save(): void {
    const item: Anniversary = {
      id: this.initial === null ? newId() : this.initial.id,
      title: this.title.trim() === '' ? '纪念日' : this.title.trim(),
      calendar: this.calendar,
      month: this.month,
      day: this.day,
      isLeapMonth: this.isLeapMonth,
      advanceDays: 0,
      emoji: this.emoji,
      remind: false,
      color: this.color
    };
    this.onSave(item);
  }

  private monthText(): string {
    if (this.calendar === CAL_LUNAR) {
      return LunarUtil.monthName(this.month, this.isLeapMonth);
    }
    return this.month + ' 月';
  }

  private dayText(): string {
    if (this.calendar === CAL_LUNAR) {
      return LunarUtil.dayName(this.day);
    }
    return this.day + ' 日';
  }

  build() {
    Column() {
      Row() {
        Text('取消')
          .fontSize(15)
          .fontColor(Theme.sub)
          .onClick(() => {
            this.onCancel();
          })
        Text(this.initial === null ? '添加纪念日' : '编辑纪念日')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.text)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('保存')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.primary)
          .onClick(() => {
            this.save();
          })
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })

      Scroll() {
        Column() {
          Text('名称')
            .fontSize(13)
            .fontColor(Theme.sub)
            .width('100%')
          TextInput({ text: this.title, placeholder: '例如：在一起纪念日' })
            .height(46)
            .backgroundColor(Theme.card)
            .borderRadius(Theme.radiusSm)
            .margin({ top: 6 })
            .onChange((value: string) => {
              this.title = value;
            })

          Text('日期类型')
            .fontSize(13)
            .fontColor(Theme.sub)
            .width('100%')
            .margin({ top: 14 })
          Row() {
            Text('公历')
              .fontSize(14)
              .fontColor(this.calendar === CAL_SOLAR ? '#FFFFFF' : Theme.sub)
              .backgroundColor(this.calendar === CAL_SOLAR ? Theme.primary : Theme.card)
              .borderRadius(16)
              .padding({ left: 20, right: 20, top: 8, bottom: 8 })
              .margin({ right: 10 })
              .onClick(() => {
                this.calendar = CAL_SOLAR;
                this.isLeapMonth = false;
              })
            Text('农历')
              .fontSize(14)
              .fontColor(this.calendar === CAL_LUNAR ? '#FFFFFF' : Theme.sub)
              .backgroundColor(this.calendar === CAL_LUNAR ? Theme.primary : Theme.card)
              .borderRadius(16)
              .padding({ left: 20, right: 20, top: 8, bottom: 8 })
              .onClick(() => {
                this.calendar = CAL_LUNAR;
              })
          }
          .width('100%')
          .margin({ top: 6 })

          Text(this.calendar === CAL_LUNAR ? '农历月份 / 日期' : '公历月份 / 日期')
            .fontSize(13)
            .fontColor(Theme.sub)
            .width('100%')
            .margin({ top: 14 })
          Row() {
            Column() {
              Text(this.monthText())
                .fontSize(17)
                .fontColor(Theme.text)
              Row() {
                Text('－')
                  .fontSize(15)
                  .fontColor(Theme.primary)
                  .padding(8)
                  .onClick(() => {
                    this.bumpMonth(-1);
                  })
                Text('＋')
                  .fontSize(15)
                  .fontColor(Theme.primary)
                  .padding(8)
                  .onClick(() => {
                    this.bumpMonth(1);
                  })
              }
            }
            .layoutWeight(1)
            .padding(10)
            .backgroundColor(Theme.card)
            .borderRadius(Theme.radiusSm)

            Column() {
              Text(this.dayText())
                .fontSize(17)
                .fontColor(Theme.text)
              Row() {
                Text('－')
                  .fontSize(15)
                  .fontColor(Theme.primary)
                  .padding(8)
                  .onClick(() => {
                    this.bumpDay(-1);
                  })
                Text('＋')
                  .fontSize(15)
                  .fontColor(Theme.primary)
                  .padding(8)
                  .onClick(() => {
                    this.bumpDay(1);
                  })
              }
            }
            .layoutWeight(1)
            .margin({ left: 10 })
            .padding(10)
            .backgroundColor(Theme.card)
            .borderRadius(Theme.radiusSm)
          }
          .width('100%')
          .margin({ top: 6 })

          if (this.calendar === CAL_LUNAR) {
            Row() {
              Text('这是闰月')
                .fontSize(14)
                .fontColor(Theme.text)
                .layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.isLeapMonth })
                .selectedColor(Theme.primary)
                .onChange((isOn: boolean) => {
                  this.isLeapMonth = isOn;
                })
            }
            .width('100%')
            .padding({ top: 12, bottom: 12 })
            if (this.isLeapMonth) {
              Text('提示：并非每年都有闰月，没有闰月的年份会自动按同月同日提醒。')
                .fontSize(11)
                .fontColor(Theme.orange)
                .width('100%')
            }
          }

          Text('图标')
            .fontSize(13)
            .fontColor(Theme.sub)
            .width('100%')
            .margin({ top: 14 })
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(ANNIVERSARY_EMOJIS, (item: string) => {
              Text(item)
                .fontSize(20)
                .padding(6)
                .borderRadius(10)
                .backgroundColor(this.emoji === item ? Theme.primarySoft : Theme.card)
                .margin({ right: 6, top: 6 })
                .onClick(() => {
                  this.emoji = item;
                })
            }, (item: string) => item)
          }
          .width('100%')

          Text('颜色')
            .fontSize(13)
            .fontColor(Theme.sub)
            .width('100%')
            .margin({ top: 14 })
          Row() {
            ForEach(ANNIVERSARY_COLORS, (item: string) => {
              Row()
                .width(this.color === item ? 30 : 24)
                .height(this.color === item ? 30 : 24)
                .backgroundColor(item)
                .borderRadius('50%')
                .margin({ right: 10 })
                .onClick(() => {
                  this.color = item;
                })
            }, (item: string) => item)
          }
          .width('100%')
          .margin({ top: 6 })

          if (this.initial !== null) {
            Button('删除这个纪念日')
              .width('100%')
              .height(44)
              .backgroundColor('#FFF0F3')
              .fontColor(Theme.primaryDeep)
              .borderRadius(22)
              .margin({ top: 24, bottom: 40 })
              .onClick(() => {
                this.onDelete();
              })
          } else {
            Row().height(40)
          }
        }
        .padding({ left: 16, right: 16 })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bg)
  }
}
