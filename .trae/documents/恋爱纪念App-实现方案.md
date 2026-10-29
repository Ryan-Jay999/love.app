# 恋爱纪念 App 实现方案（LoveDemo）

## Context（背景与目标）

`c:\Users\REN\LoveDemo` 目前是一个**全新的 HarmonyOS 空模板工程**（bundleName `com.example.lovedemo`，单 `entry` 模块，仅 `pages/Index.ets` 的 Hello World）。需要在这个工程里从零实现一个**本地优先的双人恋爱记录 App**，覆盖用户提出的 5 大需求：

1. 恋爱天数 + 纪念日倒计时（公历 / **农历** 双支持，支持提前提醒）
2. 共同回忆时间轴（地点 / 做了什么 / 照片 / 一句话感受）
3. 心愿清单双板块（「我想和 TA 一起做」含旅游攻略子任务勾选、「我想送给 TA」）
4. 细节备忘录（忌口、过敏、口味、尺码、讨厌的东西）
5. 本地加密（自设应用密码锁）+ 一键导出 ZIP 备份 / 导入还原

已确认的产品决策（用户已选择）：
- 提醒方式：**系统通知提醒**（reminderAgent + 通知授权）
- 导出格式：**ZIP（data.json + 全部照片）**
- 应用锁：**自设应用密码**（PBKDF2 派生密钥 + AES-256-GCM 整库加密）
- 附加功能（勾选）：**数据统计**、**心情打卡**、**那年今日 + 每日情话**（不做"恋爱兑换券"）

技术基线（已核对本机 SDK 声明文件）：
- compileSdkVersion 26.0.0，**compatibleSdkVersion 6.1.1(24)** → 只用 `@since ≤ 24` 的 API，**禁止使用 `@since 26.0.0` 的新接口**。
- 后端 API 已逐条核对：`cryptoFramework`（PBKDF2/AES-GCM/Random）、`file.fs`、`file.picker`、`file.photoAccessHelper`、`zlib`、`reminderAgentManager`、`notificationManager`、`util.generateRandomUUID`、`buffer`。

---

## 目录与文件结构

全部新增文件位于 `entry/src/main/ets/` 下；仅修改 3 个既有文件（见文末）。

```
model/Types.ets                     数据模型（纯 interface，可 JSON 往返）
common/Logger.ets                   hilog 封装
common/Ids.ets                      UUID 生成
common/LunarUtil.ets                农历↔公历换算（自研打包表，1900–2100）
common/DateUtil.ets                 第 N 天、下一周年、倒计时、那年今日、格式化
common/CryptoUtil.ets               PBKDF2 + AES-256-GCM + 随机数 + Base64
common/Store.ets                    数据层：单文件读写、防抖持久化、AppStorage 单一真源
common/PhotoStore.ets               选图 → 沙箱拷贝 → images/<uuid>.jpg；删图、路径解析
common/Backup.ets                   ZIP 打包/解包 + sandbox↔picker URI 桥接
common/ReminderScheduler.ets        通知授权 + 重排未来提醒
common/Quotes.ets                   内置情话文案库 + 每日取词
pages/Index.ets                     @Entry：锁定态渲染 LockView / 解锁态 Navigation+Tabs
pages/tabs/HomeTab.ets              天数、最近纪念日、那年今日、每日情话、心情打卡
pages/tabs/TimelineTab.ets          回忆时间轴（按年分组）
pages/tabs/WishTab.ets              心愿双板块 + 子任务勾选
pages/tabs/MemoTab.ets              细节备忘录（分类分组）
pages/tabs/ProfileTab.ets           统计、密码锁、导出/导入、起始日期设置
view/common/LockView.ets            密码解锁 / 首次设置密码
view/common/PhotoGrid.ets           图片网格 + 大图预览
view/common/Widgets.ets             SectionCard / EmptyView / StatCard / Chip 等小组件
view/editors/MemoryEditor.ets       bindSheet 表单：回忆
view/editors/AnniversaryEditor.ets  bindSheet 表单：纪念日（公历/农历/提前天数）
view/editors/WishEditor.ets         bindSheet 表单：心愿 + 子任务
view/editors/MemoEditor.ets         bindSheet 表单：备忘条目
```

---

## 关键设计

### 1. 数据模型（`model/Types.ets`）
纯 `interface`（ArkTS 下 interface 不支持 `@Observed`，也不需要）：
- `AppData { schemaVersion, settings, anniversaries[], memories[], wishes[], memos[], moods[] }`
- `Settings { startDate, partnerName, meName, theme, reminderEnabled, avoidWeekday? }`
- `Anniversary { id, title, calendar: 'solar'|'lunar', month, day, isLeapMonth, lunarYear?, advanceDays, emoji, remind }`
- `Memory { id, date, place, activity, feeling, note, images: string[]（相对文件名）, mood?, createdAt }`
- `WishItem { id, board: 'together'|'gift', title, note, done, doneDate?, subtasks: SubTask[], target?: 'travel' }`
- `SubTask { id, text, done }`
- `MemoItem { id, category, value, note }`（category ∈ 忌口/过敏/口味/尺码/喜好/讨厌…）
- `MoodRecord { id, date, mood, note }`

