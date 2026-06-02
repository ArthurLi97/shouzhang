# HarmonyOS API 23 (HarmonyOS 6.1.0) 开发最佳实践

## 概述

HarmonyOS API 23 对应 **HarmonyOS 6.1.0 Release**（2026年4月20日发布），是当前设备量占比最高的版本（截至2026年5月超84%）。

本 Skill 的核心主张：**UI 开发全面采用 HDS（HarmonyOS Design System）组件 + 沉浸光感材质**，替代原生 ArkUI 基础组件，打造符合系统设计语言、具有通透质感与光影层次的高级界面。

> **版本对应关系（重要）**
> - API 23 → HarmonyOS 6.1.0（Release）
> - API 24 → HarmonyOS 6.1.1（Release，2026/05/26转正）

---

## 1. 项目结构规范

### 标准目录结构

```
entry/src/main/
├── ets/
│   ├── entryability/           # EntryAbility（入口 Ability）
│   ├── entrybackupability/     # 备份恢复 Ability
│   ├── pages/                  # 页面（@Entry @Component / @Entry @ComponentV2）
│   ├── components/             # 可复用组件（HDS + 原生混合）
│   ├── hds/                    # HDS 封装层（可选）
│   │   ├── HdsCustomNavigation.ets
│   │   └── HdsCustomTabs.ets
│   ├── services/               # 业务服务层
│   ├── model/                  # 数据模型/实体类
│   ├── utils/                  # 工具类
│   └── viewmodel/              # MVVM 的 ViewModel（可选）
├── resources/
│   ├── base/
│   │   ├── element/            # 颜色、字符串、布尔值、整数等常量
│   │   ├── media/              # 图片、音视频资源
│   │   ├── profile/            # 页面路由、配置文件
│   │   └── animation/          # 动画资源
│   ├── rawfile/                # 原始文件（通过 $rawfile 访问）
│   └── [语言环境]/             # 多语言资源目录，如 zh_CN、en_US
├── module.json5                # 模块配置文件
└── oh-package.json5            # 依赖配置（需引入 @kit.UIDesignKit）
```

### 依赖配置

```json5
// oh-package.json5
{
  "modelVersion": "6.1.0",
  "dependencies": {
    "@kit.UIDesignKit": "^1.0.0"
  }
}
```

### 文件命名规范

| 类型 | 命名规范 | 示例 |
|------|---------|------|
| Ability | PascalCase + Ability | `EntryAbility.ets` |
| 页面 | PascalCase + Page | `HomePage.ets` |
| HDS 封装组件 | PascalCase | `ImmersiveNavigation.ets` |
| 服务 | PascalCase + Service | `ChatService.ets` |
| 模型 | PascalCase | `MessageItem.ets` |

---

## 2. HDS 设计体系与沉浸光感

### 2.1 什么是 HDS

**HDS（HarmonyOS Design System）** 是华为官方 UI 设计体系，通过 `@kit.UIDesignKit` 提供标准化、高可用的组件集合，确保应用在 HarmonyOS 全场景设备上达成一致的视觉体验。

API 23 起，HDS 引入 **沉浸光感（Immersive Light Effects）** —— 系统级材质效果，让 UI 组件与底层内容产生"毛玻璃 + 光影渗透"的高级视觉体验。

### 2.2 沉浸光感核心特性

| 特性 | 说明 |
|------|------|
| 物理光照模型 | 组件内部模拟真实光晕与反射效果 |
| 动态光影 | 交互时产生细腻的光晕和反射反馈 |
| 系统联动 | 自动跟随系统主题、深色模式变化 |
| 性能自适应 | 系统负载高时自动下采样模糊算法，保障 60FPS |

### 2.3 支持沉浸光感的 HDS 组件

| 组件 | 用途 | 沉浸光感配置位置 |
|------|------|-----------------|
| `HdsNavigation` | 标题栏导航 | `titleBar.style.systemMaterialEffect` |
| `HdsTabs` | 底部/顶部页签 | `barFloatingStyle.systemMaterialEffect` |
| `HdsSideMenu` | 分级侧边菜单 | 部分容器支持 |
| `HdsVisualComponent` | 高性能视觉承载 | `HdsSceneController` 注入光效参数 |

> **重要**：原生 ArkUI 组件（Search、TextInput、Button 等）**不支持**内置沉浸光感属性。如需光感效果，应优先使用 HDS 对应组件（如 HdsSearch），或通过背景模糊手动模拟。

---

## 3. HDS 沉浸光感实战规范

### 3.1 基础导入

```typescript
// ✅ 核心导入
import {
  HdsNavigation,
  HdsNavigationTitleMode,
  HdsTabs,
  HdsTabsController,
  hdsMaterial,
  SystemMaterialParams
} from '@kit.UIDesignKit'

import { curves, window } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
```

### 3.2 材质能力检测与降级（必须）

```typescript
// ✅ 最佳实践：先检测系统材质能力，再决定渲染策略
@Entry
@Component
struct ImmersivePage {
  @State activeTab: number = 0
  @State useFloatingNav: boolean = false
  @State immersiveMaterialLevel: hdsMaterial.MaterialLevel = hdsMaterial.MaterialLevel.ADAPTIVE

  private tabsController: HdsTabsController = new HdsTabsController()

  aboutToAppear(): void {
    this.detectApiCapabilities()
    this.resolveMaterialLevel()
  }

  // 检测 API 版本能力
  private detectApiCapabilities(): void {
    try {
      this.useFloatingNav = deviceInfo.sdkApiVersion >= 23
    } catch (error) {
      this.useFloatingNav = false
    }
  }

  // 检测设备材质支持级别
  private resolveMaterialLevel(): void {
    try {
      const materialTypes: Array<hdsMaterial.MaterialType> = hdsMaterial.getSystemMaterialTypes()
      if (materialTypes.indexOf(hdsMaterial.MaterialType.IMMERSIVE) < 0) {
        // 设备不支持 IMMERSIVE，降级到 SMOOTH
        this.immersiveMaterialLevel = hdsMaterial.MaterialLevel.SMOOTH
      }
    } catch (error) {
      this.immersiveMaterialLevel = hdsMaterial.MaterialLevel.SMOOTH
    }
  }

  // 构建自适应材质效果参数
  private buildMaterialEffect(): SystemMaterialParams {
    return {
      materialType: hdsMaterial.MaterialType.ADAPTIVE,    // 交由系统自适应
      materialLevel: this.immersiveMaterialLevel           // 根据设备能力动态决定
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (this.useFloatingNav) {
        this.buildHdsFloatingTabs()
      } else {
        this.buildLegacyTabs()    // 低版本降级方案
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildHdsFloatingTabs(): void {
    HdsNavigation() {
      HdsTabs({ controller: this.tabsController, index: this.activeTab }) {
        TabContent() { this.buildHomeContent() }
          .tabBar(this.customTabBar(0, $r('sys.symbol.house_fill'), '首页'))

        TabContent() { this.buildDiscoverContent() }
          .tabBar(this.customTabBar(1, $r('sys.symbol.book_pages_fill'), '发现'))

        TabContent() { this.buildProfileContent() }
          .tabBar(this.customTabBar(2, $r('sys.symbol.person_fill'), '我的'))
      }
      .vertical(false)
      .barPosition(BarPosition.End)
      .barMode(BarMode.Fixed)
      .barHeight(60)
      .barOverlap(true)
      // ✅ API 23 核心：悬浮样式 + 沉浸光感
      .barFloatingStyle({
        barSideMargin: 18,           // 左右留白
        barBottomMargin: 28,         // 底部留白（配合安全区）
        thermoCtrl: true,            // 温度控制（光效自适应）
        gradientMask: {
          maskColor: '#66F1F3F5',
          maskHeight: 92
        },
        // ✅ 沉浸光感核心配置
        systemMaterialEffect: this.buildMaterialEffect()
      })
      .onChange((index: number) => { this.activeTab = index })
    }
    .mode(NavigationMode.Stack)
    .titleBar({
      content: { title: { mainTitle: '应用标题' } },
      style: {
        thermoCtrl: true,
        // ✅ 标题栏同样启用沉浸光感
        systemMaterialEffect: this.buildMaterialEffect()
      },
      avoidLayoutSafeArea: true,
      enableComponentSafeArea: true
    })
    .titleMode(HdsNavigationTitleMode.MINI)
    .hideBackButton(true)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.BOTTOM])
    .width('100%')
    .height('100%')
  }

  @Builder
  private customTabBar(tabIndex: number, icon: Resource, text: string): void {
    Column() {
      SymbolGlyph(icon)
        .fontSize(24)
        .fontColor([this.activeTab === tabIndex ? '#F06795' : '#6F5963'])

      Text(text)
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.activeTab === tabIndex ? '#F06795' : '#6F5963')
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .scale({
      x: this.activeTab === tabIndex ? 1.06 : 0.96,
      y: this.activeTab === tabIndex ? 1.06 : 0.96
    })
    .animation({ duration: 320, curve: curves.springMotion() })
  }

  @Builder
  private buildLegacyTabs(): void {
    // API 22 及以下降级：传统 Tabs + 自定义玻璃导航栏
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() { this.buildHomeContent() }
        .tabBar('首页')
      TabContent() { this.buildDiscoverContent() }
        .tabBar('发现')
      TabContent() { this.buildProfileContent() }
        .tabBar('我的')
    }
  }

  @Builder
  private buildHomeContent(): void { /* ... */ }
  @Builder
  private buildDiscoverContent(): void { /* ... */ }
  @Builder
  private buildProfileContent(): void { /* ... */ }
}
```

