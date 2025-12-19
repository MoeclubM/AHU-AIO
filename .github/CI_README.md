# CI/CD 配置说明

## 概述

本项目配置了基于 GitHub Actions 的完整 CI/CD 流程，支持自动化构建、测试和发布。

## 工作流文件

- **主要工作流**: `.github/workflows/main.yml`
  - 触发条件: 推送 `v*` 标签或手动触发
  - 功能: 测试 → 构建 → 发布

## 快速开始

### 发布新版本

```bash
# 方法 1: 使用发布脚本
./scripts/release.sh 1.0.0

# 方法 2: 使用 Makefile
make release VERSION=1.0.0

# 方法 3: 手动创建标签
git tag v1.0.0
git push origin v1.0.0
```

### 手动触发

1. 进入 GitHub 仓库的 Actions 页面
2. 选择 "Build and Release" 工作流
3. 点击 "Run workflow"
4. 输入版本号（如：v1.0.0）
5. 点击 "Run workflow"

## 工作流程

### 1. 版本提取
- 从标签提取版本号（如：v1.0.0 → 1.0.0）
- 生成变更日志

### 2. 测试阶段
- 运行单元测试
- 代码格式检查
- 静态分析
- 生成覆盖率报告

### 3. 构建阶段
并行构建以下平台:
- Android (arm64, x86_64)
- Linux (x86_64)
- Windows (x64)
- macOS (universal)

### 4. 发布阶段
- 创建 GitHub Release
- 上传所有构建产物
- 生成发布说明

## 文件结构

```
.github/workflows/main.yml    # CI 工作流配置
scripts/release.sh            # 发布脚本
Makefile                      # Make 命令
RELEASE_PROCESS.md            # 详细发布文档
QUICK_RELEASE.md              # 快速参考
CI_ENHANCEMENT_SUMMARY.md     # 实施总结
```

## 环境变量

无需要配置的环境变量。所有配置均在 `main.yml` 中硬编码。

## 权限要求

GitHub Token 需要以下权限:
- `contents: write` - 创建发布
- `actions: read` - 读取工作流状态

## 故障排除

### 构建失败
1. 检查 Actions 日志
2. 查看具体错误信息
3. 修复后重新推送标签

### 测试失败
1. 本地运行 `flutter test`
2. 修复失败的测试
3. 提交更改

### 产物未上传
1. 检查构建是否成功
2. 验证 artifact 路径
3. 查看 release 步骤日志

## 维护

### 更新 Flutter 版本
编辑 `.github/workflows/main.yml` 中的 `FLUTTER_VERSION` 环境变量。

### 修改构建配置
编辑 `main.yml` 中对应的构建作业。

### 添加新平台
1. 在 `main.yml` 中添加新的构建作业
2. 在发布阶段添加新的 artifact

## 监控

- 查看 Actions 页面监控 CI 状态
- 检查 GitHub Releases 页面确认发布
- 监控 Codecov 报告了解代码覆盖率

## 参考资料

- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Flutter 构建文档](https://docs.flutter.dev/deployment)
- [softprops/action-gh-release](https://github.com/softprops/action-gh-release)
