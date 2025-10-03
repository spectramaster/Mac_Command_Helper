# Mac Command Helper v2.0.1 - 任务清单
（升级）v2.1.0 社区与 CI 增强：

- [x] 社区文件：CONTRIBUTING/CODE_OF_CONDUCT/SECURITY
- [x] CI：GitHub Actions（shellcheck + markdownlint）
- [x] Issue/PR 模板
- [x] Makefile 与 shellcheck 脚本
- [x] 主题配置与无彩模式、错误日志摘要
- [x] 可选本地遥测（默认关闭）
- [x] 安装脚本非交互参数 -y/--user/--alias
- [x] README 徽章、目录、卸载说明

（稳定性与安全性）
- [x] 交互输入校验（路径/名称/端口/大小/邮箱）
- [x] 修复参数模式匹配（APP_NAME 优先级与 $ 标识）
- [x] Docker 批量操作更稳健（xargs）
- [x] Xcode 清理路径空值防护
- [x] 安全删除在 APFS 上的提示与回退

状态: 全部任务将在本次提交内完成并保持此清单与变更日志同步。

- [x] 1. 添加 `jq` 依赖检查；整合配置初始化；历史日志滚动
- [x] 2. 完成 CLI 搜索实现（支持 --first/--run/--json）
- [x] 3. 命令详情页支持添加到收藏；收藏夹支持移除
- [x] 4. 增加 CLI 直接执行命令组合 `mcmd combo <index|name>`
- [x] 5. 将磁盘 I/O 监控从 `iotop` 替换为 `iostat`
- [x] 6. Wi‑Fi 接口自适应，完善查看密码逻辑
- [x] 7. 降低系统清理风险，仅清理用户级缓存/日志
- [x] 8. `help <ID>` 展示单命令帮助
- [x] 9. 安装脚本增加 `jq` 检查提示
- [x] 10. 更新文档（README/CHEATSHEET/INDEX），同步变更与依赖
- [x] 11. 版本号升级至 v2.0.1；整理更新说明
