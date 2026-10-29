import { MemoItem } from '../../model/Types';
import { newId } from '../../common/Ids';
import { MEMO_CATEGORIES, OptionItem } from '../../common/Constants';
import { Theme } from '../common/Widgets';

@Component
export struct MemoEditor {
  initial: MemoItem | null = null;
  defaultCategory: string = '忌口';
  onCancel: () => void = () => {
  };
  onSave: (item: MemoItem) => void = () => {
  };
  onDelete: () => void = () => {
  };

  @State category: string = '忌口';
  @State value: string = '';
  @State note: string = '';

  aboutToAppear(): void {
    this.category = this.defaultCategory;
    if (this.initial !== null) {
      this.category = this.initial.category;
      this.value = this.initial.value;
      this.note = this.initial.note;
    }
  }

  private save(): void {
    if (this.value.trim() === '') {
      return;
    }
    const item: MemoItem = {
      id: this.initial === null ? newId() : this.initial.id,
      category: this.category,
      value: this.value.trim(),
      note: this.note
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
        Text(this.initial === null ? '添加细节' : '编辑细节')
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
          Text('分类')
            .fontSize(13)
            .fontColor(Theme.sub)
            .width('100%')
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(MEMO_CATEGORIES, (item: OptionItem) => {
              Text(item.label)
                .fontSize(13)
                .fontColor(this.category === item.key ? '#FFFFFF' : Theme.sub)
                .backgroundColor(this.category === item.key ? Theme.primary : Theme.card)
                .borderRadius(14)
                .padding({ left: 14, right: 14, top: 7, bottom: 7 })
                .margin({ right: 8, top: 8 })
                .onClick(() => {
                  this.category = item.key;
                })
            }, (item: OptionItem) => item.key)
          }
          .width('100%')
          .margin({ top: 6 })

          Text('内容')
            .fontSize(13)
            .fontColor(Theme.sub)
            .width('100%')
            .margin({ top: 14 })
          TextInput({ text: this.value, placeholder: '比如：不吃香菜 / 鞋码 37' })
            .height(46)
            .backgroundColor(Theme.card)
            .borderRadius(Theme.radiusSm)
            .margin({ top: 6 })
            .onChange((value: string) => {
              this.value = value;
            })

          Text('补充说明')
            .fontSize(13)
            .fontColor(Theme.sub)
            .width('100%')
            .margin({ top: 14 })
          TextArea({ text: this.note, placeholder: '例如：一点点香菜都不行 / 喜欢某品牌的某款' })
            .height(90)
            .backgroundColor(Theme.card)
            .borderRadius(Theme.radiusSm)
            .margin({ top: 6 })
            .onChange((value: string) => {
              this.note = value;
            })

          if (this.initial !== null) {
            Button('删除这条记录')
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
