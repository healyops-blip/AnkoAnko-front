# AnkoAnko

AnkoAnko 是一个 Flutter 多平台应用。本仓库将应用代码、技术文档和团队协作说明分开管理，便于多人共同开发。

## 仓库结构

```text
.
├── app/       # 完整的 Flutter 应用
├── prototypes/anko-ios/ # Anko iOS + HTML 实时 3D 交互原型
├── docs/      # 架构、需求和技术设计文档
├── developer-guide/ # 开发者环境、构建及协作指南
├── .gitignore
└── README.md  # 仓库首页
```

## 快速开始

```bash
cd app
flutter pub get
flutter run
```

更多说明：

- [环境搭建](developer-guide/getting-started.md)
- [Web 构建指南（无需 Xcode）](developer-guide/web-build.md)
- [Xcode 构建指南](developer-guide/xcode-build.md)
- [协作流程](developer-guide/collaboration.md)
- [技术文档索引](docs/README.md)
- [Flutter 应用说明](app/README.md)

## 基本检查

提交代码前，请在 `app/` 中执行：

```bash
flutter analyze
flutter test
```

## Anko 交互原型

[查看原型说明](prototypes/anko-ios/README.md)：包含可离线运行的 HTML、Xcode 工程和实时 3D 角色源代码。

- 网页：克隆后打开 `prototypes/anko-ios/Anko-iOS.html`。
- iOS：打开 `prototypes/anko-ios/Anko.xcodeproj`，选择 Anko 与 iPhone 模拟器运行。
- 角色开发：在 `prototypes/anko-ios/Character` 执行 `npm ci && npm test && npm run build`。

原型包含黑白主题、iOS 原生 Liquid Glass 控件、实时角色跟随与关节运动，并已移除幸福指数。Flutter `app/` 保持独立，尚未迁移这些界面与角色功能。
