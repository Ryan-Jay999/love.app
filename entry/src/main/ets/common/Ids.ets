import { util } from '@kit.ArkTS';

export function newId(): string {
  return util.generateRandomUUID(false).replaceAll('-', '');
}
