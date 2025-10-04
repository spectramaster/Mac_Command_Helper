# 🐧 Linux Command Helper (Debian/Ubuntu)

你的 Linux 服务器终端助手（Debian/Ubuntu），聚焦稳定、安全、好用。支持交互界面、搜索、收藏、历史、命令组合、快捷执行。

![Linux](https://img.shields.io/badge/Linux-Debian%2FUbuntu-blue) ![bash](https://img.shields.io/badge/shell-bash-orange) ![PRs](https://img.shields.io/badge/PRs-welcome-brightgreen)

## ✨ 特性
- 10 大分类，40+ 常用运维命令（APT/服务/网络/存储/安全/用户/容器/监控/备份/快捷）
- 交互 UI：菜单、搜索、收藏、历史、命令组合
- 快捷执行：`lcmd 1.1`、`lcmd search nginx --first`、`lcmd combo 1`
- 安全优先：预览（dry-run）、双确认、自动备份与校验（sshd、APT 源、UFW）
- 错误日志与历史记录：`~/.linux-cmd-helper/error.log`、`history.log`
- 无彩/无动画：`NO_COLOR=1` 或 `LCMD_NO_COLOR=1`

## 🚀 安装

```bash
# 推荐：安装脚本
chmod +x install-linux.sh
./install-linux.sh -y            # 全局安装 (sudo)
./install-linux.sh -y --user     # 用户安装 (~/bin)
./install-linux.sh -y --alias    # 仅设置别名

# 安装完成后
lcmd version
```

## 🧭 使用

```bash
# 交互模式
lcmd

# 快捷执行
lcmd 1.1                 # APT 更新
lcmd search nginx --first
lcmd combo 1             # 预设组合：系统更新
```

注意：在交互模式下，执行完命令会暂停显示结果（按任意键继续）。

## 🧰 命令分类（部分）

- 系统管理（APT 更新/升级/清理、journal 清理、时间同步、APT 源切换）
- 服务与进程（systemctl start/stop/restart/enable/disable/status）
- 网络工具（ip/ss/dig/traceroute/ping、DNS 查看）
- 存储与文件（磁盘/目录占用、查找大文件、tar 压缩/解压、安全删除）
- 安全与防火墙（UFW 安全启用、Fail2ban 状态、SSHD 加固、自动安全更新）
- 用户与权限（adduser、usermod 加 sudo）
- 容器与开发（Docker 状态/清理、Git 全局配置）
- 监控与日志（top、ps 排名、journal 错误）
- 备份与计划（rsync 预览+执行、crontab 编辑）

## 🛡️ 安全说明
- 防火墙启用（UFW）会先检测/允许 SSH 端口，默认双确认，尽量避免断连风险
- SSHD 加固会先备份配置并做语法校验；任何问题可用备份回滚
- APT 源切换为预览+备份+确认流程；应用后自动执行 `apt update`
- 安全删除（shred）在某些文件系统上不保证不可恢复

## 📁 配置与日志

```
~/.linux-cmd-helper/
├── config.json       # 主配置（可选）
├── history.log       # 执行历史（保留最近 5000 条）
├── error.log         # 失败时的 stderr 摘要
├── favorites.json    # 收藏列表（需要 jq）
└── combos.json       # 命令组合（需要 jq）
```

## 🧩 依赖（按需安装）
- 必备：`bash`, 基础 GNU 工具
- 建议：`jq`, `dnsutils`(dig), `traceroute`, `rsync`, `ufw`, `fail2ban`, `unattended-upgrades`, `docker`
- 安装脚本会提示是否安装缺失依赖

## 🐛 故障排查
- 查看错误日志：`~/.linux-cmd-helper/error.log`
- 历史记录（含退出码）：`~/.linux-cmd-helper/history.log`
- 运行环境：Debian 11+/Ubuntu 20.04+

## 🤝 贡献
- 欢迎 PR/Issue；请参考 CONTRIBUTING.md 与 CODE_OF_CONDUCT.md

## 📄 许可证
- MIT License（见仓库 LICENSE）

