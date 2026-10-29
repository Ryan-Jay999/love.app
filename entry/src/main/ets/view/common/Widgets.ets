export class Theme {
  static readonly primary: string = '#FF6B81';
  static readonly primaryDeep: string = '#E8506B';
  static readonly primarySoft: string = '#FFEDF1';
  static readonly bg: string = '#FFF7F9';
  static readonly card: string = '#FFFFFF';
  static readonly text: string = '#2B2B33';
  static readonly sub: string = '#8A8A99';
  static readonly line: string = '#F2E7EA';
  static readonly green: string = '#4CAF7D';
  static readonly orange: string = '#FF9F43';
  static readonly radius: number = 16;
  static readonly radiusSm: number = 10;
  static readonly gap: number = 12;
  static readonly pad: number = 16;
}

@Component
export struct Pill {
  label: string = '';
  active: boolean = false;
  onTap: () => void = () => {
  };

  build() {
    Text(this.label)
      .fontSize(13)
      .fontColor(this.active ? '#FFFFFF' : Theme.sub)
      .backgroundColor(this.active ? Theme.primary : '#FFFFFF')
      .borderRadius(14)
      .borderWidth(this.active ? 0 : 1)
      .borderColor(Theme.line)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .margin({ right: 8 })
      .onClick(() => {
        this.onTap();
      })
  }
}

@Component
export struct StatBox {
  value: string = '';
  label: string = '';
  color: string = Theme.primary;

  build() {
    Column() {
      Text(this.value)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.color)
      Text(this.label)
        .fontSize(12)
        .fontColor(Theme.sub)
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .padding({ top: 14, bottom: 14 })
  }
}

@Component
export struct EmptyTip {
  text: string = '还没有内容';

  build() {
    Column() {
      Text('🕊️')
        .fontSize(40)
      Text(this.text)
        .fontSize(14)
        .fontColor(Theme.sub)
        .margin({ top: 8 })
    }
    .width('100%')
    .padding({ top: 40, bottom: 40 })
    .justifyContent(FlexAlign.Center)
  }
}

@Builder
export function sectionTitle(title: string, action: string, onAction: () => void) {
  Row() {
    Text(title)
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .fontColor(Theme.text)
      .layoutWeight(1)
    if (action !== '') {
      Text(action)
        .fontSize(13)
        .fontColor(Theme.primary)
        .onClick(() => {
          onAction();
        })
    }
  }
  .width('100%')
  .padding({ left: 4, right: 4, bottom: 8 })
}

@Builder
export function fieldLabel(text: string) {
  Text(text)
    .fontSize(13)
    .fontColor(Theme.sub)
    .width('100%')
    .margin({ top: 12, bottom: 6 })
}
