# NewsReaderApp

一个基于 GitHub API 的 iOS 新闻阅读应用，支持用户登录、搜索 GitHub 热门仓库、生物识别登录等功能。

## 📱 功能特性

### 核心功能
- ✅ 用户登录/注册（支持 Face ID / Touch ID）
- ✅ 首页展示 GitHub 热门仓库
- ✅ 搜索 GitHub 仓库
- ✅ 个人资料管理
- ✅ 退出登录

### 技术特性
- ✅ 未登录可浏览首页
- ✅ 安全存储（Keychain）
- ✅ 深色/浅色模式自适应
- ✅ 统一错误处理
- ✅ iPad 适配

## 📷 截图
Simulator Screenshot - iPhone 17 Pro Max - 2026-04-03 at 14.57.04.png
Simulator Screenshot - iPhone 17 Pro Max - 2026-04-03 at 14.56.51.png
Simulator Screenshot - iPhone 17 Pro Max - 2026-04-03 at 14.57.34.png
Simulator Screenshot - iPhone 17 Pro Max - 2026-04-03 at 14.57.49.png
Simulator Screenshot - iPhone 17 Pro Max - 2026-04-03 at 14.57.58.png

| 首页 | 搜索 | 个人资料 |
|------|------|----------|
| ![首页](Screenshots/HomePage.png) | ![搜索](Screenshots/SearchPage.png) | ![个人资料](Screenshots/ProfilePage.png) |

| 登录页 | 深色模式 |
|--------|----------|
| ![登录](Screenshots/LoginPage.png) | ![深色模式](Screenshots/DarkMode.png) |

## 🛠 技术栈

| 技术 | 说明 |
|------|------|
| **语言** | Swift 5.9+ |
| **UI 框架** | UIKit + SnapKit |
| **最低版本** | iOS 14.0 |
| **架构** | Protocol Oriented Programming |
| **网络** | URLSession + GitHub API |
| **存储** | Keychain + UserDefaults |
| **测试** | XCTest (Unit Tests + UI Tests) |

## 📦 依赖库

| 库 | 用途 | 版本 |
|----|------|------|
| [SnapKit](https://github.com/SnapKit/SnapKit) | 自动布局 | 5.7.0+ |

## 🚀 快速开始

### 环境要求
- Xcode 14.0+
- iOS 14.0+
- Swift 5.9+

### 安装步骤

1. **克隆项目**
```bash
git clone https://github.com/John-sudo-maker/Reader.git
cd NewsReaderApp
