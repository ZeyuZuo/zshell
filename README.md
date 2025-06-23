# ZShell - SSH连接管理工具

一个基于Flutter开发的跨平台SSH连接管理shell工具应用，采用Material3设计风格，提供直观的左右分栏界面布局。developed by augment.

## 🚀 项目概述

ZShell是一个现代化的SSH连接管理工具，旨在简化服务器连接管理和日常运维工作。通过直观的图形界面，用户可以轻松管理多个SSH连接、执行常用命令、记录笔记，并获得AI辅助支持。

## ✨ 主要功能

### 🖥️ 主机列表管理
- 📋 显示和管理SSH连接的服务器列表
- ➕ 支持添加、编辑、删除主机配置
- 🔄 实时显示主机连接状态（在线/离线）
- ⚡ 快速连接到选定的主机
- 🔐 安全存储连接参数（IP地址、端口、用户名、密钥等）
- 📑 标签页形式管理多个并发连接

### 🤖 AI助手
- 💬 集成AI辅助功能，提供智能建议
- 🔍 命令解释和故障排查支持
- 📚 知识库查询和技术文档推荐

### ⚡ 快捷指令
- 📝 存储和管理常用的shell命令
- 🏷️ 命令分类和标签管理
- 🔄 一键执行常用操作
- 📋 命令历史记录

### 📝 笔记管理
- 📖 记录和管理运维相关笔记
- 🔗 与特定主机关联的笔记
- 🏷️ 标签和分类系统
- 🔍 全文搜索功能

### ⚙️ 设置中心
- 🎨 应用主题和外观配置
- 🔐 安全设置和密钥管理
- 🌐 网络和连接配置
- 📱 跨平台同步设置

## 🏗️ 技术架构

### 前端框架
- **Flutter**: 跨平台UI框架
- **Material3**: 现代化设计系统
- **响应式设计**: 适配不同屏幕尺寸

### 状态管理
- **Provider/Riverpod**: 全局状态管理
- **MVVM架构**: 清晰的代码组织结构

### 数据存储
- **SQLite**: 本地数据库存储
- **Hive**: 轻量级键值存储
- **加密存储**: 敏感信息安全保护

### SSH连接
- **dart:io**: 原生进程管理
- **SSH库**: 安全连接实现
- **密钥管理**: 支持多种认证方式

## 🛠️ 开发环境

### 系统要求
- Flutter SDK >= 3.8.1
- Dart SDK >= 3.0.0
- 支持平台：Windows、Linux、macOS

### 依赖包
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.5          # 状态管理
  sqflite: ^2.3.0          # SQLite数据库
  hive: ^2.2.3             # 轻量级存储
  path_provider: ^2.1.1    # 路径管理
  crypto: ^3.0.3           # 加密功能
  process_run: ^0.12.5     # 进程管理
  file_picker: ^6.1.1      # 文件选择
  shared_preferences: ^2.2.2 # 偏好设置
```

## 🚀 快速开始

### 1. 克隆项目
```bash
git clone https://github.com/zeyuzuo/zshell.git
cd zshell
```

### 2. 安装依赖
```bash
flutter pub get
```

### 3. 运行应用
```bash
# 开发模式
flutter run

# 构建发布版本
flutter build windows  # Windows
flutter build linux    # Linux
flutter build macos    # macOS
```

## 📁 项目结构

```
lib/
├── core/                 # 核心功能
│   ├── constants/       # 常量定义
│   ├── themes/          # 主题配置
│   ├── utils/           # 工具函数
│   └── services/        # 核心服务
├── data/                # 数据层
│   ├── models/          # 数据模型
│   ├── repositories/    # 数据仓库
│   └── datasources/     # 数据源
├── presentation/        # 表现层
│   ├── pages/           # 页面组件
│   ├── widgets/         # 通用组件
│   └── providers/       # 状态提供者
└── main.dart           # 应用入口
```

## 🔒 安全特性

- 🔐 SSH密钥安全存储
- 🛡️ 连接信息加密保护
- 🔑 多种认证方式支持
- 🚫 敏感信息不明文存储

## 🌐 跨平台支持

| 平台 | 状态 | 特性 |
|------|------|------|
| Windows | ✅ 支持 | 完整功能 |
| Linux | ✅ 支持 | 完整功能 |
| macOS | ✅ 支持 | 完整功能 |

## 📋 开发计划

详细的开发步骤和任务安排请查看 [task.md](task.md) 文件。

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 📞 联系方式

- 项目链接: [https://github.com/zeyuzuo/zshell](https://github.com/zeyuzuo/zshell)
- 问题反馈: [Issues](https://github.com/zeyuzuo/zshell/issues)

## 🙏 致谢

感谢所有为这个项目做出贡献的开发者和用户！