### 3.3 MaterialType 与 MaterialLevel 枚举详解

```typescript
// MaterialType（材质类型）
hdsMaterial.MaterialType.ADAPTIVE     // 系统自适应（推荐）
hdsMaterial.MaterialType.IMMERSIVE    // 沉浸式材质，需要设备硬件支持
hdsMaterial.MaterialType.NONE         // 无材质效果

// MaterialLevel（材质等级）
hdsMaterial.MaterialLevel.ADAPTIVE    // 系统自动选择（推荐）
hdsMaterial.MaterialLevel.EXQUISITE   // 精致效果（高画质）
hdsMaterial.MaterialLevel.GENTLE      // 柔和效果
hdsMaterial.MaterialLevel.SMOOTH      // 平滑效果（性能优先，降级时使用）
```

### 3.4 悬浮导航安全区适配

```typescript
@Component
struct SafeAreaAwarePage {
  @State bottomAvoidHeight: number = 0

  async aboutToAppear(): Promise<void> {
    try {
      const mainWindow = await window.getLastWindow(getContext())
      const avoidArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)
      this.bottomAvoidHeight = avoidArea.bottomRect.height
    } catch (error) {
      hilog.error(0x0000, 'SafeArea', 'Failed to get avoid area')
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll() {
        Column() {
          // 页面内容
        }
        // ✅ 底部预留空间：导航指示器高度 + 悬浮页签高度 + 边距
        .padding({
          bottom: this.bottomAvoidHeight + 116   // 116 = 60(页签) + 28(底部边距) + 28(内容间隙)
        })
      }

      // 悬浮页签层（覆盖在内容之上）
      this.buildFloatingTabBar()
    }
  }
}
```

### 3.5 HDS 卡片与容器光感模拟

对于不支持内置 `systemMaterialEffect` 的自定义区域，可使用背景模糊模拟类光感效果：

```typescript
@Component
struct GlassCard {
  @Prop title: string = ''
  @Prop content: string = ''

  build() {
    Column({ space: 12 }) {
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1714')

      Text(this.content)
        .fontSize(14)
        .fontColor('#666666')
        .lineHeight(22)
    }
    .width('100%')
    .padding(20)
    .borderRadius(24)
    // 类光感效果：背景模糊 + 半透明 + 边缘高光
    .backgroundBlurStyle(BlurStyle.REGULAR)
    .backgroundColor('rgba(255,255,255,0.72)')
    .backdropFilter($r('sys.blur.20'))
    .shadow({
      radius: 24,
      color: 'rgba(0,0,0,0.08)',
      offsetY: 8
    })
    // 顶部边缘微光
    .border({
      width: { top: 1 },
      color: 'rgba(255,255,255,0.4)'
    })
  }
}
```

---

## 4. ArkTS 严格模式规范

API 23 采用 **Strictly Constrained ArkTS**，以下写法被禁止：

### ❌ 禁止的语法

```typescript
// 1. 禁止 any 类型
let data: any = fetchData()      // ❌ 错误
let data: object | null = fetchData()  // ✅ 正确

// 2. 禁止 undefined 作为独立类型参数
let arr: Array<undefined> = []   // ❌ 错误

// 3. 禁止类的静态块
class Foo {
  static {                       // ❌ 错误
    // ...
  }
}

// 4. 禁止 delete 操作符
delete obj.key                   // ❌ 错误
obj.key = undefined              // ✅ 正确

// 5. 禁止 with 语句
with (obj) { ... }               // ❌ 错误

// 6. 禁止在顶层使用 this
console.log(this)                // ❌ 错误

// 7. 禁止在 .ets 文件中使用 eval()
eval("console.log('hello')")     // ❌ 错误
```

### ✅ 推荐语法

```typescript
// 1. 显式声明所有类型
function calculate(a: number, b: number): number {
  return a + b
}

// 2. 使用接口定义数据结构
interface UserInfo {
  id: string
  name: string
  age?: number
}

// 3. 使用联合类型替代 any
type Result = Success | Failure | Loading

// 4. 使用常量枚举提升性能
const enum ColorMode {
  LIGHT = 0,
  DARK = 1,
  AUTO = 2
}

// 5. API 23：模块懒加载优化冷启动
async function loadHeavyModule(): Promise<void> {
  const heavy = await import('../modules/heavy')
  heavy.doSomething()
}
```

---

## 5. HDS + ArkUI 组件开发规范

### 装饰器使用规范（V1 + V2）

API 23 中 **V1 和 V2 装饰器均可用**，HDS 组件内部兼容两种模式。新项目推荐在自定义组件中评估 V2：

| 装饰器 | 用途 | 适用场景 |
|--------|------|---------|
| `@State` / `@Local` | 组件内部状态 | 仅在本组件使用 |
| `@Prop` / `@Param` | 父→子单向同步 | 子组件不修改，仅显示 |
| `@Link` / `@Param+@Event` | 父↔子双向同步 | 子组件需要修改 |
| `@Provide/@Consume` | 跨层级双向同步 | 主题、语言等全局状态 |
| `@Observed/@ObjectLink` | 嵌套对象观察（V1） | 列表项中的复杂对象 |
| `@ObservedV2+@Trace` | 深层嵌套观察（V2） | 多层嵌套属性变化检测 |
| `@Computed`（V2） | 计算属性 | 派生状态自动计算 |
| `@Monitor`（V2） | 状态监听 | 异步监听变量修改 |

