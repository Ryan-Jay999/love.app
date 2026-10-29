import { promptAction } from '@kit.ArkUI';
import { AppData, DATA_KEY, emptyAppData } from '../../model/Types';
import { Backup, BackupResult } from '../../common/Backup';
import { DateUtil } from '../../common/DateUtil';
import { Store } from '../../common/Store';
import { PasswordDialog } from '../../view/common/PasswordDialog';
import { Theme } from '../../view/common/Widgets';

@Component
export struct ProfileTab {
  @StorageProp(DATA_KEY) data: AppData = emptyAppData();
  @StorageLink('loveAppLocked') locked: boolean = false;
  @State lockOn: boolean = Store.hasLock();

  private enableDialog: CustomDialogController = new CustomDialogController({
    builder: PasswordDialog({
      title: '设置应用密码',
      desc: '密码用于加密本机数据。忘记密码将无法恢复，请务必牢记。',
      withConfirm: true,
      confirmText: '开启',
      onSubmit: async (pwd: string, pwd2: string): Promise<string> => {
        await Store.enableLock(pwd);
        this.lockOn = Store.hasLock();
        return '';
      }
    }),
    autoCancel: true,
    customStyle: true
  });

  private changeDialog: CustomDialogController = new CustomDialogController({
    builder: PasswordDialog({
      title: '修改应用密码',
      desc: '需要先输入当前密码进行验证。',
      withConfirm: true,
      confirmText: '修改',
      onSubmit: async (pwd: string, pwd2: string): Promise<string> => {
        const ok: boolean = await Store.changePassword(pwd, pwd2);
        return ok ? '' : '当前密码不正确';
      }
    }),
    autoCancel: true,
    customStyle: true
  });

  private disableDialog: CustomDialogController = new CustomDialogController({
    builder: PasswordDialog({
      title: '关闭应用密码',
      desc: '关闭后数据将以明文保存在本机。',
      withConfirm: false,
      confirmText: '关闭',
      onSubmit: async (pwd: string, pwd2: string): Promise<string> => {
        const ok: boolean = await Store.disableLock(pwd);
        if (ok) {
          this.lockOn = false;
          return '';
        }
        return '密码不正确';
      }
    }),
    autoCancel: true,
    customStyle: true
  });

  private distinctCities(): number {
    const names: string[] = [];
    for (let i = 0; i < this.data.memories.length; i++) {
      const place: string = this.data.memories[i].place.trim();
      if (place !== '' && names.indexOf(place) < 0) {
        names.push(place);
      }
    }
    return names.length;
  }

  private wishRate(): string {
    let total: number = 0;
    let done: number = 0;
    for (let i = 0; i < this.data.wishes.length; i++) {
      total += 1;
      if (this.data.wishes[i].done) {
        done += 1;
      }
    }
    if (total === 0) {
      return '0%';
    }
    return Math.round(done * 100 / total) + '%';
  }

  private setStartDate(): void {
    const current: Date = this.data.settings.startDate === '' ? new Date() :
    DateUtil.parseDateStr(this.data.settings.startDate);
    DatePickerDialog.show({
      start: new Date(1990, 0, 1),
      end: new Date(2100, 11, 31),
      selected: current,
      onDateAccept: (value: Date) => {
        Store.commit((d: AppData) => {
          d.settings.startDate = DateUtil.toDateStr(value);
        });
      }
    });
  }

  private async exportAll(): Promise<void> {
    const ctx = Store.context();
    if (ctx === null) {
      return;
    }
    promptAction.showToast({ message: '正在打包…' });
    const zipPath: string = await Backup.exportZip();
    const result: BackupResult = await Backup.saveToUserFile(ctx, zipPath);
    promptAction.showToast({ message: result.message });
  }

