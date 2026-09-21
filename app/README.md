# Flutter 应用

此目录包含完整的 AnkoAnko Flutter 工程，包括 Dart 源码、测试和各平台工程。

## 常用命令

所有命令均在本目录执行：

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## iOS / Xcode

```bash
open ios/Runner.xcworkspace
```

在 Xcode 中选择 `Runner` Scheme 和目标模拟器，然后使用 `Command + R` 运行。

完整的编译、签名和归档流程请参阅 [Xcode 构建指南](../developer-guide/xcode-build.md)。

## Web（无需 Xcode）

```bash
flutter run -d chrome
flutter build web
```

没有 Xcode 的开发者也可以完成 Web 调试和 Release 构建。完整流程和能力限制请参阅 [Web 构建指南](../developer-guide/web-build.md)。

## 主要目录

```text
app/
├── lib/       # Dart 应用源码
├── test/      # 自动化测试
├── ios/       # iOS 工程
├── android/   # Android 工程
├── macos/     # macOS 工程
├── web/       # Web 工程
├── linux/     # Linux 工程
└── windows/   # Windows 工程
```