### V2 数据模型规范（配合 HDS 使用）

```typescript
import { ObservedV2, Trace } from '@ohos/arkui'

@ObservedV2
class UserProfile {
  @Trace name: string = ''
  @Trace avatar: string = ''
  @Trace contact = {
    phone: '',
    address: { city: '', detail: '' }
  }
}

// 在 HDS 页面中使用 V2 状态
@Entry
@ComponentV2
struct ProfilePage {
  @Local user: UserProfile = new UserProfile()

  build() {
    HdsNavigation() {
      Scroll() {
        Column() {
          // 修改深层属性也能触发更新（V1 做不到）
          Text(this.user.contact.address.city)
          Button('修改城市')
            .onClick(() => { this.user.contact.address.city = '深圳' })
        }
      }
    }
    .titleBar({ content: { title: { mainTitle: '个人资料' } } })
  }
}
```

---

## 6. Stage 模型最佳实践

### Ability 生命周期（含 API 23 Attach/Detach）

```typescript
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { window } from '@kit.ArkUI'

const DOMAIN = 0x0000
const TAG = 'EntryAbility'

export default class EntryAbility extends UIAbility {
  private pushService: PushKitService = new PushKitService()
  private chatService: ChatService = new ChatService()

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // ✅ API 23：获取启动时间戳用于性能分析
    hilog.info(DOMAIN, TAG, 'launchTime: %{public}d', launchParam.launchUTCTime)
    this.initServices()
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/HomePage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load content: %{public}s', JSON.stringify(err))
        return
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading content')
    })
  }

  onDestroy(): void {
    this.chatService.destroy()
    this.pushService.destroy()
  }
}
```

### 自定义组件生命周期（API 23 Attach/Detach）

```typescript
@Component
struct LifecycleAwareComponent {
  @State isAttached: boolean = false

  aboutToAppear(): void { }

  // ✅ API 23 新增：组件挂载到渲染树
  onAttach(): void {
    this.isAttached = true
  }

  // ✅ API 23 新增：组件从渲染树移除
  onDetach(): void {
    this.isAttached = false
  }

  aboutToDisappear(): void { }

  build() {
    Column() {
      Text(this.isAttached ? '已挂载' : '未挂载')
    }
  }
}
```

---

## 7. Kit 化 API 使用规范

### 常用 Kit 速查

| 功能领域 | Kit 名称 | 典型导入 |
|---------|---------|---------|
| **HDS 设计系统** | **`@kit.UIDesignKit`** | **`HdsTabs`, `HdsNavigation`, `hdsMaterial`** |
| Ability 管理 | `@kit.AbilityKit` | `UIAbility`, `Want`, `AbilityConstant` |
| UI 开发 | `@kit.ArkUI` | `window`, `Animator`, `curves` |
| 网络请求 | `@kit.NetworkKit` | `http`, `socket` |
| 数据存储 | `@kit.ArkData` | `relationalStore`, `dataPreferences` |
| 文件管理 | `@kit.CoreFileKit` | `fileIo`, `picker` |
| 相机 | `@kit.CameraKit` | `camera` |
| 音频 | `@kit.AudioKit` | 变声、系统音效（API 23 新增） |
| 多媒体 | `@kit.MediaKit` | 批量缩略图、HDR 转 SDR（API 23 新增） |
| 性能分析 | `@kit.PerformanceAnalysisKit` | `hilog`, `hiTraceMeter` |
| 安全 | `@kit.SecurityKit` | `cryptoFramework`, `userAuth` |

### 扩展 Kit 能力速查（API 23 新增/常用）

| 功能领域 | Kit 名称 | 典型导入 | 说明 |
|---------|---------|---------|------|
| **系统服务** | `@kit.NotificationKit` | `notificationManager`, `NotificationRequest` | 发送本地/推送通知 |
| **系统服务** | `@kit.VibratorKit` | `vibrator` | 设备震动反馈 |
| **系统服务** | `@kit.BackgroundTaskKit` | `backgroundTaskManager`, `longTermTask` | 后台长时任务（播放、定位等） |
| **系统服务** | `@kit.PowerManagerKit` | `power` | 电源管理、屏幕常亮 |
| **系统服务** | `@kit.PasteboardKit` | `pasteboard` | 系统剪贴板读写 |
| **设备能力** | `@kit.SensorKit` | `sensor` | 加速度计、陀螺仪、光线、距离等 |
| **设备能力** | `@kit.BluetoothKit` | `bluetooth` | BLE 蓝牙扫描、连接、数据传输 |
| **设备能力** | `@kit.WifiKit` | `wifiManager` | WiFi 扫描、连接状态 |
| **设备能力** | `@kit.LocationKit` | `geoLocationManager` | 精准定位、围栏、地理编码 |
| **设备能力** | `@kit.NFCKit` | `tag` | NFC 标签读写 |
| **媒体扩展** | `@kit.MediaLibraryKit` | `photoAccessHelper` | 相册访问、媒体资源管理 |
| **账号支付** | `@kit.AccountKit` | `AccountKit` | 华为账号登录、获取 OpenID |
| **账号支付** | `@kit.IAPKit` | `iap` | 应用内购买（消耗型/非消耗型/订阅） |
| **AI 能力** | `@kit.AIEngineKit` | `textRecognition`, `imageClassification` | 文本识别、图像分类、语音识别 |
| **分布式** | `@kit.DistributedServiceKit` | `distributedObject` | 跨设备数据同步 |
| **扫码** | `@kit.ScanKit` | `scanCore`, `scanBarcode` | 扫码、生成条码/二维码 |
| **日历联系人** | `@kit.CalendarKit` | `calendarManager` | 日历事件增删改查 |
| **日历联系人** | `@kit.ContactKit` | `contact` | 联系人读取、写入 |

### 导入示例

```typescript
// ✅ 按 Kit 导入（推荐）
import {
  HdsTabs,
  HdsNavigation,
  HdsNavigationTitleMode,
  hdsMaterial
} from '@kit.UIDesignKit'
import { UIAbility, Want } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { window, curves } from '@kit.ArkUI'
import { http } from '@kit.NetworkKit'
import { notificationManager } from '@kit.NotificationKit'
import { vibrator } from '@kit.VibratorKit'
import { backgroundTaskManager } from '@kit.BackgroundTaskKit'
```

---

## 7.1 核心 Kit 实战代码片段

### 通知（@kit.NotificationKit）

```typescript
import { notificationManager } from '@kit.NotificationKit'

async function publishFocusNotification(title: string, content: string): Promise<void> {
  const notificationRequest: notificationManager.NotificationRequest = {
    id: 1001,
    content: {
      notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
      normal: {
        title: title,
        text: content,
        additionalText: 'Focus Tomato'
      }
    }
  }
  try {
    await notificationManager.publish(notificationRequest)
  } catch (err) {
    hilog.error(0x0000, 'Notification', 'Failed: %{public}s', JSON.stringify(err))
  }
}
```

### 震动（@kit.VibratorKit）

