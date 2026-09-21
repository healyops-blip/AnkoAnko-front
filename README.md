# AnkoAnko

AnkoAnko 是一个 Flutter 多平台应用。本仓库将应用代码、技术文档和团队协作说明分开管理，便于多人共同开发。

## 仓库结构

```text
.
├── app/       # 完整的 Flutter 应用
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
