import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { Store } from '../common/Store';

const DOMAIN = 0x0001;
const RELOCK_AFTER_MS: number = 300000;

export default class EntryAbility extends UIAbility {
  private backgroundAt: number = 0;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'LoveDemo', '%{public}s', 'Ability onCreate');
    Store.init(this.context);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'LoveDemo', '%{public}s', 'Ability onDestroy');
    Store.flushNow();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'LoveDemo', '%{public}s', 'Ability onWindowStageCreate');

    // 应用整体为固定浅色设计，强制浅色模式，避免深色系统下输入框等组件文字不可见
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    } catch (err) {
      hilog.error(DOMAIN, 'LoveDemo', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'LoveDemo', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'LoveDemo', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'LoveDemo', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'LoveDemo', '%{public}s', 'Ability onForeground');
    if (Store.hasLock() && this.backgroundAt > 0 && Date.now() - this.backgroundAt > RELOCK_AFTER_MS) {
      Store.lockNow();
    }
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'LoveDemo', '%{public}s', 'Ability onBackground');
    this.backgroundAt = Date.now();
    Store.flushNow();
  }
}
