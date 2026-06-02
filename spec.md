# SnapSticker · MVP 产品规格说明书（v0.4 — HDS + API23 全面组件化版）

> 产品定位：把生活中的物体收集成贴纸，并自由组合创作。  
> 目标平台：HarmonyOS 6.1.0+（API 23），手机形态为主，适配折叠屏 Parallel View。  
> 技术栈：ArkTS + ArkUI + **HDS（HarmonyOS Design System / UI Design Kit）**。  
> UI 原则：**所有导航、操作栏、列表卡片、提示组件优先使用 HDS 预制组件**，仅在 HDS 未覆盖场景使用基础 ArkUI 组件自定义。

---

# 1. 产品愿景（不变）

用户通过拍照，将现实世界中的物体自动抠图生成贴纸。  
这些贴纸会进入个人贴纸库，持续积累后在画布中自由组合，形成属于自己的视觉手账。

## 核心价值

不是 `抠图工具`，而是 `生活贴纸收藏册`。

---

# 2. 产品定位（不变）

一句话描述：

> 把生活收集成贴纸。

---

# 3. MVP 目标与假设（不变）

| 假设 | 指标 |
|------|------|
| H1：用户愿意持续收集贴纸 | 70% 以上用户生成 3 张以上贴纸 |
| H2：自动抠图质量足够好 | 满意度 ≥ 4/5 |
| H3：用户愿意进行拼贴创作 | 50% 以上用户创建至少 1 张画布 |

---

# 4. 信息架构与导航方案（HDS 根容器）

## 4.1 全局根容器：HdsTabs（浮动底栏）

整个应用以 **`HdsTabs`** 作为根视图容器（Page 级别），承载三大主模块：

```text
HdsTabs (根容器，barPosition: End，浮动样式)
├── TabContent 1: 首页/贴纸库
│   └── NavDestination Stack
│       ├── 首页（贴纸网格 + 分类标签）
│       ├── 拍照/相册选择
│       ├── 智能抠图中
│       ├── 贴纸编辑页
│       ├── 加入收藏成功
│       ├── 分类贴纸库
│       ├── 贴纸详情
│       ├── 分类管理
│       └── 搜索贴纸
│
├── TabContent 2: 画布创作
│   └── NavDestination Stack
│       ├── 画布编辑页
│       └── 导出页
│
└── TabContent 3: 我的
    └── NavDestination Stack
        └── 我的页面
```

> **HDS 规范**：`HdsTabs` 作为根视图容器时，每个 `TabContent` 内部使用 `Navigation` + `NavDestination` 管理子页面栈。  
> **API23 增强**：`HdsTabs` 支持浮动样式（`floatingStyle`）+ `systemMaterialEffect` 沉浸光感 + `barOverlap(true)` 内容区顶底栏模糊叠加 + `barBackgroundStyle` 渐变模糊。

### HdsTabs 全局配置

```typescript
import { HdsTabs, HdsTabsController, hdsMaterial } from '@kit.UIDesignKit';

@Entry
@Component
struct RootPage {
  private hdsTabController: HdsTabsController = new HdsTabsController();
  @State useApi23: boolean = false;

  aboutToAppear(): void {
    this.useApi23 = deviceInfo.sdkApiVersion >= 23;
  }

  build() {
    HdsTabs({ controller: this.hdsTabController }) {
      TabContent() { HomeNavStack() }
        .tabBar({ icon: $r('sys.symbol.square_grid_2x2'), text: '贴纸库' })

      TabContent() { CanvasNavStack() }
        .tabBar({ icon: $r('sys.symbol.paintbrush'), text: '画布' })

      TabContent() { ProfileNavStack() }
        .tabBar({ icon: $r('sys.symbol.person'), text: '我的' })
    }
    .barPosition(BarPosition.End)
    .vertical(false)
    .barOverlap(true)                       // TabBar 叠加在内容之上，背景模糊
    .divider({ mode: DividerMode.NONE })    // 无分割线，沉浸效果
    .barBackgroundBlurStyle(BlurStyle.COMPONENT_THICK)
    .applyTheme(this.useApi23 ? {
      floatingStyle: {
        systemMaterialEffect: hdsMaterial.Effect.EXQUISITE
      }
    } : {})
  }
}
```

---

## 4.2 子页面导航：Navigation + NavDestination

每个 `TabContent` 内部使用 `Navigation` 容器管理子页面栈：

```typescript
@Component
struct HomeNavStack {
  @Provide('homePathStack') pathStack: NavPathStack = new NavPathStack();

  build() {
    Navigation(this.pathStack) {
      // 默认显示首页
      HomePage()
    }
    .hideTitleBar(true)  // 使用 HdsActionBar 替代系统标题栏
    .navDestination({
      // 注册所有子页面
      'StickerEditPage': StickerEditPage,
      'CategoryPage': CategoryPage,
      'StickerDetailPage': StickerDetailPage,
      'CategoryManagePage': CategoryManagePage,
      'SearchPage': SearchPage,
    })
  }
}
```

