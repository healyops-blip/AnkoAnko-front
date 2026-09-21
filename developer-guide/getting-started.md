# 环境搭建

## 必要工具

- Flutter SDK
- Git
- Google Chrome（开发或构建 Web 时）
- Xcode（仅开发、构建或发布 iOS/macOS 时需要）
- Android Studio 或 Android SDK（仅开发 Android 时需要）

## 获取并运行项目

```bash
git clone <repository-url>
cd Ankoanko-front/app
flutter doctor
flutter pub get
flutter run
```

没有 Xcode 时，请使用 Chrome 作为运行目标：

```bash
flutter run -d chrome
```

Web 开发与 Release 构建不依赖 Xcode，完整流程请参阅 [Web 构建指南（无需 Xcode）](web-build.md)。Chrome 可以模拟 iPhone 尺寸，但不能替代真实的 iOS、Safari/WebKit 或签名发布测试。

## 使用 Xcode

从仓库根目录执行：

```bash
open app/ios/Runner.xcworkspace
```

不要直接打开 `Runner.xcodeproj`。在 Xcode 顶部选择 `Runner` Scheme 和目标模拟器，然后按 `Command + R`。

完整流程请参阅 [Xcode 构建指南](xcode-build.md)。
