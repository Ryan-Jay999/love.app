import { promptAction } from '@kit.ArkUI';
import { AppData, DATA_KEY, emptyAppData, MemoItem } from '../../model/Types';
import { MEMO_CATEGORIES, MEMO_PRESETS, OptionItem } from '../../common/Constants';
import { newId } from '../../common/Ids';
import { Store } from '../../common/Store';
import { MemoEditor } from '../../view/editors/MemoEditor';
import { EmptyTip, Theme } from '../../view/common/Widgets';

interface MemoGroup {
  category: string;
  items: MemoItem[];
}

@Component
export struct MemoTab {
  @StorageProp(DATA_KEY) data: AppData = emptyAppData();
  @State showEditor: boolean = false;
  @State editing: MemoItem | null = null;
  @State defaultCategory: string = '忌口';

  private groups(): MemoGroup[] {
    const result: MemoGroup[] = [];
    for (let i = 0; i < MEMO_CATEGORIES.length; i++) {
      const cat: string = MEMO_CATEGORIES[i].key;
      const items: MemoItem[] = [];
      for (let j = 0; j < this.data.memos.length; j++) {
        if (this.data.memos[j].category === cat) {
          items.push(this.data.memos[j]);
        }
      }
      if (items.length > 0) {
        const g: MemoGroup = { category: cat, items: items };
        result.push(g);
      }
    }
    return result;
  }

  private openEditor(item: MemoItem | null, category: string): void {
    this.editing = item;
    this.defaultCategory = category;
    this.showEditor = true;
  }

  private save(item: MemoItem): void {
    Store.commit((d: AppData) => {
      let updated: boolean = false;
      for (let i = 0; i < d.memos.length; i++) {
        if (d.memos[i].id === item.id) {
          d.memos[i] = item;
          updated = true;
        }
      }
      if (!updated) {
        d.memos.push(item);
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
      const next: MemoItem[] = [];
      for (let i = 0; i < d.memos.length; i++) {
        if (d.memos[i].id !== id) {
          next.push(d.memos[i]);
        }
      }
      d.memos = next;
    });
    this.showEditor = false;
    this.editing = null;
  }

  private quickAdd(preset: OptionItem): void {
    const item: MemoItem = { id: newId(), category: preset.key, value: preset.label, note: '' };
    Store.commit((d: AppData) => {
      d.memos.push(item);
    });
    promptAction.showToast({ message: '已加入「' + preset.key + '」' });
  }

  @Builder
  editorBuilder() {
    MemoEditor({
      initial: this.editing,
      defaultCategory: this.defaultCategory,
      onCancel: () => {
        this.showEditor = false;
      },
      onSave: (item: MemoItem) => {
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
          Text('TA 的细节')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.text)
          Text('记住这些，就不会踩雷')
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
            this.openEditor(null, '忌口');
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16 })

      Scroll() {
        Column() {
          Text('快速添加')
            .fontSize(12)
            .fontColor(Theme.sub)
            .width('100%')
            .margin({ top: 14 })
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(MEMO_PRESETS, (preset: OptionItem) => {
              Text('＋ ' + preset.label)
                .fontSize(12)
                .fontColor(Theme.primaryDeep)
                .backgroundColor(Theme.primarySoft)
                .borderRadius(14)
                .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                .margin({ right: 8, top: 8 })
                .onClick(() => {
                  this.quickAdd(preset);
                })
            }, (preset: OptionItem) => preset.label)
          }
          .width('100%')

          if (this.groups().length === 0) {
            EmptyTip({ text: '记下 TA 的忌口、过敏、尺码…' })
          }

          ForEach(this.groups(), (group: MemoGroup) => {
            Column() {
              Text(group.category)
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.primary)
                .width('100%')
                .margin({ bottom: 8 })
              ForEach(group.items, (item: MemoItem) => {
                Row() {
                  Column() {
                    Text(item.value)
                      .fontSize(14)
                      .fontColor(Theme.text)
                    if (item.note !== '') {
                      Text(item.note)
                        .fontSize(12)
                        .fontColor(Theme.sub)
                        .margin({ top: 3 })
                    }
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                  Text('›')
                    .fontSize(18)
                    .fontColor(Theme.sub)
                }
                .width('100%')
                .padding({ top: 10, bottom: 10 })
                .onClick(() => {
                  this.openEditor(item, item.category);
                })
                Divider().color(Theme.line)
              }, (item: MemoItem) => item.id)
            }
            .width('100%')
            .padding(14)
            .backgroundColor(Theme.card)
            .borderRadius(Theme.radius)
            .margin({ top: 12 })
          }, (group: MemoGroup) => JSON.stringify(group))

          Row().height(30)
        }
        .padding({ left: 16, right: 16 })
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