```typescript
import { vibrator } from '@kit.VibratorKit'

function vibrateShort(): void {
  try {
    // 预设效果：轻触反馈
    vibrator.startVibration({
      type: 'preset',
      effectId: 'haptic.feedback.light'
    }, {
      usage: 'alarm'   // usage: alarm / ring / notification / touch
    })
  } catch (err) {
    hilog.error(0x0000, 'Vibrator', 'Vibrate failed: %{public}s', JSON.stringify(err))
  }
}

function vibrateCustom(duration: number = 300): void {
  try {
    vibrator.startVibration({
      type: 'time',
      duration: duration
    }, {
      usage: 'alarm'
    })
  } catch (err) {
    hilog.error(0x0000, 'Vibrator', 'Vibrate failed: %{public}s', JSON.stringify(err))
  }
}
```

### 后台长时任务（@kit.BackgroundTaskKit）

```typescript
import { backgroundTaskManager } from '@kit.BackgroundTaskKit'
import { wantAgent } from '@kit.AbilityKit'

async function startLongTermTask(): Promise<void> {
  try {
    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: 'com.example.focustomato',
          abilityName: 'EntryAbility'
        }
      ],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0
    }
    const agent = await wantAgent.getWantAgent(wantAgentInfo)

    await backgroundTaskManager.startBackgroundRunning(
      getContext(),
      backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK,  // 或 DATA_TRANSFER / LOCATION
      agent
    )
    hilog.info(0x0000, 'BGTask', 'Long term task started')
  } catch (err) {
    hilog.error(0x0000, 'BGTask', 'Failed: %{public}s', JSON.stringify(err))
  }
}

async function stopLongTermTask(): Promise<void> {
  try {
    await backgroundTaskManager.stopBackgroundRunning(getContext())
  } catch (err) {
    hilog.error(0x0000, 'BGTask', 'Failed: %{public}s', JSON.stringify(err))
  }
}
```

### 剪贴板（@kit.PasteboardKit）

```typescript
import { pasteboard } from '@kit.PasteboardKit'

function copyToClipboard(text: string): void {
  const systemPasteboard = pasteboard.getSystemPasteboard()
  const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text)
  systemPasteboard.setData(pasteData).then(() => {
    hilog.info(0x0000, 'Clipboard', 'Copy success')
  }).catch((err: Error) => {
    hilog.error(0x0000, 'Clipboard', 'Copy failed: %{public}s', JSON.stringify(err))
  })
}

async function readFromClipboard(): Promise<string> {
  const systemPasteboard = pasteboard.getSystemPasteboard()
  const pasteData = await systemPasteboard.getData()
  if (pasteData) {
    return pasteData.getPrimaryText() || ''
  }
  return ''
}
```

### 传感器（@kit.SensorKit）

```typescript
import { sensor } from '@kit.SensorKit'

// 订阅加速度计
function subscribeAccelerometer(callback: (x: number, y: number, z: number) => void): void {
  sensor.on(sensor.SensorId.ACCELEROMETER, (data) => {
    callback(data.x, data.y, data.z)
  }, { interval: sensor.SensorInterval.NORMAL })
}

function unsubscribeAccelerometer(): void {
  sensor.off(sensor.SensorId.ACCELEROMETER)
}

// 单次获取光线强度
async function getLightIntensity(): Promise<number> {
  const data = await sensor.getSingleSensorData(sensor.SensorId.AMBIENT_LIGHT)
  return data.intensity   // 单位：勒克斯(lux)
}
```

### 定位（@kit.LocationKit）

```typescript
import { geoLocationManager } from '@kit.LocationKit'

async function getCurrentLocation(): Promise<{ latitude: number; longitude: number }> {
  try {
    const location = await geoLocationManager.getCurrentLocation()
    return {
      latitude: location.latitude,
      longitude: location.longitude
    }
  } catch (err) {
    hilog.error(0x0000, 'Location', 'Failed: %{public}s', JSON.stringify(err))
    throw err
  }
}

// 持续定位
function subscribeLocationChange(callback: (lat: number, lng: number) => void): void {
  const requestInfo: geoLocationManager.LocationRequest = {
    priority: geoLocationManager.LocationRequestPriority.FIRST_FIX,
    scenario: geoLocationManager.LocationRequestScenario.UNSET,
    timeInterval: 5,
    distanceInterval: 0
  }
  geoLocationManager.on('locationChange', requestInfo, (location) => {
    callback(location.latitude, location.longitude)
  })
}
```

### 相册访问（@kit.MediaLibraryKit）

```typescript
import { photoAccessHelper } from '@kit.MediaLibraryKit'

async function fetchRecentPhotos(limit: number = 20): Promise<string[]> {
  try {
    const helper = photoAccessHelper.getPhotoAccessHelper(getContext())
    const fetchOptions: photoAccessHelper.FetchOptions = {
      fetchColumns: [photoAccessHelper.PhotoKeys.URI],
      predicates: new photoAccessHelper.DataSharePredicates()
    }
    const fetchResult = await helper.getAssets(fetchOptions)
    const assets = await fetchResult.getAllObjects()
    return assets.slice(0, limit).map(asset => asset.uri)
  } catch (err) {
    hilog.error(0x0000, 'MediaLib', 'Failed: %{public}s', JSON.stringify(err))
    return []
  }
}
```

### 扫码（@kit.ScanKit）

```typescript
import { scanCore, scanBarcode } from '@kit.ScanKit'

async function startScan(): Promise<string> {
  try {
    const result = await scanBarcode.startScanForResult(getContext(), {
      scanTypes: [scanCore.ScanType.ALL],
      autoZoom: true,
      enableMultiMode: false
    })
    return result.originalValue || ''
  } catch (err) {
    hilog.error(0x0000, 'ScanKit', 'Scan failed: %{public}s', JSON.stringify(err))
    return ''
  }
}
```

### 华为账号登录（@kit.AccountKit）

```typescript
import { AccountKit } from '@kit.AccountKit'

async function signInWithHuaweiId(): Promise<{ openId: string; displayName: string } | null> {
  try {
    const signInData = await AccountKit.signIn()
    return {
      openId: signInData.openId,
      displayName: signInData.displayName
    }
  } catch (err) {
    hilog.error(0x0000, 'AccountKit', 'SignIn failed: %{public}s', JSON.stringify(err))
    return null
  }
}
```

### 日历（@kit.CalendarKit）

```typescript
import { calendarManager } from '@kit.CalendarKit'

async function addCalendarEvent(title: string, startTime: number, endTime: number): Promise<void> {
  try {
    const event: calendarManager.Event = {
      type: calendarManager.EventType.NORMAL,
      title: title,
      startTime: startTime,
      endTime: endTime,
      reminderTime: [5]   // 提前5分钟提醒
    }
    await calendarManager.addEvent(event)
  } catch (err) {
    hilog.error(0x0000, 'Calendar', 'Add event failed: %{public}s', JSON.stringify(err))
  }
}
```

### 蓝牙 BLE（@kit.BluetoothKit）

```typescript
import { bluetooth } from '@kit.BluetoothKit'

// 扫描 BLE 设备
function startBleScan(onDeviceFound: (name: string, deviceId: string) => void): void {
  bluetooth.startBLEScan([], {
    interval: 0,
    dutyMode: bluetooth.ScanDutyMode.SCAN_MODE_LOW_POWER
  })

  bluetooth.on('BLEDeviceFind', (data) => {
    data.forEach(device => {
      onDeviceFound(device.deviceName || 'Unknown', device.deviceId)
    })
  })
}

function stopBleScan(): void {
  bluetooth.stopBLEScan()
  bluetooth.off('BLEDeviceFind')
}
```

