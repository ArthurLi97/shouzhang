# SnapSticker · 手账贴纸

> 把生活收集成贴纸。

SnapSticker 是一款 HarmonyOS 原生应用，通过拍照将现实世界中的物体自动抠图生成贴纸，在画布中自由组合创作，形成属于自己的视觉手账。

## 产品截图

![原型图](prototype.png)

## 核心功能

| 功能 | 描述 |
|------|------|
| 📷 拍照/相册导入 | 一键拍照或从相册选择图片 |
| ✂️ 智能抠图 | 基于 VisionKit 自动识别主体并抠图 |
| 🎨 贴纸编辑 | 白边、阴影、亮度/对比度/饱和度调整 |
| 🗂️ 贴纸库 | 分类管理（咖啡、美食、花草、宠物等） |
| 🖼️ 画布创作 | 拖拽、缩放、旋转贴纸，添加文字和背景 |
| 💾 导出分享 | 保存到相册、透明背景 PNG、社交分享 |

## 技术栈

- **平台**: HarmonyOS 6.1.0+ (API 23)，兼容 API 24
- **语言**: ArkTS (Strict Mode)
- **UI 框架**: ArkUI + HDS (HarmonyOS Design System)
- **设计体系**: 沉浸光感 (Immersive Light Effects)
- **AI 能力**: `@kit.VisionKit` — 主体分割、图像分类
- **相机**: `@kit.CameraKit` — 拍照选取
- **相册**: `@kit.MediaLibraryKit` — 相册读写
- **数据存储**: RDB (`relationalStore`) + Preferences

## 项目结构

```
entry/src/main/ets/
├── entryability/           # 入口 Ability
├── entrybackupability/     # 备份恢复 Ability
├── pages/                  # 页面
│   ├── Index.ets           # 根页面 (HdsTabs 容器)
│   ├── home/               # 贴纸库模块
│   └── canvas/             # 画布创作模块
├── components/             # 可复用组件
│   ├── hds/                # HDS 风格封装组件
│   ├── canvas/             # 画布相关组件
│   ├── CategoryScrollBar.ets
│   ├── ConfettiCanvas.ets
│   ├── EmptyStateView.ets
│   ├── NewStickerCard.ets
│   ├── PrivacyDialog.ets
│   ├── StickerDataSource.ets
│   └── StickerGrid.ets
├── models/                 # 数据模型
├── database/               # 数据库 & 偏好设置
├── utils/                  # 工具类
│   ├── CanvasExporter.ets
│   ├── ImageProcessor.ets
│   └── PermissionManager.ets
└── constants/              # 主题常量
```

## 页面清单

| 页面 | 路径 |
|------|------|
| 根页面（Tab 容器） | `pages/Index.ets` |
| 首页（贴纸库） | `pages/home/HomePage.ets` |
| 智能抠图中 | `pages/home/ProcessingPage.ets` |
| 贴纸编辑 | `pages/home/StickerEditPage.ets` |
| 加入收藏成功 | `pages/home/SaveSuccessPage.ets` |
| 贴纸详情 | `pages/home/StickerDetailPage.ets` |
| 分类贴纸库 | `pages/home/CategoryPage.ets` |
| 分类管理 | `pages/home/CategoryManagePage.ets` |
| 搜索贴纸 | `pages/home/SearchPage.ets` |
| 未检测到主体 | `pages/home/NoSubjectPage.ets` |
| 主体模糊 | `pages/home/BlurSubjectPage.ets` |
| 多主体选择 | `pages/home/MultiSubjectSelectPage.ets` |
| 画布背景 | `pages/home/BackgroundPage.ets` |
| 隐私政策 | `pages/home/PrivacyPolicyPage.ets` |
| 用户协议 | `pages/home/UserAgreementPage.ets` |
| 设置 | `pages/home/SettingsPage.ets` |
| 画布创作 | `pages/canvas/CanvasEditPage.ets` |
| 画布背景 | `pages/canvas/BackgroundPage.ets` |
| 导出分享 | `pages/canvas/ExportPage.ets` |

## 启动方式

使用 DevEco Studio 打开项目，点击运行按钮部署到 HarmonyOS 模拟器或真机。

## 相关文档

- [产品规格说明书](spec.md) — 完整的产品功能规格
- [开发 Skill](SKILL.md) — HarmonyOS API 23 + HDS 开发最佳实践
