#!/bin/bash
# ============================================
# 🚀 Hans Sleep YOLO Mode - 一鍵安裝腳本
# ============================================

set -e

# 顏色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   🚀 Hans Sleep YOLO Mode 安裝程式       ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""

# 取得腳本所在目錄
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_DIR="$(pwd)"

# 檢查是否在專案目錄
if [ "$SCRIPT_DIR" = "$CURRENT_DIR" ]; then
    echo -e "${RED}❌ 請在你的專案目錄執行此腳本${NC}"
    echo ""
    echo "使用方式："
    echo "  cd ~/Projects/你的專案"
    echo "  bash ~/hans-sleep-yolo-mode/install.sh"
    exit 1
fi

echo -e "${BLUE}📁 安裝到: $CURRENT_DIR${NC}"
echo ""

# 檢查是否已安裝
if [ -f "CLAUDE.md" ]; then
    echo -e "${YELLOW}⚠️  偵測到已存在 CLAUDE.md${NC}"
    read -p "要覆蓋嗎？[y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "已取消"
        exit 0
    fi
fi

# 複製檔案
echo -e "${BLUE}📋 複製檔案...${NC}"
cp "$SCRIPT_DIR/CLAUDE.md" .
cp "$SCRIPT_DIR/sleep-safe-runner.sh" .
mkdir -p .claude/skills/autonomous-skill
cp "$SCRIPT_DIR/.claude/settings.json" .claude/
cp "$SCRIPT_DIR/.claude/skills/autonomous-skill/SKILL.md" .claude/skills/autonomous-skill/

# 給執行權限
chmod +x sleep-safe-runner.sh

# 更新 .gitignore
if [ -f ".gitignore" ]; then
    if ! grep -q "\.autonomous/" .gitignore 2>/dev/null; then
        echo "" >> .gitignore
        echo "# Claude Code autonomous tasks" >> .gitignore
        echo ".autonomous/" >> .gitignore
    fi
else
    echo "# Claude Code autonomous tasks" > .gitignore
    echo ".autonomous/" >> .gitignore
fi

echo ""
echo -e "${GREEN}✅ 安裝完成！${NC}"
echo ""
echo "已安裝："
echo "  📄 CLAUDE.md"
echo "  📄 sleep-safe-runner.sh"
echo "  📁 .claude/"
echo ""
echo -e "${YELLOW}📱 下一步：設定通知${NC}"
echo ""
echo "1. 手機下載 ntfy app"
echo "2. 訂閱一個頻道（例如 my-claude-notify）"
echo "3. 編輯 sleep-safe-runner.sh："
echo "   NTFY_TOPIC=\"你的頻道名\""
echo ""
echo -e "${BLUE}🚀 啟動方式${NC}"
echo ""
echo "  claude --dangerously-skip-permissions"
echo ""
echo "或設定 alias（只需一次）："
echo "  echo 'alias yolo=\"claude --dangerously-skip-permissions\"' >> ~/.zshrc"
echo "  source ~/.zshrc"
echo ""
echo "然後只要打 yolo 就能啟動！"
echo ""
