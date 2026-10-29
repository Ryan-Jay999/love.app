import { promptAction } from '@kit.ArkUI';
import { Memory } from '../../model/Types';
import { newId } from '../../common/Ids';
import { DateUtil } from '../../common/DateUtil';
import { MOODS, OptionItem } from '../../common/Constants';
import { PhotoStore } from '../../common/PhotoStore';
import { PhotoGrid } from '../common/PhotoGrid';
import { Theme } from '../common/Widgets';

@Component
export struct MemoryEditor {
  initial: Memory | null = null;
  onCancel: () => void = () => {
  };
  onSave: (item: Memory) => void = () => {
  };
  onDelete: () => void = () => {
  };

  @State dateText: string = DateUtil.todayStr();
  @State place: string = '';
  @State activity: string = '';
  @State feeling: string = '';
  @State note: string = '';
  @State images: string[] = [];
  @State mood: string = '';
  @State busy: boolean = false;

  aboutToAppear(): void {
    if (this.initial !== null) {
      this.dateText = this.initial.date;
      this.place = this.initial.place;
      this.activity = this.initial.activity;
      this.feeling = this.initial.feeling;
      this.note = this.initial.note;
      this.images = this.initial.images.slice(0);
      this.mood = this.initial.mood;
    }
  }

  private pickDate(): void {
    const selected: Date = DateUtil.parseDateStr(this.dateText);
    DatePickerDialog.show({
      start: new Date(1990, 0, 1),
      end: new Date(2100, 11, 31),
      selected: selected,
      onDateAccept: (value: Date) => {
        this.dateText = DateUtil.toDateStr(value);
      }
    });
  }

  private async addPhotos(): Promise<void> {
    this.busy = true;
    const uris: string[] = await PhotoStore.pickImages(Math.max(1, 9 - this.images.length));
    const names: string[] = PhotoStore.importUris(uris);
    if (names.length > 0) {
      this.images = this.images.concat(names);
    }
    if (uris.length > names.length) {
      promptAction.showToast({ message: '有 ' + (uris.length - names.length) + ' 张照片没能加入，请重试' });
    }
    this.busy = false;
  }

  private save(): void {
    const item: Memory = {
      id: this.initial === null ? newId() : this.initial.id,
      date: this.dateText,
      place: this.place,
      activity: this.activity,
      feeling: this.feeling,
      note: this.note,
      images: this.images,
      mood: this.mood,
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
        Text(this.initial === null ? '记录回忆' : '编辑回忆')
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
          Text('日期')
            .fontSize(13)
            .fontColor(Theme.sub)
            .width('100%')
          Row() {
            Text(this.dateText)
              .fontSize(16)
              .fontColor(Theme.text)
              .layoutWeight(1)
            Text('选择 ›')
              .fontSize(13)
              .fontColor(Theme.primary)
          }
          .width('100%')
          .padding(14)
          .backgroundColor(Theme.card)
          .borderRadius(Theme.radiusSm)
          .margin({ top: 6 })
          .onClick(() => {
            this.pickDate();
          })

          Text('地点')
            .fontSize(13)
            .fontColor(Theme.sub)
            .width('100%')
            .margin({ top: 14 })
          TextInput({ text: this.place, placeholder: '比如：南山路的猫咖啡馆' })
            .height(46)
            .backgroundColor(Theme.card)
            .borderRadius(Theme.radiusSm)
            .margin({ top: 6 })
            .onChange((value: string) => {
              this.place = value;
            })

          Text('做了什么')
            .fontSize(13)
            .fontColor(Theme.sub)
            .width('100%')
            .margin({ top: 14 })
          TextInput({ text: this.activity, placeholder: '一起做了什么？' })
            .height(46)
            .backgroundColor(Theme.card)
            .borderRadius(Theme.radiusSm)
            .margin({ top: 6 })
            .onChange((value: string) => {
              this.activity = value;
            })

          Text('一句话感受')
            .fontSize(13)
            .fontColor(Theme.sub)
            .width('100%')
            .margin({ top: 14 })
          TextInput({ text: this.feeling, placeholder: '今天的心里话' })
            .height(46)
            .backgroundColor(Theme.card)
            .borderRadius(Theme.radiusSm)
            .margin({ top: 6 })
            .onChange((value: string) => {
              this.feeling = value;
            })

          Text('照片')
            .fontSize(13)
            .fontColor(Theme.sub)
            .width('100%')
            .margin({ top: 14 })
          PhotoGrid({
            images: this.images,
            editable: true,
            onAdd: () => {
              this.addPhotos();
            },
            onRemove: (name: string) => {
              const next: string[] = [];
              for (let i = 0; i < this.images.length; i++) {
                if (this.images[i] !== name) {
                  next.push(this.images[i]);
                }
              }
              this.images = next;
              PhotoStore.remove(name);
            }
          })

          Text('心情')
            .fontSize(13)
            .fontColor(Theme.sub)
            .width('100%')
            .margin({ top: 14 })
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(MOODS, (m: OptionItem) => {
              Text(m.label)
                .fontSize(13)
                .fontColor(this.mood === m.key ? '#FFFFFF' : Theme.sub)
                .backgroundColor(this.mood === m.key ? Theme.primary : Theme.card)
                .borderRadius(14)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .margin({ right: 8, top: 8 })
                .onClick(() => {
                  this.mood = this.mood === m.key ? '' : m.key;
                })
            }, (m: OptionItem) => m.key)
          }
          .width('100%')

          Text('备注')
            .fontSize(13)
            .fontColor(Theme.sub)
            .width('100%')
            .margin({ top: 14 })
          TextArea({ text: this.note, placeholder: '还想记下点什么？' })
            .height(100)
            .backgroundColor(Theme.card)
            .borderRadius(Theme.radiusSm)
            .margin({ top: 6 })
            .onChange((value: string) => {
              this.note = value;
            })

          if (this.initial !== null) {
            Button('删除这条回忆')
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