---

## 8. 网络与数据规范

### HTTP 请求（API 23 Network Kit 增强）

```typescript
import { http } from '@kit.NetworkKit'

class HttpService {
  private httpRequest: http.HttpRequest | null = null

  async request<T>(url: string, method: http.RequestMethod, data?: object): Promise<T> {
    this.httpRequest = http.createHttp()

    try {
      const response = await this.httpRequest.request(url, {
        method,
        header: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        extraData: data ? JSON.stringify(data) : undefined,
        // ✅ API 23：DNS 缓存优化
        usingDNSCache: true,
        connectTimeout: 30000,
        readTimeout: 30000
      })

      if (response.responseCode === 200) {
        return JSON.parse(response.result as string) as T
      }
      throw new Error(`HTTP ${response.responseCode}`)
    } catch (err) {
      hilog.error(0x0000, 'HttpService', 'Request failed: %{public}s', JSON.stringify(err))
      throw err
    } finally {
      this.httpRequest?.destroy()
      this.httpRequest = null
    }
  }
}
```

---

## 9. HDS 性能优化规范

### 渲染优化

```typescript
@Entry
@ComponentV2
struct OptimizedPage {
  @Local listData: string[] = []

  @Computed
  get itemCount(): number {
    return this.listData.length
  }

  build() {
    HdsNavigation() {
      List() {
        LazyForEach(this.dataSource, (item: string) => {
          ListItem() {
            GlassCard({ title: item })    // 使用 HDS 风格卡片
          }
          .reuseId('glass_card')
        })
      }
      .cachedCount(5)
    }
  }
}
```

### HDS 性能禁忌

| 禁忌 | 原因 | 解决方案 |
|------|------|---------|
| 在 Scroll 内嵌套过多 Material 组件 | 实时模糊计算导致滚动卡顿 | 仅在顶部导航或固定栏使用沉浸光感 |
| 全屏所有卡片使用 backdropFilter | GPU 过度绘制 | 仅关键区域使用，普通区域用纯色/简单模糊 |
| 忽略 `thermoCtrl` | 光效未自适应系统温度 | 始终开启 `thermoCtrl: true` |
| 硬编码材质参数 | 不同设备效果差异大 | 使用 `ADAPTIVE` 让系统自动决定 |

### 内存管理

```typescript
@Component
struct MemorySafeComponent {
  private intervalId: number = -1

  aboutToAppear(): void {
    this.intervalId = setInterval(() => this.refreshData(), 5000)
  }

  aboutToDisappear(): void {
    if (this.intervalId !== -1) {
      clearInterval(this.intervalId)
      this.intervalId = -1
    }
  }

  // API 23：跨语言内存泄漏检测
  // 在 DevEco Profiler 中联合采集 local/global trace + 堆快照
  private refreshData(): void { }
}
```

---

## 10. 安全规范

### 权限声明

```json
// module.json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET",
        "reason": "$string:permission_internet_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

### 运行时权限申请

```typescript
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit'

async function requestPermission(permission: Permissions): Promise<boolean> {
  const atManager = abilityAccessCtrl.createAtManager()
  const grantStatus = await atManager.checkAccessToken(permission)

  if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
    return true
  }

  const authResults = await atManager.requestPermissionsFromUser(
    getContext(), [permission]
  )
  return authResults.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
}
```

---

## 11. 日志与调试规范

### 日志规范

```typescript
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = 'MyService'

hilog.debug(DOMAIN, TAG, 'Debug: %{public}s', value)
hilog.info(DOMAIN, TAG, 'Success: %{public}d', code)
hilog.warn(DOMAIN, TAG, 'Deprecated API')
hilog.error(DOMAIN, TAG, 'Error: %{public}s', JSON.stringify(err))

// 敏感信息脱敏
hilog.info(DOMAIN, TAG, 'User: %{private}s, ID: %{public}d', userName, userId)
```

### API 23 调试工具

```typescript
// DevEco Studio 6.1.0 新增能力：
// 1. ArkUI Inspector：查看窗口交互事件（触屏、鼠标、焦点变化）
// 2. DevEco Profiler：ArkTS Snapshot 泳道，分析内存申请释放
// 3. 跨语言内存泄漏：联合采集 local/global trace + 堆快照
// 4. AppAnalyzer：上架合规体检、云端真机测试
// 5. Hvigor 可视化任务查看
```

---

## 12. 资源管理规范

### 引用资源

```typescript
// 系统 Symbol
SymbolGlyph($r('sys.symbol.checkmark.circle.fill'))
  .fontSize(24)
  .fontColor([$r('sys.color.brand')])

// 应用资源
Text($r('app.string.app_name'))
  .fontColor($r('app.color.text_primary'))

Image($r('app.media.logo'))
  .width($r('app.float.logo_width'))

// rawfile
Image($rawfile('images/banner.png'))
```

---

## 13. API 23 HDS 与系统新增能力

### HdsTabs 悬浮样式配置

```typescript
HdsTabs({ controller: this.tabsController })
  .barFloatingStyle({
    barSideMargin: 18,              // 左右留白
    barBottomMargin: 28,            // 底部留白
    thermoCtrl: true,               // 温度控制
    gradientMask: {
      maskColor: '#66F1F3F5',
      maskHeight: 92
    },
    systemMaterialEffect: {
      materialType: hdsMaterial.MaterialType.ADAPTIVE,
      materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
    }
  })
```

### HdsNavigation 标题栏沉浸光感

```typescript
HdsNavigation()
  .titleBar({
    content: { title: { mainTitle: '标题' } },
    style: {
      thermoCtrl: true,
      systemMaterialEffect: {
        materialType: hdsMaterial.MaterialType.ADAPTIVE,
        materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
      }
    }
  })