> **API23 Navigation 增强**：支持分栏定制（`splitPaneMode`）、分栏分割线样式、右侧默认占位页、单页面自定义主题（局部页面自定义主题）。折叠屏场景下自动适配 Parallel View。

---

# 5. 页面设计（HDS 组件化实现）

---

## Page 1：首页（贴纸库）

### 布局结构

```typescript
@Component
struct HomePage {
  @State selectedCategory: string = '全部';
  @State stickerList: Sticker[] = [];

  build() {
    Column() {
      // 顶部操作栏：HdsActionBar
      HdsActionBar({
        primaryText: { text: 'SnapSticker', fontSize: 24, fontWeight: FontWeight.Bold },
        endButtons: [
          { icon: $r('sys.symbol.gear'), action: () => { /* 设置 */ } }
        ]
      })
      .actionBarStyle(ActionBarStyle.NORMAL)

      // 新建贴纸按钮（HDS 无专用大按钮卡片，使用 HdsListItemCard 变体或自定义圆角卡片）
      NewStickerCard()

      // 分类标签横向滚动（ArkUI Scroll + Row，HDS 无横向二级标签组件）
      CategoryScrollBar({ selected: this.selectedCategory })

      // 贴纸网格（ArkUI Grid + LazyForEach）
      StickerGrid({ stickers: this.stickerList })

      Spacer()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_base'))
  }
}
```

### 新建贴纸卡片

使用自定义圆角卡片，但遵循 HDS 视觉规范（`borderRadius(16)`，无硬边框，软阴影）：

```typescript
@Builder
function NewStickerCard() {
  Column() {
    Row() {
      SymbolGlyph($r('sys.symbol.plus'))
        .fontSize(24)
        .fontColor($r('app.color.brand_primary'))
      Text('新建贴纸')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ left: 8 })
      Blank()
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor($r('app.color.ink_light'))
    }
    .width('100%')
    .padding(16)
  }
  .width('100%')
  .margin(16)
  .backgroundColor(Color.White)
  .borderRadius(16)
  .shadow({
    radius: 12,
    color: 'rgba(26, 26, 26, 0.06)',
    offsetX: 2,
    offsetY: 4
  })
  .onClick(() => {
    // bindSheet 弹出相机/相册选项
  })
}
```

### 分类标签栏

```typescript
@Component
struct CategoryScrollBar {
  @Link selected: string;
  private categories: string[] = ['全部', '咖啡', '美食', '花草', '宠物', '其他'];

  build() {
    Scroll() {
      Row({ space: 12 }) {
        ForEach(this.categories, (cat: string) => {
          Text(cat)
            .fontSize(14)
            .fontWeight(this.selected === cat ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(this.selected === cat ? $r('app.color.brand_primary') : $r('app.color.ink_mid'))
            .backgroundColor(this.selected === cat ? $r('app.color.brand_primary_light') : Color.Transparent)
            .padding({ top: 6, bottom: 6, left: 12, right: 12 })
            .borderRadius(16)
            .onClick(() => { this.selected = cat; })
        })
      }
      .padding({ left: 16, right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .width('100%')
    .height(48)
  }
}
```

### 贴纸网格

```typescript
@Component
struct StickerGrid {
  @Prop stickers: Sticker[];
  private gridScroller: Scroller = new Scroller();

  build() {
    Grid(this.gridScroller) {
      LazyForEach(new StickerDataSource(this.stickers), (sticker: Sticker) => {
        GridItem() {
          Image(sticker.uri)
            .width('100%')
            .aspectRatio(1)
            .objectFit(ImageFit.Cover)
            .borderRadius(12)
            .shadow({
              radius: 8,
              color: 'rgba(26, 26, 26, 0.05)',
              offsetX: 1,
              offsetY: 2
            })
        }
        .onClick(() => { /* 进入贴纸详情 */ })
      }, (sticker: Sticker) => sticker.id.toString())
    }
    .columnsTemplate('1fr 1fr 1fr')
    .columnsGap(8)
    .rowsGap(8)
    .padding(16)
    .layoutWeight(1)
    .cachedCount(2)
    // API23：Grid 支持长按聚合动画（多选预留）
    .longPressGatherAnimation(this.useApi23 ? { duration: 300 } : undefined)
  }
}
```

---

## Page 2：拍照/相册选择页

- 不单独做页面，使用系统能力直接调起：
  - 拍照：`CameraPicker`（`@kit.CameraKit`）
  - 相册导入：`photoAccessHelper.PhotoViewPicker`
- 返回 `PixelMap` 后直接进入「智能抠图中」页。

---

## Page 3：智能抠图中（Loading）

