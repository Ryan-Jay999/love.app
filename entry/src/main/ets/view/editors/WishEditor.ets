import { BOARD_GIFT, BOARD_TOGETHER, SubTask, WishItem } from '../../model/Types';
import { newId } from '../../common/Ids';
import { Theme } from '../common/Widgets';

@Component
export struct WishEditor {
  initial: WishItem | null = null;
  defaultBoard: string = BOARD_TOGETHER;
  onCancel: () => void = () => {
  };
  onSave: (item: WishItem) => void = () => {
  };
  onDelete: () => void = () => {
  };

  @State title: string = '';
  @State board: string = BOARD_TOGETHER;
  @State note: string = '';
  @State isTravel: boolean = false;
  @State subtasks: SubTask[] = [];
  @State newTask: string = '';

  aboutToAppear(): void {
    this.board = this.defaultBoard;
    if (this.initial !== null) {
      this.title = this.initial.title;
      this.board = this.initial.board;
      this.note = this.initial.note;
      this.isTravel = this.initial.isTravel;
      this.subtasks = this.initial.subtasks.slice(0);
    }
  }

  private addTask(): void {
    const text: string = this.newTask.trim();
    if (text === '') {
      return;
    }
    const task: SubTask = { id: newId(), text: text, done: false };
    this.subtasks = this.subtasks.concat([task]);
    this.newTask = '';
  }

  private removeTask(id: string): void {
    const next: SubTask[] = [];
    for (let i = 0; i < this.subtasks.length; i++) {
      if (this.subtasks[i].id !== id) {
        next.push(this.subtasks[i]);
      }
    }
    this.subtasks = next;
  }

  private save(): void {
    const item: WishItem = {
      id: this.initial === null ? newId() : this.initial.id,
      board: this.board,
      title: this.title.trim() === '' ? '新的心愿' : this.title.trim(),
      note: this.note,
      done: this.initial === null ? false : this.initial.done,
      doneDate: this.initial === null ? '' : this.initial.doneDate,
      subtasks: this.subtasks,
      isTravel: this.isTravel,
      createdAt: this.initial === null ? Date.now() : this.initial.createdAt
    };
    this.onSave(item);
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
        Text(this.initial === null ? '添加心愿' : '编辑心愿')
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
          Text('心愿内容')
            .fontSize(13)
            .fontColor(Theme.sub)
            .width('100%')
          TextInput({ text: this.title, placeholder: '比如：一起去看海' })
            .height(46)
            .backgroundColor(Theme.card)
            .borderRadius(Theme.radiusSm)
            .margin({ top: 6 })
            .onChange((value: string) => {
              this.title = value;
            })

          Text('放在哪个板块')
            .fontSize(13)
            .fontColor(Theme.sub)
            .width('100%')
            .margin({ top: 14 })
          Row() {
            Text('我想和TA一起做')
              .fontSize(13)
              .fontColor(this.board === BOARD_TOGETHER ? '#FFFFFF' : Theme.sub)
              .backgroundColor(this.board === BOARD_TOGETHER ? Theme.primary : Theme.card)
              .borderRadius(16)
              .padding({ left: 14, right: 14, top: 8, bottom: 8 })
              .margin({ right: 8 })
              .onClick(() => {
                this.board = BOARD_TOGETHER;
              })
            Text('我想送给TA')
              .fontSize(13)
              .fontColor(this.board === BOARD_GIFT ? '#FFFFFF' : Theme.sub)
              .backgroundColor(this.board === BOARD_GIFT ? Theme.primary : Theme.card)
              .borderRadius(16)
              .padding({ left: 14, right: 14, top: 8, bottom: 8 })
              .onClick(() => {
                this.board = BOARD_GIFT;
              })
          }
          .width('100%')
          .margin({ top: 6 })

          Row() {
            Text('这是一次旅行')
              .fontSize(14)
              .fontColor(Theme.text)
              .layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.isTravel })
              .selectedColor(Theme.primary)
              .onChange((isOn: boolean) => {
                this.isTravel = isOn;
              })
          }
          .width('100%')
          .padding({ top: 14, bottom: 14 })
          .margin({ top: 14 })
          .backgroundColor(Theme.card)
          .borderRadius(Theme.radiusSm)

          Text('攻略清单 / 小步骤')
            .fontSize(13)
            .fontColor(Theme.sub)
            .width('100%')
            .margin({ top: 14 })
          if (this.subtasks.length > 0) {
            Column() {
              ForEach(this.subtasks, (task: SubTask, index: number) => {
                Row() {
                  Text('• ' + task.text)
                    .fontSize(14)
                    .fontColor(Theme.text)
                    .layoutWeight(1)
                  Text('删除')
                    .fontSize(12)
                    .fontColor(Theme.sub)
                    .onClick(() => {
                      this.removeTask(task.id);
                    })
                }
                .width('100%')
                .padding({ top: 8, bottom: 8 })
              }, (task: SubTask) => JSON.stringify(task))
            }
            .width('100%')
            .padding({ left: 12, right: 12 })
            .backgroundColor(Theme.card)
            .borderRadius(Theme.radiusSm)
            .margin({ top: 6 })
          }
          Row() {
            TextInput({ text: this.newTask, placeholder: '添加一步，例如：订机票' })
              .layoutWeight(1)
              .height(42)
              .backgroundColor(Theme.card)
              .borderRadius(Theme.radiusSm)
              .onChange((value: string) => {
                this.newTask = value;
              })
              .onSubmit(() => {
                this.addTask();
              })
            Button('添加')
              .height(42)
              .fontSize(13)
              .backgroundColor(Theme.primary)
              .borderRadius(Theme.radiusSm)
              .margin({ left: 8 })
              .onClick(() => {
                this.addTask();
              })
          }
          .width('100%')
          .margin({ top: 8 })

          Text('备注 / 攻略细节')
            .fontSize(13)
            .fontColor(Theme.sub)
            .width('100%')
            .margin({ top: 16 })
          TextArea({ text: this.note, placeholder: '想去的店、预算、交通、想去的时间…' })
            .height(110)
            .backgroundColor(Theme.card)
            .borderRadius(Theme.radiusSm)
            .margin({ top: 6 })
            .onChange((value: string) => {
              this.note = value;
            })

          if (this.initial !== null) {
            Button('删除这个心愿')
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
