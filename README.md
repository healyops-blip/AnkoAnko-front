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

## Flutter Smoke 调试

前端始终使用同一套 Flutter 代码，通过编译参数切换 Smoke 内存数据和 Go 后端接口。Smoke 模式不会请求网络，也不会写入本地数据库；应用重启后，调试过程中产生的数据会重置。

```bash
cd app
flutter pub get
flutter run --dart-define=ANKO_SMOKE_MODE=true
```

Smoke 模式启动后，界面右上角会显示橙色 `SMOKE` 标识。家庭码为 `DEVANKO1`，三个开发者账号共用验证码 `123456`：

| 身份 | 手机号 | Anko 账号 | 权限 |
| --- | --- | --- | --- |
| 妈妈 | `13800001001` | `dev_mom` | 家庭管理员：可邀请和编辑成员、管理家庭、设备、房间及隐私设置，也可处理紧急事件 |
| 奶奶 | `13800001002` | `dev_grandma` | 普通成员：可查看和联系家人、处理普通事件，并设置个人紧急联系人；不可管理家庭、设备、房间及隐私设置 |
| 孩子 | `13800001003` | `dev_child` | 受限成员：不可管理家庭、发起呼叫、查看事件证据或认领事件 |

开发账号和验证码只写在开发文档中，不会展示在登录注册界面。

连接 Go 后端时关闭 Smoke 模式并传入接口地址：

```bash
flutter run \
  --dart-define=ANKO_SMOKE_MODE=false \
  --dart-define=ANKO_API_BASE_URL=http://127.0.0.1:8080
```

正式接口模式不会自动回退到 Smoke 数据；未配置接口地址时，应用会显示配置错误。字段和接口约定参见 [Smoke 模式说明](docs/smoke-mode.md) 与 [Go API 契约](docs/go-api-contract.md)。

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

原型包含黑白主题、iOS 原生 Liquid Glass 控件、实时角色跟随与关节运动，并已移除幸福指数。Flutter `app/` 已包含登录注册、守护和联系家人等正式前端流程；原型继续作为交互与视觉参考。
