import { Theme } from './Widgets';

@CustomDialog
export struct PasswordDialog {
  controller?: CustomDialogController;
  title: string = '应用密码';
  desc: string = '';
  withConfirm: boolean = false;
  confirmText: string = '确定';
  onSubmit: (pwd: string, pwd2: string) => Promise<string> = () => Promise.resolve('');

  @State pwd: string = '';
  @State pwd2: string = '';
  @State error: string = '';
  @State busy: boolean = false;

  private async submit(): Promise<void> {
    if (this.pwd.length < 4) {
      this.error = '密码至少 4 位';
      return;
    }
    if (this.withConfirm && this.pwd !== this.pwd2) {
      this.error = '两次输入的密码不一致';
      return;
    }
    this.busy = true;
    const message: string = await this.onSubmit(this.pwd, this.pwd2);
    this.busy = false;
    if (message === '') {
      this.controller?.close();
    } else {
      this.error = message;
      this.pwd = '';
      this.pwd2 = '';
    }
  }

  build() {
    Column() {
      Text(this.title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(Theme.text)
      if (this.desc !== '') {
        Text(this.desc)
          .fontSize(12)
          .fontColor(Theme.sub)
          .textAlign(TextAlign.Center)
          .margin({ top: 8 })
      }
      TextInput({ text: this.pwd, placeholder: '请输入密码（至少 4 位）' })
        .type(InputType.Password)
        .maxLength(16)
        .height(46)
        .backgroundColor(Theme.bg)
        .borderRadius(10)
        .margin({ top: 16 })
        .onChange((value: string) => {
          this.pwd = value;
          this.error = '';
        })
      if (this.withConfirm) {
        TextInput({ text: this.pwd2, placeholder: '请再次输入密码' })
          .type(InputType.Password)
          .maxLength(16)
          .height(46)
          .backgroundColor(Theme.bg)
          .borderRadius(10)
          .margin({ top: 10 })
          .onChange((value: string) => {
            this.pwd2 = value;
            this.error = '';
          })
      }
      if (this.error !== '') {
        Text(this.error)
          .fontSize(12)
          .fontColor(Theme.primaryDeep)
          .width('100%')
          .margin({ top: 8 })
      }
      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(42)
          .backgroundColor(Theme.bg)
          .fontColor(Theme.sub)
          .borderRadius(21)
          .onClick(() => {
            this.controller?.close();
          })
        Button(this.busy ? '处理中...' : this.confirmText)
          .layoutWeight(1)
          .height(42)
          .backgroundColor(Theme.primary)
          .fontColor('#FFFFFF')
          .borderRadius(21)
          .margin({ left: 10 })
          .enabled(!this.busy)
          .onClick(() => {
            this.submit();
          })
      }
      .width('100%')
      .margin({ top: 18 })
    }
    .width('100%')
    .padding(20)
  }
}
