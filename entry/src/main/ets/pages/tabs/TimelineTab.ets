import { promptAction } from '@kit.ArkUI';
import { AppData, DATA_KEY, emptyAppData, Memory } from '../../model/Types';
import { DateUtil } from '../../common/DateUtil';
import { moodEmoji } from '../../common/Constants';
import { PhotoStore } from '../../common/PhotoStore';
import { Store } from '../../common/Store';
import { MemoryEditor } from '../../view/editors/MemoryEditor';
import { EmptyTip, Theme } from '../../view/common/Widgets';
import { PhotoGrid } from '../../view/common/PhotoGrid';

interface YearGroup {
  year: string;
  items: Memory[];
}

@Component
export struct TimelineTab {
  @StorageProp(DATA_KEY) data: AppData = emptyAppData();
  @State showEditor: boolean = false;
  @State editing: Memory | null = null;

  private groups(): YearGroup[] {
    const sorted: Memory[] = this.data.memories.slice(0);
    sorted.sort((a: Memory, b: Memory) => b.date.localeCompare(a.date));
    const result: YearGroup[] = [];
    for (let i = 0; i < sorted.length; i++) {
      const year: string = DateUtil.yearKey(sorted[i].date);
      if (result.length === 0 || result[result.length - 1].year !== year) {
        const g: YearGroup = { year: year, items: [] };
        result.push(g);
      }
      result[result.length - 1].items.push(sorted[i]);
    }
    return result;
  }

  private openEditor(item: Memory | null): void {
    this.editing = item;
    this.showEditor = true;
  }

  private save(item: Memory): void {
    const isNew: boolean = this.editing === null;
    Store.commit((d: AppData) => {
      let updated: boolean = false;
      for (let i = 0; i < d.memories.length; i++) {
        if (d.memories[i].id === item.id) {
          d.memories[i] = item;
          updated = true;
        }
      }
      if (!updated) {
        d.memories.push(item);
      }
    });
    this.showEditor = false;
    this.editing = null;
    promptAction.showToast({ message: isNew ? '已记录这一刻' : '已更新' });
  }

  private deleteCurrent(): void {
    if (this.editing === null) {
      return;
    }
    const id: string = this.editing.id;
    const images: string[] = this.editing.images.slice(0);
    Store.commit((d: AppData) => {
      const next: Memory[] = [];
      for (let i = 0; i < d.memories.length; i++) {
        if (d.memories[i].id !== id) {
          next.push(d.memories[i]);
        }
      }
      d.memories = next;
    });
    for (let i = 0; i < images.length; i++) {
      PhotoStore.remove(images[i]);
    }
    this.showEditor = false;
    this.editing = null;
    promptAction.showToast({ message: '已删除' });
  }

  @Builder
  editorBuilder() {
    MemoryEditor({
      initial: this.editing,
      onCancel: () => {
        this.showEditor = false;
      },
      onSave: (item: Memory) => {
        this.save(item);
      },
      onDelete: () => {
        this.deleteCurrent();
      }
    })
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          Column() {
            Text('共同回忆')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.text)
            Text('已收藏 ' + this.data.memories.length + ' 个瞬间')
              .fontSize(12)
              .fontColor(Theme.sub)
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          Text('＋ 记录')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor(Theme.primary)
            .borderRadius(18)
            .padding({ left: 14, right: 14, top: 8, bottom: 8 })
            .onClick(() => {
              this.openEditor(null);
            })
        }
        .width('100%')
        .margin({ top: 6, bottom: 14 })

        if (this.data.memories.length === 0) {
          EmptyTip({ text: '一起去过的店、看过的海，\n都值得被记下来' })
        }

        ForEach(this.groups(), (group: YearGroup) => {
          Column() {
            Text(group.year + ' 年')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.primary)
              .width('100%')
              .margin({ top: 8, bottom: 8 })
            ForEach(group.items, (item: Memory) => {
              Row() {
                Column() {
                  Text(DateUtil.formatShort(DateUtil.parseDateStr(item.date)))
                    .fontSize(11)
                    .fontColor(Theme.primary)
                  Text(DateUtil.weekdayCn(DateUtil.parseDateStr(item.date)))
                    .fontSize(10)
                    .fontColor(Theme.sub)
                    .margin({ top: 2 })
                }
                .width(52)
                .alignItems(HorizontalAlign.Center)

                Column() {
                  Row() {
                    Text(item.mood !== '' ? moodEmoji(item.mood) + ' ' : '')
                      .fontSize(13)
                    Text(item.place === '' ? '某个地方' : item.place)
                      .fontSize(14)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(Theme.text)
                      .layoutWeight(1)
                  }
                  .width('100%')
                  if (item.activity !== '') {
                    Text(item.activity)
                      .fontSize(13)
                      .fontColor(Theme.sub)
                      .width('100%')
                      .margin({ top: 4 })
                  }
                  if (item.feeling !== '') {
                    Text('“' + item.feeling + '”')
                      .fontSize(13)
                      .fontColor(Theme.primaryDeep)
                      .width('100%')
                      .margin({ top: 6 })
                  }
                  if (item.note !== '') {
                    Text(item.note)
                      .fontSize(12)
                      .fontColor(Theme.sub)
                      .width('100%')
                      .margin({ top: 6 })
                  }
                  if (item.images.length > 0) {
                    PhotoGrid({ images: item.images, editable: false })
                      .margin({ top: 4 })
                  }
                  Row() {
                    Text('编辑')
                      .fontSize(12)
                      .fontColor(Theme.primary)
                      .onClick(() => {
                        this.openEditor(item);
                      })
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.End)
                  .margin({ top: 6 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                .padding(12)
                .backgroundColor(Theme.card)
                .borderRadius(Theme.radiusSm)
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)
              .margin({ bottom: 10 })
            }, (item: Memory) => item.id)
          }
          .width('100%')
        }, (group: YearGroup) => JSON.stringify(group))

        Row().height(80)
      }
      .padding({ left: 16, right: 16, top: 16 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(Theme.bg)
    .bindSheet(this.showEditor, this.editorBuilder(), {
      height: SheetSize.LARGE,
      showClose: false,
      dragBar: true,
      backgroundColor: Theme.bg,
      onDisappear: () => {
        this.showEditor = false;
        this.editing = null;
      }
    })
  }
}