```

### 其他 API 23 新特性速查

| Kit | 新增能力 |
|-----|---------|
| ArkUI | 自定义键盘切换接续、跑马灯间距/延迟、滚动组件模拟拖拽、Attach/Detach 生命周期 |
| ArkTS | 模块懒加载、跨语言内存泄漏检测（Local/ Global Handle） |
| Ability Kit | hnp Native 包独立签名、启动时间戳 |
| Camera Kit | HDR 动态照片拍摄 |
| Audio Kit | 变声效果、系统音效管理 |
| Media Kit | 批量视频缩略图提取、HDR 转 SDR |
| Network Kit | DNS 缓存增强 |
| ArkWeb | 模拟点击检测、首屏渲染时间统计 |

---

## 14. 常见错误与规避

| 错误描述 | 原因 | 解决方案 |
|---------|------|---------|
| `systemMaterialEffect is not supported` | 设备 API < 23 | 使用 `deviceInfo.sdkApiVersion >= 23` 检测后降级 |
| `IMMERSIVE material not available` | 设备不支持沉浸式材质 | 用 `hdsMaterial.getSystemMaterialTypes()` 检测，降级到 SMOOTH |
| Scroll 卡顿 | Material 组件过多 | 仅导航栏使用沉浸光感，内容区用 GlassCard 替代 |
| 悬浮页签被 Dialog 遮挡 | zIndex 层级问题 | 调整 Stack 中页签层的 zIndex |
| `Type 'any' is not supported` | 使用了 any 类型 | 显式声明类型 |
| `V2 decorator not supported` | 在 V1 组件中使用 V2 装饰器 | 将 `@Component` 改为 `@ComponentV2` |
| HdsNavigation titleBar 与 TabContent 内部标题重复 | 导航栏和子页面同时显示标题 | 去掉 `HdsNavigation` 的 `titleBar`，由各 `TabContent` 自行管理标题栏 |
| 页面底部出现多余空白 | `Stack.padding(bottom)` 与 `HdsNavigation.ignoreLayoutSafeArea(BOTTOM)` 重复处理安全区 | 只保留一处底部安全区适配，去掉外层 `Stack` 的 bottom padding |
| 圆形按钮旁边出现方形阴影/轮廓 | `Circle()` 嵌套在 `Stack()` 内，`Stack` 的矩形边界导致 shadow/点击效果沿方形边缘投射 | 去掉内层 `Circle()`，直接给 `Stack` 设置 `.backgroundColor()` + `.borderRadius(宽高/2)` |
| SymbolGlyph 显示为带边框的方框（tofu） | 系统 Symbol 资源在当前设备/预览器上不可用 | 更换为其他系统 Symbol，或使用 `Image` + `$r('app.media.xxx')` 替代 |
| 预览器白屏/无法加载数据 | 预览器不会执行 `EntryAbility.onCreate()`，`getContext()` 返回 null | 实现内存 Mock Preferences，Context 为 null 时自动降级到内存存储 |

---

## 15. HDS 沉浸光感构建清单

- [ ] `build-profile.json5` 中 `compileSdkVersion` 设置为 `6.1.0(23)`
- [ ] `oh-package.json5` 已依赖 `@kit.UIDesignKit`
- [ ] UI 使用 `HdsNavigation` + `HdsTabs` 替代原生 Navigation/Tabs
- [ ] 标题栏和页签均配置 `systemMaterialEffect`
- [ ] 已检测设备材质能力并编写降级逻辑
- [ ] 悬浮页签已适配安全区（`bottomAvoidHeight + 页签高度 + 边距`）
- [ ] `thermoCtrl: true` 已开启
- [ ] 内容区底部预留足够空间避免被悬浮页签遮挡
- [ ] API 22 及以下有降级方案（传统 Tabs + 自定义样式）
- [ ] 上架前使用 AppAnalyzer 进行合规体检

---

## 版本演进参考

| API 版本 | 系统版本 | 发布时间 | 关键特性 |
|---------|---------|---------|---------|
| 22 | 6.0.2 | 2026.03 | Stage 模型成熟 |
| **23** | **6.1.0** | **2026.04.20** | **HDS 沉浸光感、悬浮页签、V2 装饰器稳定** |
| 24 | 6.1.1 | 2026.05.26 | 动态布局容器、跨 Ability 组件迁移 |

---

## 16. 实战踩坑补充（Focus Tomato 项目经验）

### 16.1 HdsNavigation titleBar 与 TabContent 标题重复

当 `HdsNavigation` 配置了固定的 `titleBar`，而各 `TabContent` 内部又自定义了标题栏时，首页会出现标题文字叠加重复。

```typescript
// ❌ 错误：导航栏和子页面同时显示标题
HdsNavigation()
  .titleBar({ content: { title: { mainTitle: 'Focus Tomato' } } })
// IndexPage 内部又有一个 Row { Text('Focus Tomato') }

// ✅ 正确：去掉导航栏 titleBar，由子页面自行管理
HdsNavigation()
  // 不设置 titleBar，或根据 activeTab 动态变化
// IndexPage / StatisticsPage / SettingsPage 各自定义标题栏
```

> 适用场景：底部 Tab 导航中，各页签需要不同的顶部标题（如"首页"/"统计"/"设置"）。

### 16.2 底部安全区域重复处理导致空白

同时使用以下两种方案时，底部会被重复推上去，产生多余空白：

```typescript
// ❌ 错误：两处同时处理底部安全区
Stack({ alignContent: Alignment.Bottom }) {
  HdsNavigation() { ... }
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.BOTTOM])
}
.padding({ bottom: this.bottomAvoidHeight })   // 重复！

// ✅ 正确：只保留 HdsNavigation 的安全区处理
Stack({ alignContent: Alignment.Bottom }) {
  HdsNavigation() { ... }
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.BOTTOM])
}
// 外层 Stack 不再额外加 bottom padding
```

### 16.3 Stack + Circle 嵌套导致的方形阴影/轮廓

用 `Circle()` 嵌套在 `Stack()` 内实现圆形按钮时，`Stack` 的矩形边界会导致 `shadow` 和点击高亮沿方形边缘投射：

```typescript
// ❌ 错误：shadow 和点击效果沿 Stack 的矩形边界
Stack({ alignContent: Alignment.Center }) {
  Circle().width(72).height(72).fill('#FF6B6B')
  SymbolGlyph($r('sys.symbol.play_fill'))
}
.width(72).height(72)
.shadow({ radius: 12, color: '#FF6B6B40', offsetY: 4 })

// ✅ 正确：Stack 自身就是圆形
Stack({ alignContent: Alignment.Center }) {
  SymbolGlyph($r('sys.symbol.play_fill'))
    .fontSize(28)
    .fontColor(['#FFFFFF'])
}
.width(72)
.height(72)
.backgroundColor('#FF6B6B')
.borderRadius(36)    // 72/2 = 36，形成正圆
.shadow({ radius: 12, color: '#FF6B6B40', offsetY: 4 })
```

> 同理，将 `.onClick()` 绑定在已经是圆形的 `Stack` 上，点击高亮区域也会沿圆形边界。

### 16.4 预览器无法获取 Context 的降级方案

预览器不会执行 `EntryAbility.onCreate()`，导致 `getContext()` 为 null，Preferences 获取失败页面白屏。

```typescript
// StorageUtil.ets — 内存 Mock Preferences 降级
private static getMockPreferences(): preferences.Preferences {
  const store = new Map<string, preferences.ValueType>()
  return {
    put: async (key, value) => { store.set(key, value) },
    get: async (key, defaultValue) => store.has(key) ? store.get(key)! : defaultValue,
    delete: async (key) => { store.delete(key) },
    flush: async () => {},
    clear: async () => { store.clear() }
  } as preferences.Preferences
}

private static async getPreferences(): Promise<preferences.Preferences> {
  if (!StorageUtil.context) {
    return this.getMockPreferences()   // 预览器自动降级到内存存储
  }
  return await preferences.getPreferences(StorageUtil.context, 'app_storage')
}
```

### 16.5 SymbolGlyph 渲染为方框（tofu）的规避

当系统 Symbol 资源在特定设备或预览器上不可用时，`SymbolGlyph` 会渲染为带边框的方框。

**规避方案**：
1. 优先使用高频系统 Symbol（如 `play_fill`、`pause_fill`、`checkmark`、`gearshape` 等）
2. 关键图标准备应用内资源兜底：`Image($r('app.media.icon_name'))`
3. 避免在 Symbol 资源名称中使用过于冷门的组合

### 16.6 `promptAction.showActionMenu` 最多只能放 6 个按钮

ArkTS 严格模式下，`showActionMenu` 的 `buttons` 参数类型是固定长度为 6 的元组 `[Button, Button?, Button?, Button?, Button?, Button?]`，超过 6 个按钮会导致编译错误。

```typescript
// ❌ 错误：12 个按钮超出限制
const durations = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
promptAction.showActionMenu({
  buttons: durations.map(d => ({ text: `${d} 分钟`, color: '#1A1A1A' }))  // 编译报错！
})

