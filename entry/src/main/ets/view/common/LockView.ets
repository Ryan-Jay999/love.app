import { promptAction } from '@kit.ArkUI';
import { Store } from '../../common/Store';
import { Theme } from './Widgets';

@Component
export struct LockView {
  @State pwd: string = '';
  @State error: string = '';
  @State busy: boolean = false;

  private async doUnlock(): Promise<void> {
    if (this.pwd.length < 4) {
      this.error = '密码至少 4 位';
      return;
    }
    this.busy = true;
    const ok: boolean = await Store.unlock(this.pwd);
    this.busy = false;
    if (ok) {
      this.error = '';
      this.pwd = '';
      promptAction.showToast({ message: '解锁成功' });
    } else {
      this.error = '密码不正确，请重试';
      this.pwd = '';
    }
  }

  build() {
    Column() {
      Column() {
        Text('💗')
          .fontSize(52)
        Text('拾年')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.text)
          .margin({ top: 10 })
        Text('输入密码查看你们的回忆')
          .fontSize(13)
          .fontColor(Theme.sub)
          .margin({ top: 6 })
      }
      .margin({ top: 120 })

      Column() {
        TextInput({ text: this.pwd, placeholder: '请输入应用密码' })
          .type(InputType.Password)
          .maxLength(16)
          .height(48)
          .borderRadius(12)
          .backgroundColor('#FFFFFF')
          .onChange((value: string) => {
            this.pwd = value;
            this.error = '';
          })
          .onSubmit(() => {
            this.doUnlock();
          })

        if (this.error !== '') {
          Text(this.error)
            .fontSize(12)
            .fontColor('#E8506B')
            .margin({ top: 8 })
        }

        Button(this.busy ? '解锁中...' : '解 锁')
          .width('100%')
          .height(46)
          .borderRadius(23)
          .backgroundColor(Theme.primary)
          .margin({ top: 18 })
          .enabled(!this.busy)
          .onClick(() => {
            this.doUnlock();
          })
      }
      .padding(20)
      .width('100%')

      Text('数据保存在本机并以 AES-256 加密，忘记密码将无法恢复')
        .fontSize(11)
        .fontColor(Theme.sub)
        .textAlign(TextAlign.Center)
        .padding({ left: 32, right: 32 })
        .margin({ top: 30 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bg)
    .justifyContent(FlexAlign.Start)
  }
}
