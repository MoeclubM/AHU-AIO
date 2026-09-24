# AHU-AIO

安徽大学校园多合一客户端。课表、成绩、一卡通、通知，一个 App 搞定。

[![Release](https://img.shields.io/github/v/release/MoeclubM/AHU-AIO)](https://github.com/MoeclubM/AHU-AIO/releases)
[![License](https://img.shields.io/github/license/MoeclubM/AHU-AIO)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)

## 功能

| 模块 | 说明 |
|------|------|
| 课表 | 周次切换、当前周高亮、过滤未知课程 |
| 成绩 / 培养方案 | 教务与微教务双通道查询 |
| 一卡通 | 一码通支付、余额查询、充值 |
| 空闲教室 | 按校区 / 教学楼 / 时段检索 |
| 通知公告 | 教务通知与校内公告同步 |

界面提供 **Miuix（HyperOS）** 与 **Material 3** 双风格，支持动态取色、液态玻璃与 AMOLED。

## 安装

从 [Releases](https://github.com/MoeclubM/AHU-AIO/releases) 下载最新 `AHU-AIO-Beta-Android-arm64.apk` 安装到 Android 设备。

**登录**

| 入口 | 凭据 |
|------|------|
| 微教务 / 一卡通 | 统一身份认证（学号） |
| 安大教务 | 教务系统账号密码（失效会引导重登） |

## 开发

```bash
# 依赖
flutter pub get

# 运行
flutter run

# 静态检查（提交前请确保通过）
flutter analyze

# 测试
flutter test
```

要求：Flutter `>=3.44`，Dart `>=3.12`。

发布流程见 [CI 说明](.github/CI_README.md)。

## 贡献

Issue / PR 均欢迎。改代码前请跑通 `flutter analyze` 与 `flutter test`。