### 2. 农历换算（`common/LunarUtil.ets`）
**不使用** `i18n.getCalendar(locale,'chinese')`：其 `get('year')` 在农历历法对象下语义存在歧义，闰月只能读不能写，且依赖设备 ICU 数据。
改为**自研 1900–2100 农历打包表**（经典 hex 表 + 闰月大小月判断），提供：
- `solarToLunar(y,m,d) → { ly, lm, ld, isLeap }`
- `lunarToSolar(ly, lm, ld, isLeap) → { y, m, d }`（该农历年无该闰月时降级为非闰月并提示）
- `ganzhi(ly)` / `zodiac(ly)`（甲乙丙丁 / 生肖，用于展示）
- `formatLunar(...) → "乙巳年 正月初五"`

**验证手段**：实现前先用 `node -e` 内联脚本跑同一份表的算法，断言已知日期（2024-02-10 正月初一、2025-01-29 正月初一、2023 闰二月、2026-02-17 春节、1900-01-31 正月初一）后再落 ArkTS。

### 3. 加密与存储（`common/CryptoUtil.ets` + `common/Store.ets`）
密钥派生：`cryptoFramework.createKdf('PBKDF2|SHA256')` + `PBKDF2Spec{ password, salt(16B), iterations: 100000, keySize: 32 }`，**必须用异步 `generateSecret`**（`generateSecretSync` 会阻塞主线程）。
加解密：`createSymKeyGenerator('AES256').convertKey(raw)` + `createCipher('AES256|GCM|NoPadding')`；`GcmParamsSpec` 的 `iv`(12B)/`aad`(空 Uint8Array)/`authTag`(16B) **三个字段都必填**；加密输出 = `ciphertext || 末16B tag`，解密时须把 tag 拆回 params。

存储格式（`filesDir/lovedata.bin`，无密码时退化为 `lovedata.json` 明文）：
```
LOVE1\n<iterations>\n<base64 salt>\n<base64 iv>\n<base64 ciphertext||tag>
```
- **密码是否正确由 GCM authTag 校验决定**，不需要额外 magic verifier，也不需要 preferences 存配置；`lockEnabled` 由"`lovedata.bin` 是否存在"推导。
- 密码只存在于内存（解锁后持有派生密钥），不做任何明文落盘。
- 关闭密码锁：解密后用明文 JSON 覆盖写回并删除 `.bin`；修改密码：旧密钥解密 → 新密钥重加密。
- 照片存 `filesDir/images/<uuid>.jpg`（应用沙箱，其他应用不可访问）；打开密码锁时**整库数据（含照片路径清单）加密**，照片本体保持沙箱私有。

### 4. 单一真源与状态刷新（ArkTS 状态管理约束）
ArkTS 下 `@State` 对 `Array<interface>` 的**嵌套属性赋值不会触发刷新**，且 `@Observed` 只能修饰 `class`。因此：
- `Store` 初始化时 `AppStorage.setOrCreate('appData', data)`。
- `Index.ets` 用 `@StorageLink('appData') appData: AppData`（读写）；各 Tab / 编辑器用 `@StorageProp('appData') appData: AppData`（单向只读，自动刷新）。
- **唯一写入口** `Store.commit((d) => { ... })`：`JSON.parse(JSON.stringify(appData)) as AppData` → 应用变更 → `AppStorage.set('appData', next)` → 触发全量刷新 → 防抖 500ms 落盘。杜绝对象展开（ArkTS 禁止 spread 无类型字面量）。
- `ForEach` 的 `keyGenerator` 一律用 `id`，避免列表编辑后组件复用错位。
- `Context` 只在 `EntryAbility.onCreate` 里 `Store.init(this.context)` 注入一次，组件内不调用 `getContext`。

### 5. 导出 / 导入（`common/Backup.ets`）
- 导出：先把当前数据写成 `cacheDir/backup/data.json` 并拷贝照片到同目录 → `zlib.compressFiles(inFiles, outZip, options)` 生成 `cacheDir/backup/love-backup-<日期>.zip`（outFile 目录必须已存在）。
- 落盘到用户位置：`new picker.DocumentViewPicker(context)` → `save(new DocumentSaveOptions())` 拿 URI（**save 用 `fileSuffixChoices`**）→ `fs.openSync(uri, READ_WRITE)` 拿 fd → `fs.copyFile(zipPath, fd)`（zlib 不能直接写 `file://docs/...`）。
- 导入：`DocumentViewPicker.select()`（**select 用 `fileSuffixFilters`**）→ 解压到 `cacheDir/restore/` → 校验 `schemaVersion` + 缺字段补默认 → 覆盖 `filesDir` → 重新 `commit` 并刷新。

