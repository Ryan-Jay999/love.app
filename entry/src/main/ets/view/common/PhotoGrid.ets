import { PhotoStore } from '../../common/PhotoStore';
import { Theme } from './Widgets';

@Component
export struct PhotoGrid {
  @Prop images: string[] = [];
  editable: boolean = false;
  onAdd: () => void = () => {
  };
  onRemove: (name: string) => void = () => {
  };
  onPreview: (name: string) => void = () => {
  };

  @State previewName: string = '';
  @State previewShow: boolean = false;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.images, (name: string) => {
        Stack({ alignContent: Alignment.TopEnd }) {
          Image(PhotoStore.displayPath(name))
            .width(96)
            .height(96)
            .objectFit(ImageFit.Cover)
            .borderRadius(10)
            .onClick(() => {
              if (this.onPreview !== null) {
                this.onPreview(name);
              }
              this.previewName = name;
              this.previewShow = true;
            })
          if (this.editable) {
            Text('✕')
              .fontSize(12)
              .fontColor('#FFFFFF')
              .backgroundColor('#99000000')
              .borderRadius(9)
              .width(18)
              .height(18)
              .textAlign(TextAlign.Center)
              .margin({ top: 4, right: 4 })
              .onClick(() => {
                this.onRemove(name);
              })
          }
        }
        .width(96)
        .height(96)
        .margin({ right: 8, top: 8 })
      }, (name: string) => name)

      if (this.editable) {
        Column() {
          Text('＋')
            .fontSize(24)
            .fontColor(Theme.primary)
          Text('加照片')
            .fontSize(10)
            .fontColor(Theme.sub)
        }
        .width(96)
        .height(96)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Theme.card)
        .borderRadius(10)
        .borderWidth(1)
        .borderColor(Theme.line)
        .borderStyle(BorderStyle.Dashed)
        .margin({ right: 8, top: 8 })
        .onClick(() => {
          this.onAdd();
        })
      }
      }
      .width('100%')

      if (this.previewShow) {
        Column() {
          Image(PhotoStore.displayPath(this.previewName))
            .width('100%')
            .objectFit(ImageFit.Contain)
            .onClick(() => {
              this.previewShow = false;
            })
          Text('点击任意处关闭')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .margin({ top: 12 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#000000')
        .justifyContent(FlexAlign.Center)
        .position({ x: 0, y: 0 })
        .zIndex(99)
      }
    }
    .width('100%')
  }
}