```typescript
@Component
struct ProcessingPage {
  @State progress: number = 0;
  @State stepText: string = '正在识别主体...';

  build() {
    Column({ space: 24 }) {
      // 中央进度
      Stack() {
        Progress({ value: this.progress, total: 100, type: ProgressType.Ring })
          .width(120)
          .height(120)
          .color($r('app.color.brand_primary'))
          .backgroundColor($r('app.color.brand_primary_light'))
        Text(`${this.progress}%`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }

      Text(this.stepText)
        .fontSize(14)
        .fontColor($r('app.color.ink_mid'))

      Text('预计 1~3 秒')
        .fontSize(12)
        .fontColor($r('app.color.ink_light'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.bg_base'))
  }
}
```

---

## Page 4：贴纸编辑页

### 顶部操作栏：HdsActionBar

```typescript
HdsActionBar({
  startButtons: [
    { icon: $r('sys.symbol.chevron_left'), action: () => { this.pathStack.pop() } }
  ],
  primaryText: { text: '预览 & 编辑', fontSize: 18, fontWeight: FontWeight.Medium },
  endButtons: [
    { text: '保存', textColor: $r('app.color.brand_primary'), action: () => { this.saveSticker() } }
  ]
})
.actionBarStyle(ActionBarStyle.NORMAL)
```

### 预览区与编辑面板

```typescript
Column() {
  // 预览区：棋盘格背景 + 贴纸
  Stack() {
    ChessboardBackground()  // Canvas 绘制棋盘格
    Image(this.stickerUri)
      .objectFit(ImageFit.Contain)
      .width('80%')
  }
  .layoutWeight(1)
  .width('100%')

  // 背景预览切换
  Row({ space: 12 }) {
    ForEach(['透明', '白色', '深色'], (bg: string) => {
      Text(bg)
        .fontSize(12)
        .padding({ top: 4, bottom: 4, left: 12, right: 12 })
        .backgroundColor(this.previewBg === bg ? $r('app.color.brand_primary_light') : Color.Transparent)
        .fontColor(this.previewBg === bg ? $r('app.color.brand_primary') : $r('app.color.ink_mid'))
        .borderRadius(12)
        .onClick(() => { this.previewBg = bg; })
    })
  }
  .padding(12)

  // 编辑面板
  Column({ space: 16 }) {
    // 白边大小
    Row() {
      Text('白边大小').fontSize(14).fontColor($r('app.color.ink_mid'))
      Blank()
      Text(this.borderSize).fontSize(14).fontColor($r('app.color.ink_deep'))
    }
    .width('100%')

    Slider({ value: this.borderValue, min: 0, max: 2, step: 1 })
      .blockColor($r('app.color.brand_primary'))
      .trackColor($r('app.color.brand_primary_light'))
      .selectedColor($r('app.color.brand_primary'))
      .onChange((v) => { this.borderValue = v; })

    // 阴影开关
    HdsListItemCard({
      textItem: {
        primaryText: { text: '阴影', fontSize: 14 }
      },
      suffix: new SuffixSwitch({
        options: { isOn: this.shadowOn }
      })
    })
    .onClick(() => { this.shadowOn = !this.shadowOn; })
  }
  .padding(16)
  .backgroundColor(Color.White)
  .borderRadius({ topLeft: 20, topRight: 20 })
  .shadow({ radius: 16, color: 'rgba(0,0,0,0.08)', offsetY: -4 })
}
```

> **注意**：`HdsListItemCard` 的 `SuffixSwitch` 用于开关项，保持与系统设置一致的视觉风格。

---

## Page 5：加入收藏成功

```typescript
@Component
struct SaveSuccessPage {
  build() {
    Column({ space: 24 }) {
      // 贴纸预览
      Image(this.stickerUri)
        .width(200)
        .aspectRatio(1)
        .borderRadius(16)
        .shadow({ radius: 16, color: 'rgba(0,0,0,0.1)', offsetY: 8 })

      // 撒花效果（Canvas 简单粒子动画）
      ConfettiCanvas()

      Text('已加入贴纸库！')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Text('你可以在贴纸库中找到它')
        .fontSize(14)
        .fontColor($r('app.color.ink_mid'))

      // 主操作按钮（HDS 风格）
      Button('查看贴纸库', { type: ButtonType.Capsule })
        .width('80%')
        .height(48)
        .backgroundColor($r('app.color.brand_primary'))
        .fontColor(Color.White)
        .onClick(() => { this.pathStack.clear(); })

      Button('再来一张', { type: ButtonType.Capsule })
        .width('80%')
        .height(48)
        .backgroundColor(Color.Transparent)
        .fontColor($r('app.color.brand_primary'))
        .border({ width: 1, color: $r('app.color.brand_primary') })
        .onClick(() => { /* 重新拍照 */ })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.bg_base'))
  }
}
```

---

## Page 6：分类贴纸库

