# Web 构建指南（无需 Xcode）

## 适用对象与能力边界

本指南面向没有安装 Xcode，或使用 Windows、Linux 的开发者。Flutter Web 的开发、Chrome 调试、自动化测试和 Release 构建均不需要 Xcode。

没有 Xcode 时可以完成：

- 在 Chrome 中运行和调试 Flutter Web 应用
- 构建可部署的 Web Release 产物
- 使用 Chrome 预览 iPhone 尺寸下的响应式布局
- 执行 Dart 格式检查、Flutter 静态分析和 Widget 测试

没有 Xcode 时不能完成：

- 运行 iOS 模拟器或生成 iOS `.app`
- 构建、签名或发布 `.ipa`
- 验证真实 iPhone、iOS 系统能力或 Safari/WebKit 专属行为

Chrome 的 iPhone 设备模式只是尺寸和响应式布局预览，不等同于真实 iOS 环境。需要交付 iOS 应用时，必须由配备 macOS 和 Xcode 的开发者或 macOS CI 环境执行 [Xcode 构建流程](xcode-build.md)。

## 1. 准备环境

安装 Flutter SDK 和 Google Chrome，然后从仓库根目录执行：

```bash
cd app
flutter doctor
flutter pub get
flutter devices
```

`flutter devices` 的结果中应包含 `Chrome (web)`。

如果没有启用 Web 支持，可以执行：

```bash
flutter config --enable-web
```

重新打开终端后再次运行 `flutter devices`。

## 2. 在 Chrome 中调试

所有 Flutter 命令均从 `app/` 目录执行：

```bash
flutter run -d chrome
```

Flutter 会启动本地开发服务器并打开 Chrome。终端中常用操作：

- `r`：热重载
- `R`：热重启
- `q`：停止运行

也可以指定调试服务器端口：

```bash
flutter run -d chrome --web-port 8080
```

然后访问 `http://localhost:8080`。

## 3. 编译 Release 版本

```bash
flutter build web --release
```

构建产物位于：

```text
app/build/web/
```

部署时需要上传 `build/web/` 里面的全部内容，而不是上传 `web/` 源码目录。

## 4. 使用 iPhone 尺寸预览

仅执行 `flutter build web` 或在 IDE 中选择“编译”，只会生成 Web 构建产物，不会自动打开手机预览。使用下面的命令可以自动打开 Chrome，但首次仍需在 Chrome 中手动开启设备模式：

先启动 Chrome 调试：

```bash
flutter run -d chrome
```

Chrome 快捷键：

| 操作 | macOS | Windows |
| --- | --- | --- |
| 打开开发者工具 | `Command + Option + I` | `Ctrl + Shift + I` 或 `F12` |
| 开启或关闭设备工具栏 | `Command + Shift + M` | `Ctrl + Shift + M` |

开启设备工具栏后，在设备下拉菜单中选择任意 iPhone 型号；若需手动设置，推荐使用 `393 × 852` 作为常用 iPhone 竖屏视口。Chrome 通常会记住上次选择的设备模式，但这属于浏览器设置，不是 Flutter 编译流程的一部分。

项目的 `web/index.html` 已配置移动端 viewport 和 iOS 安全区适配，页面会按手机实际宽度渲染，而不是缩放桌面布局。

## 5. 本地预览 Release 产物

不要直接双击 `build/web/index.html`，应通过 HTTP 服务器预览。从 `app/` 目录执行：

```bash
python3 -m http.server 8080 --directory build/web
```

然后访问 `http://localhost:8080`。

## 6. 部署到子路径

如果网站不是部署在域名根目录，而是类似 `https://example.com/ankoanko/` 的子路径，需要在构建时设置 base href：

```bash
flutter build web --release --base-href /ankoanko/
```

`--base-href` 必须以 `/` 开头并以 `/` 结尾，且应与实际部署路径一致。

例如 GitHub Pages 项目站点通常使用仓库名作为子路径：

```bash
flutter build web --release --base-href /仓库名/
```

## 7. 发布前检查

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release
```

在 Chrome 中检查：

- 页面能否正常加载和刷新
- 浏览器控制台是否存在错误
- 手机和桌面宽度下布局是否正常
- 图片、字体和其他资源路径是否正确
- 浏览器前进、后退及页面路由是否正常

## 8. 常见问题

### Chrome 没有出现在设备列表

确认 Chrome 已安装，并执行：

```bash
flutter config --enable-web
flutter doctor
flutter devices
```

### 修改代码后页面没有更新

先在运行 Flutter 的终端按 `R` 热重启。仍未更新时，停止进程并重新执行 `flutter run -d chrome`。

### 部署后出现白屏或资源 404

检查部署路径与 `--base-href` 是否一致，并确认上传的是 `build/web/` 中的全部文件。

### 刷新子页面返回 404

这是 Web 服务器的路由回退配置问题。服务器需要将未知的前端路由回退到 `index.html`，具体配置取决于使用的托管平台。
