# 协作流程

## 开始开发

从最新的 `main` 分支创建独立功能分支：

```bash
git switch main
git pull
git switch -c feature/short-description
```

推荐的分支前缀：

- `feature/`：新功能
- `fix/`：问题修复
- `docs/`：文档调整
- `refactor/`：不改变行为的代码整理

## 提交前检查

```bash
cd app
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

提交应保持范围清晰，并使用能够说明变更目的的信息。

## 合并代码

1. 将分支推送到 GitHub。
2. 创建 Pull Request，说明修改内容和验证方式。
3. 至少由另一位成员完成 Review。
4. 测试通过并解决评论后再合并。

不要直接向 `main` 推送未经检查的功能代码，也不要提交构建产物、IDE 用户配置、证书或环境密钥。
