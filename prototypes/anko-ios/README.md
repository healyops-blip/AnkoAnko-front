# Anko · iOS 家庭守护

按参考图的白灰与 Anker 蓝重新设计，使用参考 IP 重绘的蓝色角色替换原黑豹，原始 HTML 未修改。

## 查看

直接双击工程内的 `Anko-iOS.html`，无需联网。桌面显示手机预览，手机显示全屏应用布局。

## HTML 与 iOS 同步

唯一页面源文件是 `Anko/Resources/Web/index.html`，已内嵌实时 3D 角色程序及渲染库，可单独复制分享。工程内 `Anko-iOS.html` 是指向此文件的相对文件链接；HTML 与 iOS 读取同一份内容。

后续修改请编辑这个源文件，避免另存覆盖文件链接。浏览器刷新即可看到修改；Xcode 再次 Run 时会自动打包最新页面。已经安装的应用需要重新编译安装才能更新。两端共享设计和交互代码，本地演示记录不互相同步。

该目录为独立原型，不替换仓库的 Flutter app。对外分享副本不会自动跟随源工程更新。

## iOS 应用

打开 `Anko.xcodeproj`，选择 Anko scheme 和 iPhone 模拟器运行。真机运行需在 Signing & Capabilities 中选择自己的开发团队及可用的 Bundle ID。

实现采用 UIKit 原生导航/开关/分段控件 + 共享本地 WKWebView 内容，由 SwiftUI 承载。完整保留 HTML 的交互状态与流程，并非全部用 SwiftUI 重写。最低 iOS 17，竖屏，支持白色 / 黑色主题。页面、模型代码与渲染库均打包在应用中，可离线使用。

## 已保留功能

数字家园和地图事件、风险认领/提交/复核、家庭留言、照片便签、IP 成长与奖励防重复、房间隐私、家庭设置、榜单与分享模拟。紧急事件演示入口位于“我的”底部。

所有设备、事件、分数和分享都是本机演示，未接入摄像头、语音 AI、真实家庭消息服务。照片仅本次运行预览，不持久保存。

## 视觉资源

`Anko/Resources/Web/assets/anko.png` 由内置 image_gen 基于用户提供的 1.png 生成，透明背景。最终提示词见 `asset-prompt.txt`。

## 验证

Xcode 27 / iPhone 17 Pro iOS 27 模拟器编译运行成功，当前截图见 `Design/character-3d-light.png` 与 `Design/character-3d-dark-home.png`。交互回归记录见 `Design/character-3d-verification.txt`。

## 外观主题与图标

“我的”顶部提供白色、黑色主题预览与切换。选择即时应用到所有页面并在本机保存；重新启动会恢复。iOS 状态栏和原生容器同步变化。HTML 与 iOS 的主题偏好分别保存在各自设备上。应用图标使用 Anko 角色，资源位于 `Anko/Assets.xcassets/AppIcon.appiconset`。

## Apple Liquid Glass

iOS 端底部使用原生 UITabBarController；所有布尔开关使用 UISwitch，主题与场景使用 UISegmentedControl。未自绘原生材质，未覆盖系统标签栏背景。iOS 26 及以上由系统提供 Liquid Glass，iOS 17–18 使用相应系统外观。

开关范围：Anko 巡游、设备覆盖图层、减少动态效果、卧室隐私，以及参榜/公开方案/分区示意/接力方法四个分享选项。隐私保留确认流程，分享开关只修改草稿。

HTML 预览保持相同状态、控件语义与布局，并提供玻璃胶囊、选中滑块和拖动交互。网页效果是近似表现，不能提供苹果系统的真实 Liquid Glass 光学材质。页面代码和内容仍共用一份，原生控件通过桥接同步。

官方依据：https://developer.apple.com/videos/play/wwdc2025/284/ 和 https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass 。

## 实时 3D Anko（2026-09-21）

当前角色由三维网格和分层关节构成，按参考图重建，造型细节与原图有所差异。运行时不再使用表情图片或帧序列。头部、耳朵、肩、肘、髋、腿和眼睛分别受连续参数驱动，身体重心与目光使用弹簧积分平滑过渡。

- 轻触：产生有幅度变化的身体弹性与手臂回应，保留短句反馈。
- 按住拖动：实时跟随目标位置；脚步相位取决于移动速度，松手后减速停下。
- 视线：跟随触点；空闲时以不同间隔转头、眨眼、呼吸。
- 键盘：聚焦角色后使用左右方向键移动，回车或空格摸摸。
- 主题、任务与演示提醒：连续混合安静、开心、关注的面部与身体参数。
- 家园巡游：小角色在地图上移动并摆动手脚；关闭巡游或减少动态时停止。

互动属于本地实时角色控制，并未接入自主 AI 或真实设备。业务状态仍为同一份共享 HTML。减少动态设置和系统减少动态偏好会关闭角色的持续运动，保留即时表情与文字。应用进入后台停止更新。运行需要 WebGL 2；无法启动时显示说明，不回退到照片切换。

源代码位于 `Character/character.js`（模型、渲染、输入）和 `Character/motion.mjs`（运动计算）。修改后在 Character 目录运行 `npm ci`、`npm run build`，将程序重新内嵌到共享 HTML，再在 Xcode 运行。`npm test` 检查连续转向、停止、快速点击边界、表情混合和减少动态。依赖版本固定在 package-lock.json；Three.js 授权见 THREE-LICENSE.txt。渲染 API 依据：https://threejs.org/docs/pages/WebGLRenderer.html 。

旧 PNG 保留为设计参考，应用图标仍为 Anko。当前运行中的角色不读取这些 PNG。

已移除幸福指数、详情入口及便签加分文案。首页保留安全值和空间完整两项；便签回应及 Anko 开心反馈保留。

## 模型细化更新

角色现使用 `Character/model/anko-refined.glb`，包含融合后的头罩与耳朵、连续的身体和四肢、七根驱动骨骼与蒙皮，以及曲面脸框、虹膜、闭眼曲线、笑口和贴合胸口的闪电。实时动作仍由运动控制器计算。材质、头身比例和手脚轮廓重新校准，运行模型不会切换角色图片。

可编辑 Blender 源文件和重建脚本保存在 `Character/model`；模型结构、权重归一化、脚部隔离及手臂变形测试纳入 `npm test`。当前预览见 `Design/character-refined-front.png` 与 `Design/character-refined-turn.png`。这仍是根据参考图重建的模型，不代表已与品牌原始模型完全一致。
