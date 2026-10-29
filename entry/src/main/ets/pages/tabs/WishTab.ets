import { promptAction } from '@kit.ArkUI';
import { AppData, BOARD_GIFT, BOARD_TOGETHER, DATA_KEY, emptyAppData, SubTask, WishItem } from '../../model/Types';
import { DateUtil } from '../../common/DateUtil';
import { Store } from '../../common/Store';
import { WishEditor } from '../../view/editors/WishEditor';
import { EmptyTip, Theme } from '../../view/common/Widgets';

@Component
export struct WishTab {
  @StorageProp(DATA_KEY) data: AppData = emptyAppData();
  @State board: string = BOARD_TOGETHER;
  @State showEditor: boolean = false;
  @State editing: WishItem | null = null;

  private items(): WishItem[] {
    const result: WishItem[] = [];
    for (let i = 0; i < this.data.wishes.length; i++) {
      if (this.data.wishes[i].board === this.board) {
        result.push(this.data.wishes[i]);
      }
    }
    result.sort((a: WishItem, b: WishItem) => {
      if (a.done === b.done) {
        return b.createdAt - a.createdAt;
      }
      return a.done ? 1 : -1;
    });
    return result;
  }

  private doneCount(): number {
    let n: number = 0;
    const list: WishItem[] = this.items();
    for (let i = 0; i < list.length; i++) {
      if (list[i].done) {
        n += 1;
      }
    }
    return n;
  }

  private openEditor(item: WishItem | null): void {
    this.editing = item;
    this.showEditor = true;
  }

  private save(item: WishItem): void {
    Store.commit((d: AppData) => {
      let updated: boolean = false;
      for (let i = 0; i < d.wishes.length; i++) {
        if (d.wishes[i].id === item.id) {
          d.wishes[i] = item;
          updated = true;
        }
      }
      if (!updated) {
        d.wishes.push(item);
      }
    });
    this.showEditor = false;
    this.editing = null;
  }

  private deleteCurrent(): void {
    if (this.editing === null) {
      return;
    }
    const id: string = this.editing.id;
    Store.commit((d: AppData) => {
      const next: WishItem[] = [];
      for (let i = 0; i < d.wishes.length; i++) {
        if (d.wishes[i].id !== id) {
          next.push(d.wishes[i]);
        }
      }
      d.wishes = next;
    });
    this.showEditor = false;
    this.editing = null;
  }

  private toggleDone(item: WishItem): void {
    Store.commit((d: AppData) => {
      for (let i = 0; i < d.wishes.length; i++) {
        if (d.wishes[i].id === item.id) {
          const next: boolean = !d.wishes[i].done;
          d.wishes[i].done = next;
          d.wishes[i].doneDate = next ? DateUtil.todayStr() : '';
        }
      }
    });
  }

  private toggleSubtask(item: WishItem, taskId: string): void {
    Store.commit((d: AppData) => {
      for (let i = 0; i < d.wishes.length; i++) {
        if (d.wishes[i].id === item.id) {
          for (let j = 0; j < d.wishes[i].subtasks.length; j++) {
            if (d.wishes[i].subtasks[j].id === taskId) {
              d.wishes[i].subtasks[j].done = !d.wishes[i].subtasks[j].done;
            }
          }
        }
      }
    });
  }

  private subProgress(item: WishItem): string {
    let done: number = 0;
    for (let i = 0; i < item.subtasks.length; i++) {
      if (item.subtasks[i].done) {
        done += 1;
      }
    }
    return done + '/' + item.subtasks.length;
  }

  @Builder
  editorBuilder() {
    WishEditor({
      initial: this.editing,
      defaultBoard: this.board,
      onCancel: () => {
        this.showEditor = false;
      },
      onSave: (item: WishItem) => {
        this.save(item);
      },
      onDelete: () => {
        this.deleteCurrent();
      }
    })
  }