### 6. 提醒（`common/ReminderScheduler.ets`）
- `module.json5` 增加 `ohos.permission.PUBLISH_AGENT_REMINDER`；首次开启提醒时调 `notificationManager.requestEnableNotification(context)`（未授权时 reminderAgent 会报 1700001）。
- `reminderAgentManager.ReminderRequestCalendar` **没有"每年重复"语义**，因此采取：**冷启动 + 数据变更后 → `cancelAllReminders()` → 重排未来 30 天内需要提醒的纪念日（按 `advanceDays` 提前）**，并限制总条数（系统上限会报 1700002）。
- 提醒仅在设置页可开关，默认关闭，避免打扰。

### 7. UI 结构
- `pages/Index.ets`：`@Entry`，根据 `Store.isLocked()` 渲染 `LockView` 或主界面；主界面为底部 `Tabs`（首页 / 时光 / 心愿 / 备忘 / 我的），5 个 Tab 内容拆到 `pages/tabs/*`。
- 表单编辑统一用 `bindSheet`（多输入 + 键盘避让 + 滚动），`isShow` 为 `@State`，`SheetOptions` 显式给 `detents`；密码输入用 `CustomDialog`。
- 主题色 / 圆角 / 间距集中在 `view/common/Widgets.ets` 的常量中，不新增资源文件依赖。
- 日期选择用系统 `DatePickerDialog`；图片选择用 `photoAccessHelper.PhotoViewPicker().select({MIMEType: IMAGE_TYPE, maxSelectNumber: 9})`，选完**立即用 fd 拷贝进沙箱**（photoUri 的授权不保证长期有效，绝不持久化 URI）。

---

## 实施顺序（每步可独立验证）

1. 骨架与数据层：`model/Types.ets`、`Logger`、`Ids`、`Store`、`AppStorage` 接入、`EntryAbility` 注入 Context。
2. 日期能力：先用 node 脚本验证农历算法，再落 `LunarUtil` + `DateUtil`。
3. 安全层：`CryptoUtil` + `Store` 加密读写 + `LockView`（设置密码 / 解锁 / 改密码 / 关闭密码锁）。
4. 首页：起始日期设置 + 第 N 天 + 纪念日增删改 + 倒计时（公历/农历）。
5. 时光轴：`PhotoStore` + `MemoryEditor` + 时间轴列表 + 大图预览。
6. 心愿清单：双板块 + 子任务（旅游攻略）勾选 + 完成日期。
7. 细节备忘录：分类分组增删改。
8. 附加：心情打卡、那年今日、每日情话、数据统计。
9. 备份：ZIP 导出 / 导入还原。
10. 提醒：通知授权 + 重排逻辑 + 设置开关。
11. 编译验证与修错（见下）。

---

## Verification（验证方式）

1. **农历算法**：用本机 `node -e` 跑等价表实现，断言已知农历日期（含闰月年），全部通过后才落 ArkTS。
2. **编译验证（主要手段）**：本机装有 DevEco Studio 内置 hvigor（`C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js`，hvigor 6.26.8，SDK 在 `...\DevEco Studio\sdk\default`），执行
   `node "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" --mode module -p module=entry@default -p product=default assembleHap --no-daemon`
   目标是 **ArkTS 编译零错误**（签名步骤若因未配置签名而失败可忽略，编译期错误会先暴露）。反复修到通过。
3. **真机/模拟器验证**：本机已装 HarmonyOS-7.0.0 phone x86 模拟器镜像，但需在 DevEco Studio 中运行；交付后由你在 IDE 里跑一遍，重点验证：设置密码后重启需解锁、农历纪念日倒计时正确、导出 ZIP 可在文件管理器中打开、导入可还原。
4. **加密自查**：错误密码解锁必须失败（GCM tag 校验），正确密码可正常解密；导出 ZIP 中不得出现明文密码。

## 需要修改的既有文件
- `entry/src/main/module.json5`：新增 `requestPermissions` → `ohos.permission.PUBLISH_AGENT_REMINDER`。
- `entry/src/main/ets/entryability/EntryAbility.ets`：`onCreate` 中 `Store.init(this.context)`，`onBackground/onDestroy` 中 `Store.flushNow()`。
- `entry/src/main/ets/pages/Index.ets`：整体重写为"锁定态 / 主页 Tabs"入口。
- `entry/src/main/resources/base/element/string.json`：`EntryAbility_label` 改为中文应用名（如「我们的恋爱」）。
