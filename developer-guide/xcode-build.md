# Xcode 构建指南

## 1. 准备 Flutter 工程

从仓库根目录执行：

```bash
cd app
flutter pub get
flutter doctor
```

`flutter pub get` 会生成 Xcode 构建所需的 Flutter 配置。移动工程目录或重新拉取仓库后，应先执行一次。

## 2. 打开正确的工程

从仓库根目录执行：

```bash
open app/ios/Runner.xcworkspace
```

必须打开 `Runner.xcworkspace`，不要直接打开 `Runner.xcodeproj`。

## 3. 编译并运行模拟器版本

1. 在 Xcode 顶部选择 `Runner` Scheme。
2. 选择一个 iPhone 模拟器，例如 `iPhone 17e`。
3. 按 `Command + B` 仅编译应用。
4. 按 `Command + R` 编译、安装并运行应用。

Xcode 的 Run 操作默认使用 Debug 配置。

## 4. 清理构建缓存

发生依赖图、构建服务或旧路径错误时：

1. 执行 `Product → Clean Build Folder`，快捷键为 `Shift + Command + K`。
2. 关闭并重新打开 `Runner.xcworkspace`。
3. 仍然失败时，在 `Xcode → Settings → Locations → Derived Data` 中打开缓存目录，删除本项目对应的 `Runner-*` 缓存。
4. 返回 `app/` 执行 `flutter clean` 和 `flutter pub get`，然后重新打开 Xcode。

## 5. 真机运行

1. 连接并信任 iPhone。
2. 在 Xcode 中打开 `Runner → Signing & Capabilities`。
3. 选择团队的 Apple Developer Team。
4. 确认 Bundle Identifier 在该团队中唯一。
5. 选择连接的 iPhone，然后按 `Command + R`。

模拟器不需要开发者签名，真机运行需要有效的签名配置。

## 6. Release 归档

1. 配置 `Runner → Signing & Capabilities → Team`。
2. 将目标设备切换为 `Any iOS Device`。
3. 选择 `Product → Archive`。
4. 构建完成后，在 Organizer 中选择 `Distribute App`。
5. 根据用途选择 App Store Connect、Ad Hoc 或 Development 分发方式。

Archive 使用 Release 配置，不能以普通 iPhone 模拟器作为归档目标。

## 7. 命令行验证

如果需要判断问题来自 Flutter 工程还是 Xcode 图形界面，可以在 `app/` 中执行：

```bash
flutter build ios --simulator
```

模拟器构建产物位于：

```text
app/build/ios/iphonesimulator/Runner.app
```

构建正式 IPA 时使用：

```bash
flutter build ipa
```

正式 IPA 构建同样需要正确的 Apple Developer 签名配置。