  build() {
    Column() {
      Row() {
        Column() {
          Text('心愿清单')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.text)
          Text('一起完成 ' + this.doneCount() + ' / ' + this.items().length + ' 个心愿')
            .fontSize(12)
            .fontColor(Theme.sub)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Text('＋ 添加')
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
      .padding({ left: 16, right: 16, top: 16 })

      Row() {
        Text('我想和TA一起做')
          .fontSize(14)
          .fontColor(this.board === BOARD_TOGETHER ? '#FFFFFF' : Theme.sub)
          .backgroundColor(this.board === BOARD_TOGETHER ? Theme.primary : Theme.card)
          .borderRadius(18)
          .padding({ left: 16, right: 16, top: 9, bottom: 9 })
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.board = BOARD_TOGETHER;
          })
        Text('我想送给TA')
          .fontSize(14)
          .fontColor(this.board === BOARD_GIFT ? '#FFFFFF' : Theme.sub)
          .backgroundColor(this.board === BOARD_GIFT ? Theme.primary : Theme.card)
          .borderRadius(18)
          .padding({ left: 16, right: 16, top: 9, bottom: 9 })
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ left: 10 })
          .onClick(() => {
            this.board = BOARD_GIFT;
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14 })

      Scroll() {
        Column() {
          if (this.items().length === 0) {
            EmptyTip({ text: this.board === BOARD_TOGETHER ? '写下想一起做的事吧' : '写下想送出的心意吧' })
          }
          ForEach(this.items(), (item: WishItem) => {
            Column() {
              Row() {
                Text(item.done ? '☑' : '☐')
                  .fontSize(20)
                  .fontColor(item.done ? Theme.green : Theme.sub)
                  .margin({ right: 10 })
                  .onClick(() => {
                    this.toggleDone(item);
                    promptAction.showToast({ message: item.done ? '已重新打开' : '又完成一个心愿 🎉' });
                  })
                Column() {
                  Text(item.title)
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(item.done ? Theme.sub : Theme.text)
                    .decoration({ type: item.done ? TextDecorationType.LineThrough : TextDecorationType.None })
                  if (item.done && item.doneDate !== '') {
                    Text('完成于 ' + item.doneDate)
                      .fontSize(11)
                      .fontColor(Theme.green)
                      .margin({ top: 3 })
                  } else if (item.isTravel) {
                    Text('✈️ 旅行心愿')
                      .fontSize(11)
                      .fontColor(Theme.orange)
                      .margin({ top: 3 })
                  }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                Text('编辑')
                  .fontSize(12)
                  .fontColor(Theme.primary)
                  .onClick(() => {
                    this.openEditor(item);
                  })
              }
              .width('100%')

              if (item.subtasks.length > 0) {
                Column() {
                  Row() {
                    Text('攻略清单')
                      .fontSize(11)
                      .fontColor(Theme.sub)
                      .layoutWeight(1)
                    Text(this.subProgress(item))
                      .fontSize(11)
                      .fontColor(Theme.primary)
                  }
                  .width('100%')
                  .margin({ bottom: 4 })
                  ForEach(item.subtasks, (task: SubTask) => {
                    Row() {
                      Text(task.done ? '✓' : '○')
                        .fontSize(13)
                        .fontColor(task.done ? Theme.green : Theme.sub)
                        .width(22)
                        .onClick(() => {
                          this.toggleSubtask(item, task.id);
                        })
                      Text(task.text)
                        .fontSize(13)
                        .fontColor(task.done ? Theme.sub : Theme.text)
                        .decoration({ type: task.done ? TextDecorationType.LineThrough : TextDecorationType.None })
                        .layoutWeight(1)
                    }
                    .width('100%')
                    .padding({ top: 4, bottom: 4 })
                  }, (task: SubTask) => task.id)
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
                .padding(10)
                .backgroundColor(Theme.bg)
                .borderRadius(8)
                .margin({ top: 8 })
              }

              if (item.note !== '') {
                Text(item.note)
                  .fontSize(12)
                  .fontColor(Theme.sub)
                  .width('100%')
                  .margin({ top: 8 })
                  .maxLines(4)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding(14)
            .backgroundColor(Theme.card)
            .borderRadius(Theme.radius)
            .margin({ top: 10 })
          }, (item: WishItem) => JSON.stringify(item))

          Row().height(30)
        }
        .padding({ left: 16, right: 16, top: 10 })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
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
