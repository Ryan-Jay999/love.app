import { AppData, DATA_KEY, emptyAppData } from '../model/Types';
import { Store } from '../common/Store';
import { LockView } from '../view/common/LockView';
import { Theme } from '../view/common/Widgets';
import { HomeTab } from './tabs/HomeTab';
import { TimelineTab } from './tabs/TimelineTab';
import { WishTab } from './tabs/WishTab';
import { MemoTab } from './tabs/MemoTab';
import { ProfileTab } from './tabs/ProfileTab';

@Entry
@Component
struct Index {
  @StorageLink('loveAppLocked') locked: boolean = false;
  @StorageProp(DATA_KEY) data: AppData = emptyAppData();
  @State currentIndex: number = 0;

  @Builder
  tabBar(index: number, icon: string, label: string) {
    Column() {
      Text(icon)
        .fontSize(20)
        .opacity(this.currentIndex === index ? 1 : 0.45)
      Text(label)
        .fontSize(10)
        .fontColor(this.currentIndex === index ? Theme.primary : Theme.sub)
        .margin({ top: 2 })
    }
    .width('100%')
    .height(52)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Stack() {
      if (this.locked) {
        LockView()
      } else {
        Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
          TabContent() {
            HomeTab()
          }
          .tabBar(this.tabBar(0, '🏠', '首页'))

          TabContent() {
            TimelineTab()
          }
          .tabBar(this.tabBar(1, '📷', '时光'))

          TabContent() {
            WishTab()
          }
          .tabBar(this.tabBar(2, '🌠', '心愿'))

          TabContent() {
            MemoTab()
          }
          .tabBar(this.tabBar(3, '📌', '备忘'))

          TabContent() {
            ProfileTab()
          }
          .tabBar(this.tabBar(4, '💗', '我的'))
        }
        .width('100%')
        .height('100%')
        .barHeight(56)
        .barBackgroundColor('#FFFFFF')
        .scrollable(false)
        .onChange((index: number) => {
          this.currentIndex = index;
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bg)
  }

  aboutToAppear(): void {
    Store.syncLockState();
    this.locked = Store.isLocked();
  }
}