```typescript
@Component
struct CategoryPage {
  @Prop category: string;
  @State stickers: Sticker[] = [];

  build() {
    Column() {
      // 顶部操作栏
      HdsActionBar({
        startButtons: [
          { icon: $r('sys.symbol.chevron_left'), action: () => { this.pathStack.pop() } }
        ],
        primaryText: { text: this.category, fontSize: 18, fontWeight: FontWeight.Medium }
      })

      // 空状态或网格
      if (this.stickers.length === 0) {
        EmptyStateView({
          icon: $r('sys.symbol.square_grid_2x2'),
          title: '还没有' + this.category + '贴纸',
          subtitle: '去拍一张吧'
        })
      } else {
        StickerGrid({ stickers: this.stickers })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_base'))
  }
}
```

---

## Page 7：画布创作（核心页面）

### 布局结构

```typescript
@Component
struct CanvasEditPage {
  @State canvasItems: CanvasItem[] = [];
  @State selectedItemId: string | null = null;
  @State activeTool: 'sticker' | 'text' | 'bg' | 'adjust' = 'sticker';

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 画布背景层
      CanvasBackground({ config: this.backgroundConfig })

      // 贴纸/文字元素层
      ForEach(this.canvasItems, (item: CanvasItem) => {
        CanvasElement({ item: item, isSelected: this.selectedItemId === item.id })
          .gesture(
            GestureGroup(GestureMode.Sequence,
              PanGesture() // 拖拽
                .onActionUpdate((e: GestureEvent) => {
                  item.x += e.offsetX;
                  item.y += e.offsetY;
                }),
              PinchGesture() // 缩放
                .onActionUpdate((e: GestureEvent) => {
                  item.scale *= e.scale;
                }),
              RotationGesture() // 旋转
                .onActionUpdate((e: GestureEvent) => {
                  item.rotation += e.angle;
                })
            )
          )
          .onClick(() => { this.selectedItemId = item.id; })
      })

      // 顶部操作栏：HdsActionBar
      HdsActionBar({
        startButtons: [
          { icon: $r('sys.symbol.xmark'), action: () => { this.pathStack.pop() } }
        ],
        endButtons: [
          { icon: $r('sys.symbol.arrow_counterclockwise'), action: () => { this.undo() } },
          { icon: $r('sys.symbol.arrow_clockwise'), action: () => { this.redo() } },
          { text: '完成', textColor: $r('app.color.brand_primary'), action: () => { this.finish() } }
        ]
      })
      .actionBarStyle(ActionBarStyle.NORMAL)
      .align(Alignment.Top)

      // 底部工具面板
      CanvasToolPanel({
        activeTool: this.activeTool,
        onToolChange: (tool) => { this.activeTool = tool; }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_base'))
  }
}
```

### 底部工具面板

使用 `HdsTabs` 作为底部工具栏（横向，barPosition: Bottom）：

```typescript
@Component
struct CanvasToolPanel {
  @Link activeTool: string;
  private tools: Array<{ name: string; icon: Resource }> = [
    { name: 'sticker', icon: $r('sys.symbol.square_grid_2x2') },
    { name: 'text', icon: $r('sys.symbol.textformat') },
    { name: 'bg', icon: $r('sys.symbol.photo') },
    { name: 'adjust', icon: $r('sys.symbol.slider_horizontal_3') }
  ];

  build() {
    Column() {
      // 工具内容区（根据 activeTool 切换）
      if (this.activeTool === 'sticker') {
        StickerPickerSheet()
      } else if (this.activeTool === 'text') {
        TextToolSheet()
      } else if (this.activeTool === 'bg') {
        BackgroundToolSheet()
      } else {
        AdjustToolSheet()
      }

      // 底部工具栏：HdsTabs 横向模式
      HdsTabs({ controller: new HdsTabsController() }) {
        ForEach(this.tools, (tool: { name: string; icon: Resource }) => {
          TabContent() { /* 内容由上层控制 */ }
            .tabBar({ icon: tool.icon, text: this.toolName(tool.name) })
        })
      }
      .barPosition(BarPosition.Start)  // 工具栏在底部
      .vertical(false)
      .barHeight(56)
      .barMode(BarMode.Fixed)
      .onChange((index: number) => {
        this.activeTool = this.tools[index].name;
      })
      .backgroundColor(Color.White)
      .shadow({ radius: 8, color: 'rgba(0,0,0,0.06)', offsetY: -2 })
    }
  }

  private toolName(name: string): string {
    const map: Record<string, string> = {
      sticker: '贴纸', text: '文字', bg: '背景', adjust: '调整'
    };
    return map[name] || name;
  }
}
```

### 画布规格

- 显示比例：`4:5`
- 导出分辨率：`1080 × 1350`
- 实际渲染：`OffscreenCanvas` 离屏绘制，最终导出 `toDataURL()`

---

## Page 8：导出页

