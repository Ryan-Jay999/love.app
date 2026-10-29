import { promptAction } from '@kit.ArkUI';
import { Anniversary, AppData, DATA_KEY, emptyAppData, Memory, MoodRecord } from '../../model/Types';
import { AnniversaryNext, DateUtil } from '../../common/DateUtil';
import { MOODS, OptionItem, moodEmoji } from '../../common/Constants';
import { quoteOfDay } from '../../common/Quotes';
import { Store } from '../../common/Store';
import { newId } from '../../common/Ids';
import { AnniversaryEditor } from '../../view/editors/AnniversaryEditor';
import { EmptyTip, sectionTitle, Theme } from '../../view/common/Widgets';
import { PhotoGrid } from '../../view/common/PhotoGrid';

interface AnnRow {
  ann: Anniversary;
  next: AnniversaryNext;
}

@Component
export struct HomeTab {
  @StorageProp(DATA_KEY) data: AppData = emptyAppData();
  @State showAnnEditor: boolean = false;
  @State editingAnn: Anniversary | null = null;

  private startDateText(): string {
    return this.data.settings.startDate;
  }

  private daysTogether(): number {
    return DateUtil.daysTogether(this.data.settings.startDate);
  }

  private rows(): AnnRow[] {
    const rows: AnnRow[] = [];
    const today: Date = new Date();
    for (let i = 0; i < this.data.anniversaries.length; i++) {
      const ann: Anniversary = this.data.anniversaries[i];
      const row: AnnRow = { ann: ann, next: DateUtil.nextOf(ann, today) };
      rows.push(row);
    }
    rows.sort((a: AnnRow, b: AnnRow) => a.next.daysLeft - b.next.daysLeft);
    return rows;
  }

  private onThisDay(): Memory[] {
    const result: Memory[] = [];
    const today: Date = new Date();
    const list: Memory[] = this.data.memories;
    for (let i = 0; i < list.length; i++) {
      if (DateUtil.isSameMonthDay(list[i].date, today)) {
        result.push(list[i]);
      }
    }
    result.sort((a: Memory, b: Memory) => b.date.localeCompare(a.date));
    return result;
  }

  private todayMood(): string {
    const list: MoodRecord[] = this.data.moods;
    const today: string = DateUtil.todayStr();
    for (let i = list.length - 1; i >= 0; i--) {
      if (list[i].date === today) {
        return list[i].mood;
      }
    }
    return '';
  }

  private setMood(key: string): void {
    const today: string = DateUtil.todayStr();
    Store.commit((d: AppData) => {
      let found: boolean = false;
      for (let i = 0; i < d.moods.length; i++) {
        if (d.moods[i].date === today) {
          d.moods[i].mood = key;
          found = true;
        }
      }
      if (!found) {
        const rec: MoodRecord = { id: newId(), date: today, mood: key, note: '' };
        d.moods.push(rec);
      }
    });
    promptAction.showToast({ message: '今天的心情已记下 ' + moodEmoji(key) });
  }

  private pickStartDate(): void {
    const current: Date = this.data.settings.startDate === '' ? new Date() :
    DateUtil.parseDateStr(this.data.settings.startDate);
    DatePickerDialog.show({
      start: new Date(1990, 0, 1),
      end: new Date(),
      selected: current,
      onDateAccept: (value: Date) => {
        Store.commit((d: AppData) => {
          d.settings.startDate = DateUtil.toDateStr(value);
        });
        promptAction.showToast({ message: '已开始记录我们的第 1 天' });
      }
    });
  }

  private openAnnEditor(item: Anniversary | null): void {
    this.editingAnn = item;
    this.showAnnEditor = true;
  }

  private saveAnn(item: Anniversary): void {
    Store.commit((d: AppData) => {
      let updated: boolean = false;
      for (let i = 0; i < d.anniversaries.length; i++) {
        if (d.anniversaries[i].id === item.id) {
          d.anniversaries[i] = item;
          updated = true;
        }
      }
      if (!updated) {
        d.anniversaries.push(item);
      }
    });
    this.showAnnEditor = false;
  }

  private deleteAnn(): void {
    if (this.editingAnn === null) {
      return;
    }
    const id: string = this.editingAnn.id;
    Store.commit((d: AppData) => {
      const next: Anniversary[] = [];
      for (let i = 0; i < d.anniversaries.length; i++) {
        if (d.anniversaries[i].id !== id) {
          next.push(d.anniversaries[i]);
        }
      }
      d.anniversaries = next;
    });
    this.editingAnn = null;
    this.showAnnEditor = false;
  }

  @Builder
  annEditorBuilder() {
    AnniversaryEditor({
      initial: this.editingAnn,
      onCancel: () => {
        this.showAnnEditor = false;
      },
      onSave: (item: Anniversary) => {
        this.saveAnn(item);
      },
      onDelete: () => {
        this.deleteAnn();
      }
    })
  }

