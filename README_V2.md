# 🚀 Mac Command Helper v2.0

**你的终端效率助手** - 更强大、更智能、更高效！

![Version](https://img.shields.io/badge/version-2.1.0-blue)
![macOS](https://img.shields.io/badge/macOS-10.13+-green)
![Shell](https://img.shields.io/badge/shell-bash-orange)
![Made With](https://img.shields.io/badge/made%20with-bash-1f425f.svg)
![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)

## 🎉 v2.0 重大更新

## 🧭 目录

- [✨ 特性](#-特性)
- [📦 功能清单](#-功能清单)
- [🚀 快速开始](#-快速开始)
- [🌟 新功能详解](#-新功能详解)
- [🔐 隐私与安全功能](#-隐私与安全功能)
- [📁 文件操作增强](#-文件操作增强)
- [🌐 网络工具增强](#-网络工具增强)
- [🔧 开发工具增强](#-开发工具增强)
- [📊 配置文件](#-配置文件)
- [🔄 从 v1.0 升级](#-从-v10-升级)
- [🎯 使用场景](#-使用场景)
- [📚 详细文档](#-详细文档)
- [🐛 常见问题](#-常见问题)
- [💻 系统要求](#-系统要求)
- [🤝 贡献](#-贡献)
- [📝 更新日志](#-更新日志)

### 全新特性

- ⭐ **收藏夹系统** - 收藏常用命令，一键快速访问
- 📜 **历史记录查看** - 查看执行历史，快速重新执行
- 🎯 **命令组合 (Combo)** - 预设组合一键执行多个命令
- ⚡ **快捷执行模式** - 命令行参数直接执行，支持脚本调用
- 🔐 **隐私与安全** - 新增 8 个安全命令
- 📁 **文件操作增强** - 新增 7 个文件处理命令
- 🌐 **网络工具增强** - 新增 9 个网络管理命令
- 🔧 **开发工具增强** - 新增 8 个开发辅助命令
- ⚙️  **系统功能增强** - 新增 5 个系统管理命令

### 命令总数

- **v1.0**: 40+ 个命令
- **v2.0**: **70+ 个命令** ⬆️ 增加 75%

## ✨ 特性

### 🎨 精美界面
- 256 色彩系统
- Unicode 图标
- 响应式布局
- 流畅动画

### 🛠️ 强大功能
- 11 大功能分类
- 70+ 实用命令
- 智能搜索
- 详细说明和学习系统

### 🚀 高效操作
- 收藏夹快速访问
- 历史命令重执行
- 命令组合批处理
- 快捷执行模式

### 🔒 安全可靠
- 危险操作确认
- 完整的权限控制
- 详细的执行日志
- 开源透明

## 📦 功能清单

### 🐍 1. Python 开发环境 (7个命令)
- 激活/创建虚拟环境
- 包管理和依赖导出
- pip 镜像源切换
- 缓存清理

### ⚙️ 2. 系统管理 (10个命令)
- 深度系统清理
- 内存释放
- 防止休眠
- Spotlight 索引重建
- 动画效果控制
- 桌面图标切换

### 🍺 3. Homebrew 管理 (5个命令)
- 软件更新和清理
- 问题诊断
- 镜像源切换

### 📁 4. 文件操作 (9个命令)
- 大文件查找
- 批量重命名
- 图片/文件压缩
- EXIF 元数据删除
- 视频格式转换
- PDF 合并

### 🌐 5. 网络工具 (9个命令)
- 网络测速和诊断
- DNS 服务器切换
- WiFi 密码查看
- 系统代理配置
- 端口管理

### 🎨 6. 界面外观 (7个命令)
- 截图设置（格式/位置/阴影）
- Dock 自定义
- 深色模式切换

### 🔧 7. 开发工具 (8个命令)
- hosts 和环境变量编辑
- Git 配置和批量操作
- Node.js 版本管理
- Docker 快捷操作
- Xcode 清理
- 代码统计

### 🔐 8. 隐私与安全 (8个命令)
- 使用痕迹清除
- 文件夹加密
- 网络连接监控
- 强密码生成
- 安全删除文件
- 应用权限查看
- 防火墙配置

### 🚀 9. 应用管理 (5个命令)
- 强制退出应用
- 启动项管理
- 完全卸载应用
- 应用大小查看
- 应用列表导出

### ⚡ 10. 快捷操作 (5个命令)
- 重启 Finder/Dock
- 快速打开目录
- 截图工具
- 音频设备切换

### 📊 11. 性能监控 (5个命令)
- 系统资源监控
- CPU/内存排行
- 磁盘 I/O 监控
- 电池健康检查

## 🚀 快速开始

### 安装

```bash
# 方法一：Homebrew（推荐，维护者需先发布 Tap）
brew tap yourusername/tap
brew install mcmd

# 方法二：仓库下载
git clone https://github.com/yourusername/mac-cmd-helper.git
cd mac-cmd-helper
chmod +x mac-cmd-helper-v2.sh
./mac-cmd-helper-v2.sh
```

### 设置全局命令

```bash
# 添加别名到 ~/.zshrc（方法二使用）
echo 'alias mcmd="/path/to/mac-cmd-helper-v2.sh"' >> ~/.zshrc
source ~/.zshrc

# 现在可以直接运行
mcmd
```

## 💡 使用方法

### 交互模式

```bash
# 启动程序
mcmd

# 按数字选择功能分类
# 输入命令编号执行
```

### 快捷键

| 按键 | 功能 |
|------|------|
| `s` | 智能搜索命令 |
| `f` | 查看收藏夹 |
| `r` | 执行历史 |
| `c` | 命令组合 |
| `h` | 显示帮助 |
| `q` | 退出程序 |
| `0` | 返回上级 |

### 快捷执行模式 ⚡

```bash
# 直接执行命令
mcmd 2.1          # 执行系统清理

# 搜索命令
mcmd search python

# 查看帮助
mcmd help

# 查看版本
mcmd version

# 执行命令组合
mcmd combo 1         # 执行第 1 个预设组合
```

## 🌟 新功能详解

### ⭐ 收藏夹系统

```
1. 在主菜单按 'f' 进入收藏夹
2. 收藏的命令会显示在列表中
3. 输入编号快速执行
4. 配置保存在 ~/.mac-cmd-helper/favorites.json
```

### 📜 历史记录

```
1. 在主菜单按 'r' 查看历史
2. 显示最近 20 条执行记录
3. 包含执行时间、状态、耗时
4. 可以快速重新执行历史命令
```

### 🎯 命令组合

内置预设组合：

**完整清理**
- 系统清理 (2.1)
- Homebrew 清理 (3.2)
- 释放内存 (2.2)

**系统优化**
- 系统清理 (2.1)
- 禁用动画 (2.9)
- 释放内存 (2.2)

**网络诊断**
- 刷新 DNS (5.3)
- 查看 IP (5.4)
- 网络测速 (5.1)

### ⚡ 快捷执行

```bash
# 配合定时任务
crontab -e
0 2 * * * /path/to/mcmd 2.1  # 每天2点清理系统

# 编写自动化脚本
#!/bin/bash
mcmd 2.1  # 清理系统
mcmd 3.2  # 清理 Homebrew
mcmd 2.2  # 释放内存
```

## 🔐 隐私与安全功能

### 清除使用痕迹 (11.1)
- 清除最近使用的文件/应用
- 清除 Safari 浏览历史
- 清除 Spotlight 搜索历史
- 清除终端命令历史

### 文件夹加密 (11.2)
- 使用 AES-256 加密
- 创建加密磁盘镜像
- 密码保护

### 强密码生成 (11.4)
- 自定义长度和复杂度
- 自动复制到剪贴板
- 符合安全标准

提示（安全删除文件 11.5）
- 新版 macOS/APFS 上不再保证“彻底不可恢复”的文件级删除
- 建议启用 FileVault 全盘加密并对敏感介质进行妥善处理

## 📁 文件操作增强

### 图片压缩 (4.4)
```bash
# 批量压缩图片
# 可自定义质量 (1-100)
# 使用 macOS 内置 sips 工具
```

### 视频转换 (4.7)
```bash
# 支持格式：mp4, avi, mkv, mov
# 使用 ffmpeg（需安装）
```

### EXIF 删除 (4.6)
```bash
# 删除图片元数据
# 保护隐私信息
# 需要 exiftool
```

## 🌐 网络工具增强

### DNS 切换 (5.5)
- Google DNS (8.8.8.8)
- Cloudflare DNS (1.1.1.1)
- 阿里 DNS (223.5.5.5)
- 114 DNS
- 自定义 DNS

### WiFi 密码查看 (5.6)
```bash
# 查看当前连接的 WiFi 密码
# 从钥匙串读取
# 需要输入系统密码
```

### 系统代理配置 (5.7)
- HTTP 代理
- HTTPS 代理
- SOCKS5 代理
- 一键开关

## 🔧 开发工具增强

### Node.js 管理 (7.4)
- 安装 nvm
- 切换 Node 版本
- 查看可用版本

### Docker 操作 (7.5)
- 启动/停止所有容器
- 删除停止的容器
- 清理无用镜像
- 查看资源占用

### Git 批量操作 (7.6)
- 批量拉取多个仓库
- 批量查看状态
- 批量清理分支

## 📊 配置文件

v2.0 使用新的配置目录结构：

```
~/.mac-cmd-helper/
├── config.json       # 主配置
├── history.log       # 执行历史
├── favorites.json    # 收藏列表
└── combos.json       # 命令组合
```

### 主题与外观

可选配置文件 `~/.mac-cmd-helper/theme.conf`：

```
# 关闭彩色输出（on/off）
color=on
# 关闭加载动画（on/off）
spinner=on
```

也可通过环境变量控制：`NO_COLOR=1` 或 `MCMD_NO_COLOR=1` 关闭彩色。

### 错误日志

当命令失败时，会将最近的 stderr 摘要写入：

```
~/.mac-cmd-helper/error.log
```

### 可选遥测（本地汇总，默认关闭）

为帮助改进常用命令体验，支持“本地匿名计数”遥测，默认关闭：

启用方式（任选一项）：
- 环境变量：`export MCMD_TELEMETRY=1`
- 配置文件 `~/.mac-cmd-helper/config.json`：`{"telemetry":"on"}`

数据仅存储在本机的 `~/.mac-cmd-helper/metrics.json`（或 `metrics.log`），不上传网络。

## 🔄 从 v1.0 升级

v2.0 完全兼容 v1.0，无需迁移数据。

### 升级步骤

```bash
# 1. 备份 v1.0 配置（可选）
cp -r ~/.mac-cmd-helper ~/.mac-cmd-helper.backup

# 2. 下载 v2.0 脚本
# 3. 替换旧脚本
# 4. 运行新版本

mcmd
```

### 新增文件

v2.0 会自动创建新的配置文件：
- `favorites.json` - 收藏列表
- `combos.json` - 命令组合

## 🎯 使用场景

### 场景一：日常维护

```bash
# 运行完整清理组合
mcmd
→ 按 'c'
→ 选择 "完整清理"
→ 一键执行清理、释放内存
```

### 场景二：开发环境

```bash
# 快速配置 Python 环境
mcmd 1.2          # 创建虚拟环境
mcmd 1.1          # 激活环境
mcmd 1.5          # 安装依赖
```

### 场景三：隐私保护

```bash
# 使用公共电脑后清理
mcmd 11.1         # 清除使用痕迹
```

### 场景四：网络问题

```bash
# 网络诊断组合
mcmd
→ 按 'c'
→ 选择 "网络诊断"
```

## 📚 详细文档

- **快速入门**: QUICKSTART_V2.md
- **命令速查**: CHEATSHEET_V2.md
- **升级指南**: UPGRADE_GUIDE.md
- **项目总结**: PROJECT_SUMMARY_V2.md

## 🐛 常见问题

### Q: v2.0 与 v1.0 有什么区别？

**A:** v2.0 新增：
- 30+ 新命令
- 收藏夹、历史记录、命令组合等高级功能
- 快捷执行模式
- 更多的依赖工具支持

### Q: 配置文件会丢失吗？

**A:** 不会。v1.0 的历史记录会保留，v2.0 会创建新的配置文件。

### Q: 如何添加自定义命令组合？

**A:** 编辑 `~/.mac-cmd-helper/combos.json`，按照预设组合的格式添加。

### Q: 快捷执行模式支持哪些参数？

**A:** 
```bash
mcmd <命令ID>           # 直接执行命令
mcmd search <关键词>    # 搜索命令
mcmd help              # 显示帮助
mcmd version           # 显示版本
```

## 💻 系统要求

- macOS 10.13 (High Sierra) 或更高版本
- Bash 3.2+
- 终端支持 256 色

### 可选依赖

某些功能需要额外工具（脚本会提示安装）：

- `speedtest-cli` - 网络测速
- `exiftool` - EXIF 删除
- `ffmpeg` - 视频转换
- `nvm` - Node.js 管理
- `cloc` - 代码统计
- `switchaudio-osx` - 音频切换
- `jq` - JSON 解析（收藏与命令组合）

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 贡献指南

1. Fork 本仓库
2. 创建特性分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

更多细节请见 CONTRIBUTING.md 和 CODE_OF_CONDUCT.md；安全问题参阅 SECURITY.md。

### 发布与 Homebrew Tap（维护者）

```bash
# 1) 更新版本、CHANGELOG 并打 Tag
make release version=2.1.0

# 2) 使用 gh 创建 GitHub Release（可选）
gh release create v2.1.0 dist/mcmd-v2.1.0.tar.gz --title "v2.1.0" --notes-file CHANGELOG.md

# 3) 在你的 tap 仓库（yourusername/homebrew-tap）中：
#    将 dist/mcmd.rb 复制到 Formula/mcmd.rb 并提交
#    用户即可:
brew tap yourusername/tap
brew install mcmd
```

## 📝 更新日志

### v2.0.0 (2025-10-04)

### v2.0.1 (2025-10-04)

改进
- CLI 搜索增强（支持 --first/--run/--json）
- 新增 `mcmd combo <index|name>` 执行命令组合
- 命令详情页可按 `f` 添加收藏；收藏夹支持移除
- 将 I/O 监控改为 `iostat` 以提升兼容性
- Wi‑Fi 密码获取更稳健；系统清理更安全（仅用户级）
- 历史记录加入退出码并支持滚动保留
- 安装脚本新增 `jq` 检查
- 新增主题配置（关闭彩色/动画）与错误日志摘要


**新增功能**
- ⭐ 收藏夹系统
- 📜 历史记录查看器
- 🎯 命令组合功能
- ⚡ 快捷执行模式
- 🔐 8 个隐私安全命令
- 📁 7 个文件操作命令
- 🌐 9 个网络工具命令
- 🔧 8 个开发工具命令
- ⚙️ 5 个系统管理命令

**改进**
- 优化界面布局
- 增强搜索功能
- 改进错误处理
- 添加执行时间统计

**修复**
- 修复某些命令的权限问题
- 优化依赖检查逻辑
- 改进用户输入验证

### v1.0.0 (2025-10-04)

- 🎉 首次发布
- ✨ 10 大功能分类
- ✨ 40+ 核心命令

## 📄 许可证

MIT License

如需移除本工具（卸载）：
- 全局安装：删除 `/usr/local/bin/mcmd`
- 用户安装：删除 `~/bin/mcmd`
- 配置与数据：删除 `~/.mac-cmd-helper/`

## 🙏 致谢

- macOS 用户社区
- 所有开源工具贡献者
- 早期测试用户的反馈

## 📮 联系方式

- 📧 Email: your-email@example.com
- 🐛 Issues: https://github.com/yourusername/mac-cmd-helper/issues
- 💬 Discussions: https://github.com/yourusername/mac-cmd-helper/discussions

---

⭐ 如果这个工具对你有帮助，请给个 Star！

🚀 v2.0 - 让 Mac 终端更强大、更智能！
