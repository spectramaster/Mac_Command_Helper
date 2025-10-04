# Mac Command Helper - 更新说明

## v2.1.0 (2025-10-04)

Community & CI
- Add CONTRIBUTING, CODE_OF_CONDUCT, SECURITY
- Add GitHub Issue/PR templates
- Add CI workflow (shellcheck + markdownlint)
- Add Makefile and shellcheck script

DX & Config
- Theme config: no-color and spinner toggles
- Optional local-only telemetry (opt-in) with metrics.json
- Error log summary with rotation

Stability & Safety
- Input validation for interactive parameters (paths, ports, sizes, names, email)
- Fix command pattern matching so $APP_NAME no longer collides with $NAME
- Safer Xcode cleanup with non-empty directory guards
- Docker mass operations now use xargs to avoid word-splitting issues
- Secure delete messaging clarified on APFS; fallback to plain delete with warning
- Installer tilde expansion fixed to use $HOME

CLI & Installer
- Non-interactive install flags: -y/--user/--alias
- CLI search/combos/help retained from 2.0.1

Packaging
- Add Homebrew formula template and `scripts/release.sh`

Linux Edition v1.0.0 (2025-10-04)
- Add Linux server script `linux-cmd-helper.sh` (Debian/Ubuntu)
- Add installer `install-linux.sh` and docs `README_LINUX.md`
- 10 categories, 40+ commands for APT, services, network, storage, security, users, Docker, monitoring, backup
- Safety-first: dry-run previews, backups, double confirmations, error logs, history with exit codes

Docs
- README badges + TOC; telemetry and theme docs
- INDEX and CHEATSHEET adjustments

## v2.0.1 (2025-10-04)

改进
- 新增 `jq` 依赖检查与说明；收藏与组合在缺失时优雅降级
- 整合配置初始化；历史日志新增退出码并支持滚动保留最近 5000 条
- CLI 搜索完善：新增 `--first`、`--run <ID>`、`--json` 输出
- 命令详情页支持按 `f` 添加到收藏；收藏夹支持移除与无效清理
- 新增 `mcmd combo <index|name>` 直接执行组合
- 用 `iostat` 替换 `iotop` 以适配 macOS
- Wi‑Fi 接口自适应，提升查看密码的兼容性
- 系统清理降级为用户级缓存/日志，减少潜在风险
- `mcmd help <ID>` 支持查看单个命令说明
- 安装脚本新增 `jq` 提示与可选安装

文档
- README/CHEATSHEET/INDEX 同步更新：依赖、用法、兼容性说明与注意事项
