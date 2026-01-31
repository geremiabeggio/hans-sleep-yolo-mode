# 🚀 Hans Sleep YOLO Mode

> **啟動指令：** `claude --dangerously-skip-permissions`
> 
> **快捷 alias：** 在終端機執行一次 `echo 'alias yolo="claude --dangerously-skip-permissions"' >> ~/.zshrc && source ~/.zshrc`，之後只要打 `yolo` 即可

---

## ⚡ Prime Directives（絕對遵守）

1. **NEVER ask questions** — 自己做決定，不要問
2. **NEVER wait for confirmation** — 直接執行，不要等
3. **NEVER stop on errors** — 遇到錯誤自己修，繼續往下
4. **NEVER leave tasks incomplete** — 做完才停
5. **ALWAYS commit after changes** — 改完就 commit
6. **ALWAYS test before marking done** — 測試通過才算完成

---

## 🎯 Decision Framework

遇到不確定的情況：

| 狀況 | 行動 |
|------|------|
| 多種解法？ | 選最簡單的 |
| 缺少資訊？ | 用合理預設值 |
| 需求衝突？ | 照 codebase 現有 pattern |
| 卡住了？ | 記錄問題，跳過，繼續下一個 |
| 外部依賴壞了？ | Mock 掉，繼續開發 |

---

## 🛠 Tech Stack（依專案調整）

```yaml
Runtime: Node 20 LTS / Python 3.11+
Package: pnpm / npm / yarn / bun / uv
Framework: 依專案（React, Next.js, Vue, FastAPI, etc.）
Testing: 依專案（vitest, jest, pytest, etc.）
```

---

## 📝 Common Commands

```bash
# Node.js
pnpm install && pnpm dev
pnpm build && pnpm test

# Python
uv sync && uv run python main.py
uv run pytest

# Git
git add -A && git commit -m "feat: description"
```

---

## 🔄 Git Workflow

- 在 feature branch 工作：`git checkout -b feature/task-name`
- 頻繁小 commit：`git commit -m "feat: add login"`
- Conventional commits：`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
- **❌ 不要 push** — 人工 review 後再 push

---

## 📦 Long-Running Tasks（自主執行模式）

複雜任務使用 autonomous skill：

```
觸發詞：「autonomous」「自主執行」「long-running task」
儲存位置：.autonomous/<task-name>/
進度追蹤：task_list.md（用 - [ ] / - [x] checkbox）
```

---

## 🚫 Safety Boundaries

- ❌ 不執行 `sudo` / `su`
- ❌ 不刪除系統檔案
- ❌ 不 commit 機密資訊
- ❌ 不 push 到 remote
- ❌ 不對 production 資料做破壞性操作

---

## 🔧 Error Recovery

錯誤處理流程：

1. 讀錯誤訊息
2. 搜 codebase 找類似 pattern
3. 試最常見的修法
4. 3 次失敗 → 記錄問題，跳過，繼續
5. 永不放棄 — 一定有解法

---

## 📱 通知設定（ntfy.sh）

睡覺跑時會透過 ntfy 發送通知：

```
🚀 Started — 開始執行
📊 Checkpoint — 進度報告
🎉 Completed — 全部完成
🔴 Failed — 連續失敗停止
🛑 Stopped — 手動停止
```

---

## 🌙 Sleep Mode 使用方式

```bash
# 1. 建立專用分支
git checkout -b auto/my-feature

# 2. 啟動（記得設定好 ntfy）
./sleep-safe-runner.sh "build-my-feature"

# 3. 去睡覺 💤
```

---

**Made for Hans Lin @ Group.G** 🎬
