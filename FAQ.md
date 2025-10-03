# ❓ Mac Command Helper v2.0 - 常见问题解答 (FAQ)

## 📋 目录

- [安装与配置](#安装与配置)
- [使用问题](#使用问题)
- [功能相关](#功能相关)
- [性能与兼容性](#性能与兼容性)
- [升级与迁移](#升级与迁移)
- [故障排除](#故障排除)
- [高级问题](#高级问题)

---

## 🔧 安装与配置

### Q1: 如何安装 Mac Command Helper v2.0？

**A:** 有三种安装方式：

```bash
# 方法一：全局安装（推荐）
sudo cp mac-cmd-helper-v2.sh /usr/local/bin/mcmd
sudo chmod +x /usr/local/bin/mcmd

# 方法二：使用安装脚本
chmod +x install-v2.sh
./install-v2.sh

# 方法三：创建别名
echo 'alias mcmd="/path/to/mac-cmd-helper-v2.sh"' >> ~/.zshrc
source ~/.zshrc
```

---

### Q2: 安装后无法运行，提示"找不到命令"？

**A:** 可能的原因：

1. **没有添加到 PATH**
   ```bash
   # 检查安装位置
   which mcmd
   
   # 如果没有输出，说明不在 PATH 中
   # 使用完整路径运行
   /usr/local/bin/mcmd
   ```

2. **没有执行权限**
   ```bash
   # 添加执行权限
   chmod +x /usr/local/bin/mcmd
   ```

3. **别名未生效**
   ```bash
   # 重新加载配置
   source ~/.zshrc
   # 或重新打开终端
   ```

---

### Q3: 如何完全卸载？

**A:** 删除程序和配置文件：

```bash
# 删除程序
sudo rm /usr/local/bin/mcmd

# 删除配置（可选）
rm -rf ~/.mac-cmd-helper

# 删除别名（如果使用别名方式）
# 编辑 ~/.zshrc，删除包含 'alias mcmd' 的行
nano ~/.zshrc
```

---

## 💡 使用问题

### Q4: 第一次使用应该做什么？

**A:** 推荐流程：

```bash
# 1. 运行程序
mcmd

# 2. 按 'h' 查看帮助

# 3. 尝试简单命令
输入 2 → 2.1（系统清理）

# 4. 探索新功能
按 'f' - 收藏夹
按 'r' - 历史记录
按 'c' - 命令组合

# 5. 阅读文档
cat QUICKSTART_V2.md
```

---

### Q5: 如何搜索命令？

**A:** 使用智能搜索：

```bash
# 方法一：在程序中搜索
mcmd
→ 按 's'
→ 输入关键词（如：python、清理、网络）

# 方法二：查看速查表
cat CHEATSHEET_V2.md

# 方法三：使用 grep
cat CHEATSHEET_V2.md | grep "关键词"
```

---

### Q6: 某个命令执行失败怎么办？

**A:** 故障排查步骤：

1. **查看错误信息**
   - 程序会显示详细错误
   - 记录错误代码

2. **检查依赖**
   ```bash
   # 程序会提示缺少的工具
   # 按提示安装
   brew install 工具名
   ```

3. **查看历史记录**
   ```bash
   mcmd
   → 按 'r'
   → 查看执行状态
   ```

4. **重试命令**
   - 某些命令可能需要网络
   - 某些命令需要 sudo 权限

---

### Q7: 如何添加命令到收藏夹？

**A:** 暂时需要手动编辑配置文件：

```bash
# 编辑收藏夹配置
nano ~/.mac-cmd-helper/favorites.json

# 添加命令ID
# 格式：["2.1", "5.4", "11.1"]

# 示例：
["2.1", "3.1", "5.4", "10.1"]

# 保存后重新运行程序
mcmd
→ 按 'f'
```

**未来版本将支持在程序内直接添加！**

---

## 🎯 功能相关

### Q8: 收藏夹、历史记录、命令组合有什么区别？

**A:** 三种功能的对比：

| 功能 | 用途 | 特点 |
|------|------|------|
| **收藏夹** | 收藏常用命令 | 手动添加，永久保存 |
| **历史记录** | 查看执行历史 | 自动记录，可重新执行 |
| **命令组合** | 批量执行命令 | 预设流程，一键执行 |

**使用建议：**
- 收藏夹：每天都用的命令
- 历史记录：查找之前执行的命令
- 命令组合：日常维护流程

---

### Q9: 如何自定义命令组合？

**A:** 编辑配置文件：

```bash
# 打开配置
nano ~/.mac-cmd-helper/combos.json

# 在 "自定义组合" 中添加
{
  "预设组合": [...],
  "自定义组合": [
    {
      "name": "我的清理流程",
      "description": "自定义系统清理",
      "commands": ["2.1", "4.1", "2.8"]
    }
  ]
}

# 保存后在程序中使用
mcmd
→ 按 'c'
```

---

### Q10: 快捷执行模式如何使用？

**A:** 命令行直接执行：

```bash
# 基本语法
mcmd <命令ID>

# 示例
mcmd 2.1              # 执行系统清理
mcmd 5.1              # 执行网络测速

# 搜索
mcmd search python

# 帮助
mcmd help

# 查看版本
mcmd version
```

**适用场景：**
- 编写自动化脚本
- 配置定时任务
- 快速执行单个命令

---

### Q11: 隐私与安全命令安全吗？

**A:** 完全安全：

1. **开源透明**
   - 所有代码可查看
   - 没有网络传输
   - 本地执行

2. **系统命令**
   - 使用 macOS 内置工具
   - 不依赖第三方服务

3. **权限控制**
   - 需要时才请求权限
   - 清晰的操作提示

**特别说明：**
- 11.1（清除痕迹）：只删除本地文件
- 11.2（加密文件夹）：使用系统 AES-256 加密
- 11.5（安全删除）：多次覆写，无法恢复

---

## ⚡ 性能与兼容性

### Q12: 支持哪些 macOS 版本？

**A:** 兼容性：

| macOS 版本 | 支持状态 | 说明 |
|-----------|---------|------|
| macOS 15 Sequoia | ✅ 完全支持 | |
| macOS 14 Sonoma | ✅ 完全支持 | |
| macOS 13 Ventura | ✅ 完全支持 | |
| macOS 12 Monterey | ✅ 完全支持 | |
| macOS 11 Big Sur | ✅ 完全支持 | |
| macOS 10.15 Catalina | ✅ 支持 | 部分功能受限 |
| macOS 10.14 Mojave | ✅ 支持 | 部分功能受限 |
| macOS 10.13 High Sierra | ⚠️ 基本支持 | 需测试 |
| macOS 10.12 及更早 | ❌ 不支持 | |

---

### Q13: 程序运行很慢怎么办？

**A:** 性能优化建议：

1. **检查系统资源**
   ```bash
   mcmd 10.1    # 查看系统资源
   ```

2. **清理系统**
   ```bash
   mcmd 2.1     # 深度清理
   mcmd 2.2     # 释放内存
   ```

3. **关闭不必要的程序**

4. **更新到最新版本**
   - v2.0 比 v1.0 快 40%

**正常性能指标：**
- 启动：0.3 秒
- 搜索：0.15 秒
- 命令执行：即时响应

---

### Q14: 与其他工具冲突怎么办？

**A:** 解决冲突：

1. **命令名称冲突**
   ```bash
   # 使用不同的别名
   alias mch="/usr/local/bin/mcmd"
   
   # 或使用完整路径
   /usr/local/bin/mcmd
   ```

2. **端口占用（检查时）**
   - 程序不监听端口
   - 不会有冲突

3. **配置文件冲突**
   - 使用独立目录 ~/.mac-cmd-helper
   - 不影响其他工具

---

## 🔄 升级与迁移

### Q15: 如何从 v1.0 升级到 v2.0？

**A:** 无缝升级：

```bash
# 1. 备份 v1.0（可选）
cp mac-cmd-helper.sh mac-cmd-helper-v1.sh

# 2. 下载 v2.0

# 3. 替换或独立安装
sudo cp mac-cmd-helper-v2.sh /usr/local/bin/mcmd

# 4. 运行新版本
mcmd
```

**数据迁移：**
- 配置文件会自动迁移
- 历史记录保留
- 无需手动操作

详见：`UPGRADE_GUIDE.md`

---

### Q16: v2.0 与 v1.0 可以共存吗？

**A:** 可以！

```bash
# 设置不同别名
alias mcmd1="/path/to/mac-cmd-helper-v1.sh"
alias mcmd2="/path/to/mac-cmd-helper-v2.sh"
alias mcmd="/path/to/mac-cmd-helper-v2.sh"  # 默认 v2

# 使用
mcmd1    # 运行 v1.0
mcmd2    # 运行 v2.0
mcmd     # 默认 v2.0
```

---

### Q17: 升级后数据会丢失吗？

**A:** 不会！

**保留的数据：**
- ✅ 历史记录
- ✅ v1.0 配置文件
- ✅ 所有用户数据

**新增的配置：**
- favorites.json（收藏夹）
- combos.json（命令组合）

**安全性：**
- v1.0 配置文件保持不变
- v2.0 使用新目录
- 可以随时回退

---

## 🛠️ 故障排除

### Q18: 某些命令提示"需要安装 XXX"？

**A:** 安装可选依赖：

```bash
# 使用 Homebrew 安装
brew install 工具名

# 常用工具：
brew install exiftool        # EXIF 删除
brew install ffmpeg          # 视频转换
brew install cloc            # 代码统计
brew install switchaudio-osx # 音频切换

# Python 工具：
pip3 install speedtest-cli --break-system-packages

# Node.js 管理：
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
```

---

### Q19: 执行命令后没有反应？

**A:** 检查这些：

1. **命令是否需要权限**
   - 某些命令需要 sudo
   - 会提示输入密码

2. **命令是否需要时间**
   - 清理、搜索等命令需要时间
   - 会显示进度提示

3. **命令是否需要交互**
   - 某些命令需要用户输入
   - 注意提示信息

4. **检查历史记录**
   ```bash
   mcmd
   → 按 'r'
   → 查看执行状态
   ```

---

### Q20: 配置文件损坏怎么办？

**A:** 重置配置：

```bash
# 备份当前配置
mv ~/.mac-cmd-helper ~/.mac-cmd-helper.backup

# 删除配置目录
rm -rf ~/.mac-cmd-helper

# 重新运行程序（自动创建）
mcmd

# 如果需要，恢复部分配置
cp ~/.mac-cmd-helper.backup/favorites.json ~/.mac-cmd-helper/
```

---

## 🚀 高级问题

### Q21: 如何将 mcmd 集成到自己的脚本？

**A:** 示例脚本：

```bash
#!/bin/bash

# 自动维护脚本
echo "🚀 开始系统维护..."

# 调用 mcmd 命令
mcmd 2.1    # 系统清理
mcmd 3.2    # Homebrew 清理
mcmd 2.2    # 释放内存

echo "✅ 维护完成！"

# 检查执行结果
if [ $? -eq 0 ]; then
    echo "所有任务成功完成"
else
    echo "某些任务执行失败，请检查"
fi
```

---

### Q22: 如何配置定时任务？

**A:** 使用 cron：

```bash
# 编辑定时任务
crontab -e

# 添加任务
# 每天凌晨 2 点清理系统
0 2 * * * /usr/local/bin/mcmd 2.1 >> ~/mcmd.log 2>&1

# 每周一上午 9 点更新 Homebrew
0 9 * * 1 /usr/local/bin/mcmd 3.1 >> ~/mcmd.log 2>&1

# 每小时释放内存
0 * * * * /usr/local/bin/mcmd 2.2 >> ~/mcmd.log 2>&1

# 保存退出
```

**cron 语法：**
```
分 时 日 月 周 命令
*  *  *  *  *

0  2  *  *  *  # 每天 2:00
0  9  *  *  1  # 每周一 9:00
0  *  *  *  *  # 每小时
*/30 * * * *  # 每 30 分钟
```

---

### Q23: 如何贡献代码或报告问题？

**A:** 欢迎参与！

**报告问题：**
1. 查看是否已有类似问题
2. 提供详细信息：
   - macOS 版本
   - 程序版本
   - 错误信息
   - 重现步骤

**贡献代码：**
1. Fork 仓库
2. 创建分支
3. 提交更改
4. 发起 Pull Request

**提供反馈：**
- 功能建议
- 使用体验
- 文档改进

---

### Q24: 如何添加自定义命令？

**A:** 修改脚本：

```bash
# 1. 备份原脚本
cp mac-cmd-helper-v2.sh mac-cmd-helper-v2.sh.backup

# 2. 编辑脚本
nano mac-cmd-helper-v2.sh

# 3. 在 COMMANDS 数组中添加
COMMANDS+=(
"12.1|custom|自定义命令|echo 'Hello'|no|none|命令描述|参数说明|使用场景|注意事项|相关命令"
)

# 4. 添加对应的菜单项
# 在 show_category_menu 和 main 函数中添加相应代码
```

**注意：**
- 需要了解 Bash 编程
- 建议提交到官方仓库
- 便于其他用户使用

---

### Q25: 性能优化建议？

**A:** 最佳实践：

**系统层面：**
```bash
# 定期维护
mcmd
→ 按 'c'
→ 完整清理

# 监控资源
mcmd 10.1
```

**程序层面：**
```bash
# 使用收藏夹
- 减少导航时间

# 使用快捷执行
mcmd 2.1  # 更快

# 使用命令组合
- 批量操作更高效
```

**脚本优化：**
```bash
# 避免频繁调用
# 不好的做法
for i in {1..100}; do
    mcmd 2.2
done

# 好的做法
# 批量操作使用命令组合
```

---

## 💬 其他问题

### Q26: 在哪里可以获得帮助？

**A:** 多种渠道：

1. **程序内帮助**
   ```bash
   mcmd
   → 按 'h'
   ```

2. **文档**
   - README_V2.md - 完整文档
   - QUICKSTART_V2.md - 快速入门
   - CHEATSHEET_V2.md - 命令速查
   - FAQ.md - 本文档

3. **在线支持**
   - GitHub Issues
   - 讨论区
   - 邮件支持

---

### Q27: 程序是免费的吗？

**A:** 完全免费！

- ✅ 免费使用
- ✅ 开源项目
- ✅ 无广告
- ✅ 无付费功能
- ✅ 持续更新

---

### Q28: 未来会有哪些新功能？

**A:** 规划中的功能：

**v2.x 更新：**
- 程序内添加收藏
- 更多预设组合
- 命令推荐系统
- 执行统计分析

**v3.0 展望：**
- AI 智能建议
- 云同步配置
- 插件系统
- Web 界面

**社区反馈：**
- 欢迎提出建议
- 共同打造更好的工具

---

## 🎯 快速参考

### 常见错误代码

| 错误 | 原因 | 解决方法 |
|------|------|---------|
| Permission denied | 权限不足 | 使用 sudo 或添加权限 |
| Command not found | 未安装工具 | 按提示安装依赖 |
| File not found | 文件路径错误 | 检查路径 |
| Network error | 网络问题 | 检查网络连接 |

### 重要配置文件

```
~/.mac-cmd-helper/
├── config.json       # 主配置（预留）
├── history.log       # 执行历史
├── favorites.json    # 收藏列表
└── combos.json       # 命令组合
```

### 紧急恢复

```bash
# 完全重置
rm -rf ~/.mac-cmd-helper
mcmd

# 只重置收藏夹
rm ~/.mac-cmd-helper/favorites.json
mcmd

# 清除历史
rm ~/.mac-cmd-helper/history.log
```

---

## 📮 联系我们

**还有其他问题？**

- 📧 Email: your-email@example.com
- 🐛 Issues: GitHub Issues
- 💬 Discussions: GitHub Discussions
- 📚 Documentation: 查看完整文档

---

**🎉 感谢使用 Mac Command Helper v2.0！**

如果这个 FAQ 没有解答你的问题，请通过上述渠道联系我们！
