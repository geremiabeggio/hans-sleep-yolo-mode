# 🚀 Hans Sleep YOLO Mode

> **Claude Code 自主開發配置** — 讓 AI 全自動執行，權限全開，可以安心睡覺

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-v2.1+-blue)](https://claude.ai)

---

## 🤔 這是什麼？

這是一套 **Claude Code 自主開發配置**，讓你可以：

- ✅ **全自動執行** — Claude 不會問問題，自己做決定
- ✅ **權限全開** — 不會跳出煩人的權限確認視窗
- ✅ **安心睡覺** — 設定好任務，睡覺起來看成果
- ✅ **手機通知** — 透過 ntfy.sh 即時收到進度通知
- ✅ **自動 checkpoint** — 定期 git commit，不怕中斷遺失

---

## ⚠️ 警告！使用前必讀

> **YOLO Mode = 權限全開 = 風險自負**

這個配置會讓 Claude：
- 🔓 執行任何 bash 指令（不會詢問確認）
- 🔓 讀寫任何檔案
- 🔓 安裝任何套件
- 🔓 執行任何程式碼

### 🛡️ 安全建議

1. **永遠在 feature branch 工作**，不要在 main 上跑
2. **不要在有機密資料的專案使用**
3. **建議在 VM 或 Container 中執行**
4. **確保有備份**
5. **定期檢查 Claude 做了什麼**

### 🚫 禁止行為（已在設定中阻擋）

- `sudo` / `su` — 提權操作
- `rm -rf /` — 刪除系統
- `shutdown` / `reboot` — 關機重啟
- `mkfs` / `dd` — 格式化磁碟

---

## 📦 包含檔案

```
hans-sleep-yolo-mode/
├── CLAUDE.md                    # Claude 行為指引
├── sleep-safe-runner.sh         # 睡覺跑腳本（自動重啟 + 通知）
├── README.md                    # 說明文件
└── .claude/
    ├── settings.json            # Claude Code 設定
    └── skills/
        └── autonomous-skill/
            └── SKILL.md         # 長時任務技能
```

---

## 🚀 快速開始

### 1. 下載

```bash
git clone https://github.com/你的帳號/hans-sleep-yolo-mode.git
```

或直接下載 ZIP

### 2. 安裝到你的專案

```bash
cd ~/Projects/你的專案

# 複製檔案
cp -r ~/hans-sleep-yolo-mode/.claude .
cp ~/hans-sleep-yolo-mode/CLAUDE.md .
cp ~/hans-sleep-yolo-mode/sleep-safe-runner.sh .

# 給執行權限
chmod +x sleep-safe-runner.sh
```

### 3. 設定通知（ntfy.sh）

```bash
# 1. 手機下載 ntfy app（iOS / Android）
# 2. 訂閱一個頻道，例如 "my-claude-notify"
# 3. 編輯腳本

nano sleep-safe-runner.sh
# 找到這行，填入你的頻道名
NTFY_TOPIC="my-claude-notify"
```

### 4. 啟動 YOLO Mode

```bash
claude --dangerously-skip-permissions
```

### 5. 設定快捷指令（選用）

```bash
echo 'alias yolo="claude --dangerously-skip-permissions"' >> ~/.zshrc
source ~/.zshrc

# 以後只要打
yolo
```

---

## 🌙 睡覺跑模式

讓 Claude 長時間自動執行複雜任務：

```bash
# 1. 建立專用分支（重要！）
git checkout -b auto/my-feature

# 2. 啟動睡覺跑腳本
./sleep-safe-runner.sh "build-login-system"

# 3. 去睡覺 💤
# 手機會收到通知：
# 🚀 Started — 開始執行
# 📊 Checkpoint — 進度報告（每 3 輪）
# 🎉 Completed — 全部完成
# 🔴 Failed — 失敗停止
```

### 背景執行（關掉終端機也不停）

```bash
# 用 tmux
tmux new-session -d -s claude './sleep-safe-runner.sh "my-task"'

# 查看進度
tmux attach -t claude

# 離開（不停止）
# 按 Ctrl+B 再按 D
```

---

## ⚙️ 設定說明

### CLAUDE.md

這是給 Claude 看的行為指引，告訴它：
- 不要問問題，自己做決定
- 遇到錯誤自己修
- 卡住就跳過，繼續下一個
- 頻繁 commit

### sleep-safe-runner.sh

可調整的參數：

```bash
MAX_ITERATIONS=100           # 最大循環次數
MAX_CONSECUTIVE_FAILURES=5   # 連續失敗幾次才停止
SLEEP_BETWEEN_SESSIONS=5     # 每輪間隔（秒）
MAX_SESSION_MINUTES=45       # 單輪超時（分鐘）
CHECKPOINT_EVERY=3           # 每幾輪自動 commit
```

### 通知選項

支援多種通知方式（編輯 `sleep-safe-runner.sh`）：

| 方式 | 設定 |
|------|------|
| **ntfy.sh**（推薦） | `NTFY_TOPIC="your-topic"` |
| LINE Messaging API | `LINE_CHANNEL_ACCESS_TOKEN` + `LINE_USER_ID` |
| Telegram | `TELEGRAM_BOT_TOKEN` + `TELEGRAM_CHAT_ID` |
| Discord | `DISCORD_WEBHOOK` |
| Slack | `SLACK_WEBHOOK` |

---

## 📱 ntfy.sh 設定教學

最簡單的通知方式，1 分鐘搞定：

1. 手機下載 **ntfy** app
   - [iOS App Store](https://apps.apple.com/app/ntfy/id1625396347)
   - [Google Play](https://play.google.com/store/apps/details?id=io.heckel.ntfy)

2. 打開 app，點 **「+」**

3. 輸入一個**獨特的頻道名稱**（例如 `hans-claude-2026`）
   > ⚠️ 頻道是公開的，用不容易猜到的名稱

4. 測試通知：
   ```bash
   curl -d "測試成功！" ntfy.sh/你的頻道名
   ```

5. 編輯 `sleep-safe-runner.sh`，填入頻道名

---

## 🐛 常見問題

### Q: 還是會跳權限確認視窗？

確保用這個指令啟動：
```bash
claude --dangerously-skip-permissions
```

啟動後左下角要顯示 `bypass permissions on`

### Q: 睡覺跑到一半停了？

檢查日誌：
```bash
cat .autonomous/你的任務名/logs/runner.log
```

常見原因：
- Token 用完（Claude Max 也有限制）
- 連續失敗太多次
- 網路問題

### Q: 怎麼看 Claude 做了什麼？

```bash
# 看 git log
git log --oneline -20

# 看任務進度
cat .autonomous/你的任務名/task_list.md

# 看詳細日誌
ls .autonomous/你的任務名/logs/
```

### Q: 想停止執行？

```bash
# 方法 1：按 Ctrl+C

# 方法 2：如果用 tmux
tmux attach -t claude
# 按 Ctrl+C
```

---

## 🤝 貢獻

歡迎 PR 和 Issue！

---

## 📄 授權

MIT License

---

## 👤 作者

**Hans Lin** @ [Group.G](https://groupg.cc)

- 文化科技導演 / AI 導演
- 實踐大學兼任客座助理教授
- 服務客戶：台積電、Samsung、LINE、ASUS

---

## ⭐ 如果有幫助，請給個 Star！

讓更多人可以安心睡覺，讓 AI 幫你工作 💤