```typescript
@Component
struct ExportPage {
  @Prop canvasUri: string;

  build() {
    Column() {
      // 顶部操作栏
      HdsActionBar({
        startButtons: [
          { icon: $r('sys.symbol.xmark'), action: () => { this.pathStack.pop() } }
        ],
        primaryText: { text: '导出', fontSize: 18, fontWeight: FontWeight.Medium }
      })

      // 预览图
      Image(this.canvasUri)
        .width('90%')
        .aspectRatio(4 / 5)
        .borderRadius(12)
        .shadow({ radius: 16, color: 'rgba(0,0,0,0.1)', offsetY: 8 })
        .layoutWeight(1)

      // 操作按钮组
      Column({ space: 12 }) {
        Button('保存到相册', { type: ButtonType.Capsule })
          .width('90%')
          .height(48)
          .backgroundColor($r('app.color.brand_primary'))
          .onClick(() => { this.saveToAlbum(); })

        Button('保存为透明背景 PNG', { type: ButtonType.Capsule })
          .width('90%')
          .height(48)
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.brand_primary'))
          .border({ width: 1, color: $r('app.color.brand_primary') })
          .onClick(() => { this.saveAsPng(); })

        Button('分享', { type: ButtonType.Capsule })
          .width('90%')
          .height(48)
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.ink_mid'))
          .onClick(() => { this.share(); })
      }
      .padding({ bottom: 32, top: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_base'))
  }
}
```

---

## 其他页面（HDS 组件密集使用）

### 分类管理

使用 **`HdsListItemCard`** 展示分类列表，支持拖拽排序和滑动删除：

```typescript
@Component
struct CategoryManagePage {
  @State categories: Category[] = [];

  build() {
    Column() {
      HdsActionBar({
        startButtons: [
          { icon: $r('sys.symbol.chevron_left'), action: () => { this.pathStack.pop() } }
        ],
        primaryText: { text: '分类管理', fontSize: 18, fontWeight: FontWeight.Medium },
        endButtons: [
          { text: '编辑', action: () => { this.toggleEditMode(); } }
        ]
      })

      List() {
        ForEach(this.categories, (cat: Category) => {
          ListItem() {
            HdsListItemCard({
              textItem: {
                primaryText: { text: cat.name, fontSize: 16 },
                primaryPrefixSymbol: { fontResource: cat.icon }
              },
              suffix: new SuffixArrow()
            })
          }
          // API23：List 支持 swipeAction 自定义滑动删除触发类型
          .swipeAction({
            end: {
              builder: () => { this.DeleteButton(cat); }
            }
          })
          .drag({
            // 拖拽排序
          })
        })
      }
      .divider({ strokeWidth: 0.5, color: $r('app.color.divider') })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_base'))
  }
}
```

### 搜索贴纸

```typescript
@Component
struct SearchPage {
  @State keyword: string = '';
  @State results: Sticker[] = [];
  @State history: string[] = [];

  build() {
    Column() {
      HdsActionBar({
        startButtons: [
          { icon: $r('sys.symbol.chevron_left'), action: () => { this.pathStack.pop() } }
        ],
        customArea: () => {
          Search({ placeholder: '搜索贴纸', value: this.keyword })
            .width('100%')
            .height(40)
            .backgroundColor($r('app.color.search_bg'))
            .borderRadius(20)
            .onChange((v) => { this.keyword = v; })
        }
      })

      if (this.keyword.length === 0) {
        // 搜索历史
        Column() {
          Text('最近搜索').fontSize(14).fontColor($r('app.color.ink_mid')).margin(16)
          Wrap({ space: 8 }) {
            ForEach(this.history, (h: string) => {
              Text(h)
                .fontSize(12)
                .padding({ top: 4, bottom: 4, left: 10, right: 10 })
                .backgroundColor($r('app.color.chip_bg'))
                .borderRadius(12)
                .onClick(() => { this.keyword = h; })
            })
          }
          .padding(16)
        }
      } else {
        StickerGrid({ stickers: this.results })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_base'))
  }
}
```

### 贴纸详情

```typescript
@Component
struct StickerDetailPage {
  @Prop sticker: Sticker;

  build() {
    Column() {
      HdsActionBar({
        startButtons: [
          { icon: $r('sys.symbol.chevron_left'), action: () => { this.pathStack.pop() } }
        ],
        endButtons: [
          { icon: $r('sys.symbol.square_and_arrow_up'), action: () => { this.share(); } },
          { icon: $r('sys.symbol.trash'), action: () => { this.confirmDelete(); } }
        ]
      })

      // 大图预览
      Image(this.sticker.uri)
        .width('100%')
        .layoutWeight(1)
        .objectFit(ImageFit.Contain)
        .backgroundColor(Color.Black)

      // 信息卡片
      Column({ space: 0 }) {
        HdsListItemCard({
          textItem: { primaryText: { text: '分类', fontSize: 14 } },
          suffix: new SuffixText({ text: this.sticker.category })
        })
        HdsListItemCard({
          textItem: { primaryText: { text: '创建时间', fontSize: 14 } },
          suffix: new SuffixText({ text: this.formatDate(this.sticker.createdAt) })
        })
        HdsListItemCard({
          textItem: { primaryText: { text: '加入画布', fontSize: 14 } },
          suffix: new SuffixArrow()
        })
      }
      .padding(16)
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 20, topRight: 20 })
      .shadow({ radius: 16, color: 'rgba(0,0,0,0.08)', offsetY: -4 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_base'))
  }
}
```