// ✅ 正确：改用 @CustomDialog 自定义选择器
@CustomDialog
struct DurationPickerDialog {
  controller: CustomDialogController
  @Prop durations: number[] = []
  @Prop selectedValue: number = 25
  onSelect: (value: number) => void = () => {}

  build() {
    Column({ space: 16 }) {
      Text('选择时长').fontSize(18).fontWeight(FontWeight.Bold)
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
        ForEach(this.durations, (d: number) => {
          Column() {
            Text(`${d}`).fontSize(16).fontColor('#1A1A1A')
            Text('分钟').fontSize(10).fontColor('#999999')
          }
          .width('22%').height(48)
          .backgroundColor(d === this.selectedValue ? '#FF6B6B' : '#F5F5F5')
          .borderRadius(10)
          .onClick(() => {
            this.onSelect(d)
            this.controller.close()
          })
        })
      }
    }
    .width('85%').padding(20)
    .backgroundColor('#FFFFFF').borderRadius(20)
  }
}
```

### 16.7 `UIContext.setHostColorMode` / `ColorMode` 不存在

API 23 中 `ColorMode` 不在 `@kit.ArkUI` 中导出，`UIContext` 也没有 `setHostColorMode` 方法，`Window.setWindowColorMode` 同样不存在。

**当前可用方案**：
1. 保存 `darkMode` 设置值到 Preferences
2. 在 `EntryAbility.onCreate` 中通过 `ApplicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK)` 设置应用级别颜色模式
3. 提示用户重启应用后生效

```typescript
// EntryAbility.ets
onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  try {
    this.context.getApplicationContext().setColorMode(
      ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
    )
  } catch (err) {
    hilog.error(DOMAIN, TAG, 'Failed to set colorMode')
  }
}

// SettingsPage.ets — 切换时仅保存并提示
onToggle: (checked: boolean) => {
  this.settings.darkMode = checked
  this.saveSettings()
  promptAction.showToast({ message: '重启应用后生效' })
}
```

### 16.8 `private static` 方法无法在类外部访问

ArkTS 严格模式下，`private` 修饰符会阻止类外部访问，即使只是工具类的辅助方法。

```typescript
// ❌ 错误：外部无法调用
class TimeUtil {
  private static pad(num: number): string {  // private 导致外部无法访问
    return num < 10 ? `0${num}` : `${num}`
  }
}

// 外部调用时编译报错
TimeUtil.pad(5)   // Property 'pad' is private

// ✅ 正确：改为 public 或不加修饰符（默认 public）
class TimeUtil {
  static pad(num: number): string {   // 去掉 private
    return num < 10 ? `0${num}` : `${num}`
  }
}
```

---

## 17. 后台提醒（@kit.BackgroundTasksKit）

### reminderAgentManager 定时提醒

用于应用切后台后，在指定时间触发系统通知。

```typescript
import { reminderAgentManager } from '@kit.BackgroundTasksKit'

const REMINDER_NOTIFICATION_ID = 10001
let reminderId: number = -1

// 发布定时提醒（倒计时场景）
async function publishTimerReminder(leftTimeSeconds: number, title: string, content: string): Promise<void> {
  try {
    // 先取消之前的提醒
    if (reminderId !== -1) {
      await reminderAgentManager.cancelReminder(reminderId)
    }

    const reminderRequest: reminderAgentManager.ReminderRequestTimer = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_TIMER,
      triggerTimeInSeconds: leftTimeSeconds,
      title: title,
      content: content,
      notificationId: REMINDER_NOTIFICATION_ID
    }

    reminderId = await reminderAgentManager.publishReminder(reminderRequest)
    hilog.info(0x0000, 'Reminder', 'Published reminder id=%{public}d', reminderId)
  } catch (err) {
    hilog.error(0x0000, 'Reminder', 'Failed: %{public}s', JSON.stringify(err))
  }
}