  build() {
    Scroll() {
      Column() {
        // 顶部：相恋天数
        Column() {
          Text(this.data.settings.startDate === '' ? '拾年' : '我们已经在一起')
            .fontSize(13)
            .fontColor('#FFFFFFCC')
          if (this.data.settings.startDate === '') {
            Text('记录第一天的日期')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .margin({ top: 6 })
            Text('点击设置在一起的起始日期 ›')
              .fontSize(12)
              .fontColor('#FFFFFFCC')
              .margin({ top: 8 })
          } else {
            Row() {
              Text('' + this.daysTogether())
                .fontSize(46)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              Text('天')
                .fontSize(16)
                .fontColor('#FFFFFFCC')
                .margin({ left: 6, top: 18 })
            }
            .alignItems(VerticalAlign.Bottom)
            .margin({ top: 2 })
            Text(Store.getData().settings.startDate + ' 起 · 第 ' + this.daysTogether() + ' 天')
              .fontSize(12)
              .fontColor('#FFFFFFCC')
              .margin({ top: 4 })
          }
        }
        .width('100%')
        .padding(22)
        .borderRadius(20)
        .linearGradient({
          angle: 135,
          colors: [[Theme.primary, 0.0], ['#FF9F8E', 1.0]]
        })
        .alignItems(HorizontalAlign.Start)
        .onClick(() => {
          this.pickStartDate();
        })

        // 每日情话
        Column() {
          Text('今日情话')
            .fontSize(12)
            .fontColor(Theme.sub)
          Text(quoteOfDay(Date.now() / 86400000 + this.data.memories.length + this.daysTogether()))
            .fontSize(14)
            .fontColor(Theme.text)
            .lineHeight(22)
            .margin({ top: 6 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(16)
        .backgroundColor(Theme.card)
        .borderRadius(Theme.radius)
        .margin({ top: 12 })

        // 今日心情
        Column() {
          Text('今天的心情')
            .fontSize(13)
            .fontColor(Theme.sub)
            .width('100%')
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(MOODS, (m: OptionItem) => {
              Text(m.label)
                .fontSize(13)
                .fontColor(this.todayMood() === m.key ? '#FFFFFF' : Theme.text)
                .backgroundColor(this.todayMood() === m.key ? Theme.primary : Theme.primarySoft)
                .borderRadius(14)
                .padding({ left: 12, right: 12, top: 7, bottom: 7 })
                .margin({ right: 8, top: 8 })
                .onClick(() => {
                  this.setMood(m.key);
                })
            }, (m: OptionItem) => m.key)
          }
          .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Theme.card)
        .borderRadius(Theme.radius)
        .margin({ top: 12 })

        // 纪念日
        Column() {
          sectionTitle('纪念日倒计时', '＋ 添加', () => {
            this.openAnnEditor(null);
          })
          if (this.rows().length === 0) {
            EmptyTip({ text: '添加生日、见面日、约定的日子吧' })
          } else {
            ForEach(this.rows(), (row: AnnRow) => {
              Row() {
                Text(row.ann.emoji)
                  .fontSize(24)
                  .width(40)
                Column() {
                  Text(row.ann.title)
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Theme.text)
                  Text(row.next.dateStr + ' · ' + row.next.lunarText)
                    .fontSize(11)
                    .fontColor(Theme.sub)
                    .margin({ top: 3 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                Column() {
                  Text(row.next.daysLeft === 0 ? '今天' : '' + row.next.daysLeft)
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(row.next.daysLeft <= 7 ? Theme.primary : Theme.text)
                  Text(row.next.daysLeft === 0 ? '🎉 就是今天' : '天后')
                    .fontSize(10)
                    .fontColor(Theme.sub)
                }
              }
              .width('100%')
              .padding({ top: 10, bottom: 10 })
              .onClick(() => {
                this.openAnnEditor(row.ann);
              })
              Divider().color(Theme.line)
            }, (row: AnnRow) => JSON.stringify(row.ann))
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Theme.card)
        .borderRadius(Theme.radius)
        .margin({ top: 12 })

        // 那年今日
        if (this.onThisDay().length > 0) {
          Column() {
            sectionTitle('那年今日', '', () => {
            })
            ForEach(this.onThisDay(), (mem: Memory) => {
              Column() {
                Row() {
                  Text(DateUtil.yearsAgo(mem.date, new Date()) + ' 年前的今天')
                    .fontSize(12)
                    .fontColor(Theme.primary)
                    .layoutWeight(1)
                  Text(mem.date)
                    .fontSize(11)
                    .fontColor(Theme.sub)
                }
                .width('100%')
                Text((mem.feeling !== '' ? mem.feeling : mem.activity) + ' · ' + mem.place)
                  .fontSize(14)
                  .fontColor(Theme.text)
                  .width('100%')
                  .margin({ top: 6 })
                if (mem.images.length > 0) {
                  PhotoGrid({ images: mem.images.slice(0, 3), editable: false })
                }
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .padding({ top: 10, bottom: 10 })
            }, (mem: Memory) => mem.id)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Theme.card)
          .borderRadius(Theme.radius)
          .margin({ top: 12 })
        }

        Row().height(30)
      }
      .padding({ left: 16, right: 16, top: 16 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(Theme.bg)
    .bindSheet(this.showAnnEditor, this.annEditorBuilder(), {
      height: SheetSize.LARGE,
      showClose: false,
      dragBar: true,
      backgroundColor: Theme.bg,
      onDisappear: () => {
        this.showAnnEditor = false;
        this.editingAnn = null;
      }
    })
  }
}