### 我的页面

```typescript
@Component
struct ProfilePage {
  build() {
    Column() {
      HdsActionBar({
        primaryText: { text: '我的', fontSize: 18, fontWeight: FontWeight.Medium }
      })

      // 用户信息卡片（自定义，HDS 无专用用户卡片）
      Row({ space: 12 }) {
        Image($r('app.media.avatar'))
          .width(64)
          .height(64)
          .borderRadius(32)
        Column({ space: 4 }) {
          Text('Coffee Lover').fontSize(18).fontWeight(FontWeight.Medium)
          Text('VIP').fontSize(12).fontColor($r('app.color.brand_primary'))
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
      .borderRadius(16)
      .margin(16)
      .shadow({ radius: 12, color: 'rgba(26,26,26,0.06)', offsetY: 4 })

      // 统计卡片
      Row() {
        StatItem({ number: 128, label: '贴纸' })
        Divider().vertical(true).height(32).color($r('app.color.divider'))
        StatItem({ number: 16, label: '画布作品' })
        Divider().vertical(true).height(32).color($r('app.color.divider'))
        StatItem({ number: 48, label: '收藏' })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .padding(16)
      .backgroundColor(Color.White)
      .borderRadius(16)
      .margin({ left: 16, right: 16 })

      // 菜单列表：HdsListItemCard
      List() {
        ListItem() {
          HdsListItemCard({
            textItem: {
              primaryText: { text: '我的收藏', fontSize: 16 },
              primaryPrefixSymbol: { fontResource: $r('sys.symbol.heart') }
            },
            suffix: new SuffixArrow()
          })
        }

        ListItem() {
          HdsListItemCard({
            textItem: {
              primaryText: { text: '最近删除', fontSize: 16 },
              primaryPrefixSymbol: { fontResource: $r('sys.symbol.trash') }
            },
            suffix: new SuffixArrow()
          })
        }

        ListItem() {
          HdsListItemCard({
            textItem: {
              primaryText: { text: '设置', fontSize: 16 },
              primaryPrefixSymbol: { fontResource: $r('sys.symbol.gear') }
            },
            suffix: new SuffixArrow()
          })
        }

        ListItem() {
          HdsListItemCard({
            textItem: {
              primaryText: { text: '反馈与帮助', fontSize: 16 },
              primaryPrefixSymbol: { fontResource: $r('sys.symbol.questionmark_circle') }
            },
            suffix: new SuffixArrow()
          })
        }

        ListItem() {
          HdsListItemCard({
            textItem: {
              primaryText: { text: '关于我们', fontSize: 16 },
              primaryPrefixSymbol: { fontResource: $r('sys.symbol.info_circle') }
            },
            suffix: new SuffixArrow()
          })
        }
      }
      .divider({ strokeWidth: 0.5, color: $r('app.color.divider') })
      .margin({ top: 16 })
      .layoutWeight(1)
      .backgroundColor(Color.White)
      .borderRadius(16)
      .margin(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_base'))
  }
}
```

---

# 6. 异常状态（HDS 规范）

| 异常 | HDS 组件实现 |
|------|--------------|
| 未检测到主体 | 中央 `SymbolGlyph` (`xmark.circle`) + 标题文案 + 主按钮（HDS 按钮规范） |
| 主体模糊 | 同上，文案替换 |
| 多主体选择 | `CustomDialog`（HDS Dialog 风格：圆角 20，底部按钮组） |
| 抠图超时/失败 | **`HdsSnackBar`** 提示「处理失败，请重试」，带「重试」操作按钮 |
| 删除确认 | `AlertDialog`（HDS 风格） |
| 保存成功 | `HdsSnackBar` 提示「已保存到相册」 |

### HdsSnackBar 示例

```typescript
import { HdsSnackBar } from '@kit.UIDesignKit';

// 显示操作反馈
HdsSnackBar.show({
  message: '已保存到相册',
  action: {
    text: '查看',
    callback: () => { this.openAlbum(); }
  },
  duration: 3000
});
```

---

# 7. 技术方案（HarmonyOS API23 + HDS）

## 7.1 主体识别与抠图

| 能力 | API |
|------|-----|
| 主体分割 | `@kit.VisionKit` — `subjectSegmentation(image: PixelMap): SegmentationResult` |
| 图像分类（预留） | `@kit.VisionKit` — `imageClassification(image: PixelMap)` |

```typescript
import { visionKit } from '@kit.VisionKit';

const pixelMap: image.PixelMap = await pickPhoto();
const result = await visionKit.subjectSegmentation(pixelMap);
const mask: ArrayBuffer = result.mask;

// OffscreenCanvas 膨胀 + 白边
const offCanvas = new OffscreenCanvas(width, height);
const ctx = offCanvas.getContext('2d');
// ... 图像处理 ...
```

## 7.2 数据持久化