// 取消提醒
async function cancelTimerReminder(): Promise<void> {
  if (reminderId !== -1) {
    try {
      await reminderAgentManager.cancelReminder(reminderId)
      reminderId = -1
    } catch (err) {
      hilog.error(0x0000, 'Reminder', 'Cancel failed: %{public}s', JSON.stringify(err))
    }
  }
}
```

**注意事项**：
- 需要在 `module.json5` 中声明 `ohos.permission.PUBLISH_AGENT_REMINDER` 权限
- `triggerTimeInSeconds` 是从当前时间开始的倒计时秒数
- 每次发布新提醒前应先取消旧的，避免重复通知
- 暂停/重置计时器时也需要取消对应的提醒

---

## 18. 上架合规规范

### 18.1 应用元数据填写

| 文件 | 必填字段 | 示例 |
|------|---------|------|
| `AppScope/resources/base/element/string.json` | `app_name` | "番茄钟" |
| `entry/src/main/resources/base/element/string.json` | `module_desc` | "番茄钟 - 专注计时器，帮助您提高工作效率" |
| `entry/src/main/resources/base/element/string.json` | `EntryAbility_desc` | "番茄钟专注计时器主入口" |
| `entry/src/main/resources/base/element/string.json` | `EntryAbility_label` | "番茄钟" |
| `oh-package.json5` | `description` | 应用的完整描述 |
| `entry/oh-package.json5` | `description` / `author` / `license` | 模块描述、作者、许可证 |

### 18.2 隐私政策

上架应用必须提供隐私政策，内容至少包含：
1. **信息收集**：说明收集了哪些数据（即使只在本地存储也需说明）
2. **信息使用**：数据用途说明
3. **信息共享**：是否与第三方共享
4. **数据安全**：存储方式和保护措施
5. **权限说明**：申请的每个权限的用途
6. **联系方式**：用户如何联系开发者

```typescript
// 隐私政策页面（独立 @Entry 页面）
@Entry
@Component
struct PrivacyPolicyPage {
  build() {
    Column() {
      // 顶部返回导航栏
      Row() { /* 返回按钮 + 标题 */ }

      Scroll() {
        Column({ space: 16 }) {
          Text('隐私政策').fontSize(18).fontWeight(FontWeight.Bold)

          // 各章节内容
          this.buildSection('一、信息收集', '本应用仅在本地设备上运行...')
          this.buildSection('二、信息使用', '本地存储的数据仅用于...')
          this.buildSection('三、权限说明', '本应用可能需要申请以下权限...')
          // ...
        }
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
      }
      .layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor('#FAFAFA')
  }
}
```

### 18.3 权限声明规范

```json5
// module.json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.VIBRATE",
        "reason": "$string:permission_vibrate_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.PUBLISH_AGENT_REMINDER",
        "reason": "$string:permission_reminder_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

**权限 best practice**：
- 每个权限必须有对应的 `reason` 字符串资源，说明为什么需要该权限
- `usedScene.when` 尽量使用 `"inuse"`（使用时申请），减少用户抵触
- 普通权限（如 VIBRATE）在 `module.json5` 声明后自动授予，不需要运行时申请
- 敏感权限（如相机、位置）需要配合 `abilityAccessCtrl` 运行时申请

### 18.4 上架前检查清单

- [ ] 所有 `string.json` 占位符已替换为正式内容（无 "label"、"description"、"module description" 等默认文本）
- [ ] `oh-package.json5` 和 `entry/oh-package.json5` 已填写 `description`、`author`、`license`
- [ ] `module.json5` 中权限声明完整，每个权限有 `reason` 字符串资源
- [ ] 隐私政策页面内容完整，包含在应用中可访问的入口
- [ ] 关于我们页面包含版本号、隐私政策入口
- [ ] 应用图标、启动图标已替换为正式素材（非占位图）
- [ ] `build-profile.json5` 中配置了正式签名证书
- [ ] Release 包建议开启代码混淆（`obfuscation.enable: true`）
- [ ] 使用 AppAnalyzer 进行上架合规体检
- [ ] 代码中无 `testTag` 等开发期日志标签（改为有意义的 TAG 常量）

---

## 参考资源

- [HarmonyOS 6.1.0 版本概览 - 华为开发者官网](https://developer.huawei.com/consumer/cn/doc/harmonyos-releases/overview-610)
- [HDS 悬浮页签指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ui-design-hds-tabs-bar-floating)
- [HDS 沉浸光感材质指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ui-design-hds-component-material)
- [ArkUI V2 状态管理](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-decorator-overview)
- [后台提醒开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/background-reminder-agent)
- [应用上架合规指南](https://developer.huawei.com/consumer/cn/doc/app/agc-help-harmonyos-app-release-000000191)

---

## 附录 A：SnapSticker 项目特定约定

### A.1 项目概述

SnapSticker 是一款基于 HarmonyOS API 23 的贴纸收集与创作应用，采用 HDS 沉浸光感设计体系。

- **产品定位**：把生活中的物体收集成贴纸，并自由组合创作
- **核心流程**：拍照 → 智能抠图 → 贴纸编辑 → 贴纸库 → 画布创作 → 导出分享
- **技术栈**：ArkTS Strict Mode + ArkUI + HDS (`@kit.UIDesignKit`)

### A.2 颜色 Token

```typescript
// constants/ThemeConstants.ets
export const BRAND_PRIMARY   = '#6B5CE7'   // 品牌紫
export const BRAND_PRIMARY_LIGHT = '#F0EDFF' // 浅紫背景
export const BG_BASE         = '#F8F8F6'   // 页面底色
export const CARD_BG         = '#FFFFFF'   // 卡片背景
export const INK_DEEP        = '#1A1A1A'   // 深色文字
export const INK_MID         = '#666666'   // 中等文字
export const INK_LIGHT       = '#999999'   // 浅色文字
export const DIVIDER         = '#E5E5E5'   // 分割线
export const CHIP_BG         = '#F2F2F2'   // 标签/Chip 背景
export const VIP_GOLD        = '#FFB400'   // VIP 徽章金黄色
export const DANGER          = '#FF3B30'   // 删除/危险色
```

### A.3 已验证系统 Symbol 清单

以下 Symbol 在 SnapSticker 项目中已验证可用：

| Symbol | 用途 |
|--------|------|
| `sys.symbol.square_grid_2x2` | 贴纸库、网格 |
| `sys.symbol.paintbrush` | 画布创作 |
| `sys.symbol.person` / `person_2` | 我的、朋友圈 |
| `sys.symbol.gear` | 设置 |
| `sys.symbol.plus` | 新建、添加 |
| `sys.symbol.chevron_left` / `chevron_right` | 返回、展开 |
| `sys.symbol.xmark` | 关闭 |
| `sys.symbol.arrow_counterclockwise` / `arrow_clockwise` | 撤销、重做 |
| `sys.symbol.camera` | 拍照 |
| `sys.symbol.photo` | 相册、背景 |
| `sys.symbol.square_and_arrow_up` | 分享 |
| `sys.symbol.ellipsis` | 更多 |
| `sys.symbol.trash` | 删除 |
| `sys.symbol.heart` | 收藏、小红书 |
| `sys.symbol.lock` | 隐私 |
| `sys.symbol.doc_text` | 文档/协议 |
| `sys.symbol.questionmark_circle` | 帮助 |
| `sys.symbol.info_circle` | 关于 |
| `sys.symbol.star` | 背景、调整（占位） |
| `sys.symbol.textformat` | 文字工具 |
| `sys.symbol.checkmark_circle_fill` | 选中态 |
| `sys.symbol.slider_horizontal_3` | 调整工具 |

> ⚠️ **避坑**：未在本清单中列出的 Symbol 可能存在 tofu（方框）风险，使用前请先在真机或预览器上验证。

### A.4 HDS 封装组件

项目位于 `components/hds/` 目录，提供 HDS 风格的 ArkUI 封装：

| 组件 | 路径 | 说明 |
|------|------|------|
| `HdsActionBar` | `components/hds/HdsActionBar.ets` | 顶部操作栏（startButtons / primaryText / endButtons） |
| `HdsListItem` | `components/hds/HdsListItem.ets` | 列表项（图标 + 主文本 + 后缀） |
| `HdsSnackBar` | `components/hds/HdsSnackBar.ets` | 底部操作反馈提示 |
| `HdsToolBar` | `components/hds/HdsToolBar.ets` | 底部横向工具栏 |

### A.5 页面导航结构

```
HdsTabs (根容器)
├── TabContent 1: 贴纸库
│   └── Navigation (HomeNavStack)
│       ├── HomePage (首页)
│       ├── ProcessingPage (智能抠图中)
│       ├── StickerEditPage (贴纸编辑)
│       ├── SaveSuccessPage (加入收藏成功)
│       ├── StickerDetailPage (贴纸详情)
│       ├── CategoryPage (分类查看)
│       ├── CategoryManagePage (分类管理)
│       ├── SearchPage (搜索贴纸)
│       ├── NoSubjectPage (未检测到主体)
│       ├── BlurSubjectPage (主体模糊)
│       └── MultiSubjectSelectPage (多主体选择)
│
├── TabContent 2: 画布
│   └── Navigation (CanvasNavStack)
│       ├── CanvasEditPage (画布创作)
│       ├── ExportPage (导出分享)
│       └── BackgroundPage (画布背景)
│
└── TabContent 3: 我的
    └── Navigation (ProfileNavStack)
        └── ProfilePage (我的页面)
            ├── PrivacyPolicyPage (隐私政策)
            └── UserAgreementPage (用户协议)
```

### A.6 TabBar 特殊约定

SnapSticker 使用 **4 个 Tab**（非标准 3 个），中间拍照 Tab 为特殊样式：

```typescript
// 拍照 Tab 使用紫色圆形凸起样式
@Builder
CameraTabBuilder(): void {
  Column({ space: 4 }) {
    Stack() {
      SymbolGlyph($r('sys.symbol.camera'))
        .fontSize(28)
        .fontColor([Color.White])
    }
    .width(56)
    .height(56)
    .backgroundColor($r('app.color.brand_primary'))
    .borderRadius(28)
    .shadow({ radius: 12, color: 'rgba(107, 92, 231, 0.4)', offsetY: 4 })

    Text('拍照').fontSize(11).fontColor($r('app.color.ink_mid'))
  }
  .justifyContent(FlexAlign.Center)
}
```

> 拍照 Tab **不切换页面**，点击时弹出新建贴纸选择器（bindSheet）。

### A.7 卡片阴影规范

```typescript
// 通用卡片阴影
.shadow({
  radius: 8,
  color: 'rgba(0,0,0,0.12)',
  offsetX: 0,
  offsetY: 2
})

// 浮动面板阴影（底部弹出）
.shadow({ radius: 16, color: 'rgba(0,0,0,0.08)', offsetY: -4 })

// 预览图阴影
.shadow({ radius: 16, color: 'rgba(0,0,0,0.1)', offsetY: 8 })
```