  private confirmImport(): void {
    AlertDialog.show({
      title: '导入备份',
      message: '导入会覆盖当前全部记录，确定继续吗？',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '继续导入',
        fontColor: Theme.primary,
        action: () => {
          this.doImport();
        }
      }
    });
  }

  private async doImport(): Promise<void> {
    const ctx = Store.context();
    if (ctx === null) {
      return;
    }
    const result: BackupResult = await Backup.importFromUser(ctx);
    promptAction.showToast({ message: result.message });
  }

  build() {
    Scroll() {
      Column() {
        Text('我的')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.text)
          .width('100%')
          .margin({ top: 6 })

        // 统计
        Column() {
          Row() {
            Column() {
              Text('' + DateUtil.daysTogether(this.data.settings.startDate))
                .fontSize(32)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              Text('相恋天数')
                .fontSize(12)
                .fontColor('#FFFFFFCC')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            Column() {
              Text(this.wishRate())
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              Text('心愿完成率')
                .fontSize(11)
                .fontColor('#FFFFFFCC')
            }
            .alignItems(HorizontalAlign.End)
          }
          .width('100%')
          Row() {
            Column() {
              Text('' + this.data.memories.length)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              Text('回忆')
                .fontSize(11)
                .fontColor('#FFFFFFCC')
            }
            .layoutWeight(1)
            Column() {
              Text('' + this.distinctCities())
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              Text('去过的地方')
                .fontSize(11)
                .fontColor('#FFFFFFCC')
            }
            .layoutWeight(1)
            Column() {
              Text('' + this.data.moods.length)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              Text('心情记录')
                .fontSize(11)
                .fontColor('#FFFFFFCC')
            }
            .layoutWeight(1)
            Column() {
              Text('' + this.data.wishes.length)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              Text('心愿')
                .fontSize(11)
                .fontColor('#FFFFFFCC')
            }
            .layoutWeight(1)
          }
          .width('100%')
          .margin({ top: 16 })
        }
        .width('100%')
        .padding(20)
        .borderRadius(20)
        .linearGradient({
          angle: 135,
          colors: [[Theme.primary, 0.0], ['#FF9F8E', 1.0]]
        })
        .alignItems(HorizontalAlign.Start)
        .margin({ top: 12 })

        // 基本信息
        Column() {
          Row() {
            Text('在一起的起始日期')
              .fontSize(14)
              .fontColor(Theme.text)
              .layoutWeight(1)
            Text(this.data.settings.startDate === '' ? '未设置' : this.data.settings.startDate)
              .fontSize(14)
              .fontColor(Theme.primary)
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })
          .onClick(() => {
            this.setStartDate();
          })
          Divider().color(Theme.line)
          Row() {
            Text('TA 的称呼')
              .fontSize(14)
              .fontColor(Theme.text)
              .layoutWeight(1)
            TextInput({ text: this.data.settings.partnerName, placeholder: 'TA' })
              .width(130)
              .height(38)
              .textAlign(TextAlign.End)
              .backgroundColor('transparent')
              .onChange((value: string) => {
                Store.commit((d: AppData) => {
                  d.settings.partnerName = value;
                });
              })
          }
          .width('100%')
          .padding({ top: 6, bottom: 6 })
          Divider().color(Theme.line)
          Row() {
            Text('我的称呼')
              .fontSize(14)
              .fontColor(Theme.text)
              .layoutWeight(1)
            TextInput({ text: this.data.settings.myName, placeholder: '我' })
              .width(130)
              .height(38)
              .textAlign(TextAlign.End)
              .backgroundColor('transparent')
              .onChange((value: string) => {
                Store.commit((d: AppData) => {
                  d.settings.myName = value;
                });
              })
          }
          .width('100%')
          .padding({ top: 6, bottom: 6 })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        .backgroundColor(Theme.card)
        .borderRadius(Theme.radius)
        .margin({ top: 12 })

        // 安全
        Column() {
          Row() {
            Text('应用密码锁')
              .fontSize(14)
              .fontColor(Theme.text)
              .layoutWeight(1)
            if (this.lockOn) {
              Text('修改')
                .fontSize(13)
                .fontColor(Theme.primary)
                .margin({ right: 14 })
                .onClick(() => {
                  this.changeDialog.open();
                })
              Text('关闭')
                .fontSize(13)
                .fontColor(Theme.sub)
                .onClick(() => {
                  this.disableDialog.open();
                })
            } else {
              Text('开启')
                .fontSize(13)
                .fontColor(Theme.primary)
                .onClick(() => {
                  this.enableDialog.open();
                })
            }
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })
          if (this.lockOn) {
            Divider().color(Theme.line)
            Row() {
              Text('立即锁定')
                .fontSize(14)
                .fontColor(Theme.text)
                .layoutWeight(1)
              Text('›')
                .fontSize(16)
                .fontColor(Theme.sub)
            }
            .width('100%')
            .padding({ top: 12, bottom: 12 })
            .onClick(() => {
              Store.lockNow();
              this.locked = true;
            })
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        .backgroundColor(Theme.card)
        .borderRadius(Theme.radius)
        .margin({ top: 12 })

        // 备份
        Column() {
          Row() {
            Column() {
              Text('导出备份')
                .fontSize(14)
                .fontColor(Theme.text)
              Text('数据 + 全部照片打包为 zip')
                .fontSize(11)
                .fontColor(Theme.sub)
                .margin({ top: 3 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            Text('导出 ›')
              .fontSize(13)
              .fontColor(Theme.primary)
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })
          .onClick(() => {
            this.exportAll();
          })
          Divider().color(Theme.line)
          Row() {
            Column() {
              Text('导入备份')
                .fontSize(14)
                .fontColor(Theme.text)
              Text('从 zip 还原全部记录')
                .fontSize(11)
                .fontColor(Theme.sub)
                .margin({ top: 3 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            Text('导入 ›')
              .fontSize(13)
              .fontColor(Theme.primary)
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })
          .onClick(() => {
            this.confirmImport();
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        .backgroundColor(Theme.card)
        .borderRadius(Theme.radius)
        .margin({ top: 12 })

        Text('所有数据仅保存在本机，不上传任何服务器。')
          .fontSize(11)
          .fontColor(Theme.sub)
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 18, bottom: 40 })
      }
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(Theme.bg)
  }
}