| 数据 | 存储方案 |
|------|----------|
| 贴纸/画布元数据 | `@ohos.data.relationalStore`（RDB） |
| 用户偏好 | `@ohos.data.preferences` |
| 图片文件 | 应用私有目录 `filesDir` |

## 7.3 状态管理架构

```text
AppStorage / PersistentStorage (全局)
    ├─ stickerListVersion: number
    ├─ currentCategory: string
    └─ useApi23Features: boolean

HdsTabs (根容器)
    ├─ TabContent 1: HomeNavStack
    │   └─ Navigation (NavPathStack)
    │       └─ HomePage (@State stickerList, selectedCategory)
    │
    ├─ TabContent 2: CanvasNavStack
    │   └─ Navigation
    │       └─ CanvasEditPage (@State canvasItems, backgroundConfig)
    │
    └─ TabContent 3: ProfileNavStack
        └─ Navigation
            └─ ProfilePage
```

## 7.4 HDS 组件清单与用途

| HDS 组件 | 使用位置 | 说明 |
|----------|----------|------|
| **`HdsTabs`** | 全局根容器（贴纸库/画布/我的） | API23 浮动样式 + 沉浸光感 |
| **`HdsTabsController`** | HdsTabs 控制器 | `applyMiniBarStyle` / `applyShowAnimation` / `applyHideAnimation` |
| **`HdsActionBar`** | 所有页面顶部操作栏 | startButtons / primaryText / endButtons，支持展开/折叠主按钮 |
| **`HdsListItemCard`** | 分类管理、我的页面菜单、贴纸详情信息 | 左图标 + 主文本 + 右箭头/开关/Badge |
| **`HdsSnackBar`** | 操作反馈（保存成功、删除撤销、超时提示） | 底部 brief notification + action |
| **`hdsMaterial`** | TabBar、ActionBar、工具栏背景 | `EXQUISITE` / `GENTLE` / `SMOOTH` |
| **`HdsDividerStyle`** | TabBar 分割线 | `VISIBLE` / `NONE` / `FOLLOW_SCROLL` |

## 7.5 API 版本兼容性

```typescript
import { deviceInfo } from '@kit.BasicServicesKit';
import { hdsMaterial, getSystemMaterialTypes } from '@kit.UIDesignKit';

@State useApi23: boolean = false;
@State materialEffect: hdsMaterial.Effect = hdsMaterial.Effect.SMOOTH;

async aboutToAppear(): Promise<void> {
  this.useApi23 = deviceInfo.sdkApiVersion >= 23;
  if (this.useApi23) {
    const types = getSystemMaterialTypes();
    this.materialEffect = types.includes(hdsMaterial.Type.IMMERSIVE)
      ? hdsMaterial.Effect.EXQUISITE
      : hdsMaterial.Effect.SMOOTH;
  }
}
```

## 7.6 性能优化策略

| 场景 | 策略 |
|------|------|
| 贴纸网格 | `Grid` + `LazyForEach` + `IDataSource` + `cachedCount(2)` |
| 画布元素 | `@Reusable` 复用 `CanvasElement` |
| 图片加载 | `Image` `syncLoad(false)` + placeholder |
| 列表滚动 | `List` / `Grid` `edgeEffect(EdgeEffect.Spring)` |
| 离屏渲染 | `OffscreenCanvas` 用于描边算法和画布导出 |

---

# 8. 数据模型（ArkTS 显式类型）

```typescript
// Sticker.ets
export interface Sticker {
  id: number;
  uri: string;
  category: string;
  createdAt: number;
  updatedAt: number;
  tags?: string[];
}

// CanvasItem.ets
export interface CanvasItem {
  id: string;
  type: 'sticker' | 'text';
  uri?: string;
  content?: string;
  x: number;
  y: number;
  scale: number;
  rotation: number;
  zIndex: number;
}

// CanvasProject.ets
export interface CanvasProject {
  id: number;
  title: string;
  thumbnailUri: string;
  items: CanvasItem[];
  background: BackgroundConfig;
  createdAt: number;
  updatedAt: number;
}

// BackgroundConfig.ets
export interface BackgroundConfig {
  type: 'color' | 'texture' | 'pattern' | 'image';
  value: string;
}

// Category.ets
export interface Category {
  id: number;
  name: string;
  icon: Resource;
  count: number;
  sortOrder: number;
}
```

---

# 9. HDS 设计系统适配（API23）

## 9.1 沉浸光感（Immersive Light Sensation）

应用位置：

- `HdsTabs` 浮动底栏：`systemMaterialEffect` + `barOverlap(true)` + `barBackgroundBlurStyle`
- `HdsActionBar` 标题栏：`barBackgroundBlurStyle` 或自定义背景模糊
- 画布底部工具面板：HDS 材质背景

降级策略：

```typescript
if (this.useApi23) {
  // API23：系统 Material 沉浸光感
  this.tabBarMaterial = hdsMaterial.Effect.EXQUISITE;
} else {
  // API20-22：纯色背景 + 基础模糊
  this.tabBarBg = $r('app.color.tab_bar_bg');
}
```

## 9.2 视觉规范（HDS Token）

| 元素 | 规范 |
|------|------|
| 卡片圆角 | `16vp`（大卡片）、`12vp`（网格项） |
| 卡片阴影 | `shadow({ radius: 12, color: 'rgba(26,26,26,0.06)', offsetX: 2, offsetY: 4 })` |
| 按钮 | 主按钮胶囊形（`ButtonType.Capsule`），高度 `48vp`，品牌色 |
| 字体 | 标题 `fontWeight(600)`，正文 `400`， whisper 标签 `300` + `opacity(0.5)` |
| 图标 | 优先 `SymbolGlyph`（`$r('sys.symbol.xxx')`） |
| 留白 | 页面边距 `16vp`，模块间距 `24vp` |

## 9.3 色彩 Token

```typescript
// constants/ThemeConstants.ets
export const BRAND_PRIMARY = '#6B5CE7';
export const BRAND_PRIMARY_LIGHT = '#F0EDFF';
export const BRAND_SECONDARY = '#FF6B9D';
export const BG_BASE = '#F8F8F6';
export const CARD_BG = '#FFFFFF';
export const INK_DEEP = '#1A1A1A';
export const INK_MID = '#666666';
export const INK_LIGHT = '#999999';
export const DIVIDER = '#E5E5E5';
export const SEARCH_BG = '#F2F2F2';
export const CHIP_BG = '#F2F2F2';
export const SHADOW_SOFT = 'rgba(26, 26, 26, 0.06)';
```

---

# 10. MVP 边界（不变）

## 包含

- 拍照 / 相册导入
- VisionKit 自动抠图 + 白边生成
- 贴纸库（Grid 浏览 + 分类过滤）
- 分类管理（HdsListItemCard + 拖拽排序）
- 简单画布（贴纸拖拽/缩放/旋转 + 文字 + 背景 + 图层）
- 导出 PNG/JPEG

## 不包含

- AI 生成贴纸 / 云同步 / 社区 / 多人协作 / 模板商城 / 账号系统 / 订阅系统 / 自动标签 / AI 分类

---

# 11. 北极星指标（不变）

| 指标 | 说明 |
|------|------|
| 用户累计生成贴纸数 | 北极星 |
| 平均贴纸收藏数 | 次级 |
| 平均画布创建数 | 次级 |
| 导出率 | 次级 |
| 7 日留存 | 次级 |

---

# 附录：HDS 组件速查表

| 组件 | 导入路径 | 起始版本 | 使用场景 |
|------|----------|----------|----------|
| `HdsTabs` | `@kit.UIDesignKit` | 6.0.0(20) | 根容器 TabBar、画布工具栏 |
| `HdsTabsController` | `@kit.UIDesignKit` | 6.0.0(20) | TabBar 显隐/折叠/展开控制 |
| `HdsActionBar` | `@kit.UIDesignKit` | 6.0.0(20) | 页面顶部操作栏 |
| `HdsListItemCard` | `@kit.UIDesignKit` | 6.0.0(20) | 列表卡片（分类/菜单/详情） |
| `HdsSnackBar` | `@kit.UIDesignKit` | 6.0.0(20) | 底部操作反馈提示 |
| `hdsMaterial` | `@kit.UIDesignKit` | 6.0.0(20) | 沉浸光感材质 |
| `HdsSideBar` | `@kit.UIDesignKit` | 6.0.0(20) | 侧边栏（大屏场景预留） |
| `HdsSideMenu` | `@kit.UIDesignKit` | 6.0.0(20) | 侧边菜单（大屏场景预留） |

---

> **修正说明（v0.3 → v0.4）**：
> 1. **全局根容器**由 `Navigation` 改为 **`HdsTabs`**，作为 Page 级根视图容器承载三大主模块。
> 2. **所有页面顶部操作栏**统一使用 **`HdsActionBar`**，替代自定义 `Row` + `Text` + `SymbolGlyph` 拼凑。
> 3. **所有列表/菜单场景**统一使用 **`HdsListItemCard`**（分类管理、我的页面、贴纸详情信息区），替代自定义 `Row` 列表项。
> 4. **操作反馈**统一使用 **`HdsSnackBar`** 替代 `PromptAction.showToast`。
> 5. **画布底部工具栏**使用 **`HdsTabs`** 横向模式承载贴纸/文字/背景/调整四大工具。
> 6. 补充 **`HdsTabsController`** 动效控制（`applyMiniBarStyle` / `applyShowAnimation` / `applyHideAnimation`）。
> 7. 明确 **`hdsMaterial`** 在 `HdsTabs` 浮动底栏、`HdsActionBar`、画布工具栏上的应用位置。
> 8. 保留 API23 特性：浮动 Tab Bar、沉浸光感、Attach/Detach、List/Grid 长按聚合、Navigation 分栏、Parallel View。
