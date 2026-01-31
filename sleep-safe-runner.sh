#!/bin/bash
# ============================================
# 🌙 Sleep-Safe Autonomous Runner v3
# 全自動執行，可以安心睡覺
# ============================================

set -euo pipefail

# ============ 配置區 ============
TASK_NAME="${1:-my-task}"
MAX_ITERATIONS="${2:-100}"           # 最大循環次數
MAX_CONSECUTIVE_FAILURES=5           # 連續失敗上限（提高容錯）
SLEEP_BETWEEN_SESSIONS=5             # 執行間隔（秒）
MAX_SESSION_MINUTES=45               # 單次 session 超時（分鐘）
MAX_TURNS=100                        # Claude 每次最大 turns（提高）
CHECKPOINT_EVERY=3                   # 每 N 輪自動 commit
LOG_DIR=".autonomous/$TASK_NAME/logs"
TASK_FILE=".autonomous/$TASK_NAME/task_list.md"

# ============ 通知設定 ============

# 🥇 LINE Messaging API（台灣推薦，免費 200 則/月）
LINE_CHANNEL_ACCESS_TOKEN=""
LINE_USER_ID=""

# 🥈 Telegram Bot（免費無限）
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""

# 🥉 ntfy.sh（最簡單，免費）
NTFY_TOPIC=""

# Discord / Slack
DISCORD_WEBHOOK=""
SLACK_WEBHOOK=""

# ============ 顏色定義 ============
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============ 初始化 ============
mkdir -p "$LOG_DIR"
FAILURE_COUNT=0
ITERATION=0
START_TIME=$(date +%s)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
    local level="${2:-INFO}"
    local color="$NC"
    case "$level" in
        INFO) color="$CYAN" ;;
        SUCCESS) color="$GREEN" ;;
        WARN) color="$YELLOW" ;;
        ERROR) color="$RED" ;;
    esac
    echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')] [$level]${NC} $1" | tee -a "$LOG_DIR/runner.log"
}

# ============ 通知函數 ============
notify() {
    local message="$1"
    local emoji="${2:-🤖}"
    local full_message="$emoji [$TASK_NAME] $message"
    
    log "📢 Sending notification: $message" "INFO"
    
    # LINE Messaging API
    if [[ -n "${LINE_CHANNEL_ACCESS_TOKEN:-}" && -n "${LINE_USER_ID:-}" ]]; then
        curl -s -X POST "https://api.line.me/v2/bot/message/push" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $LINE_CHANNEL_ACCESS_TOKEN" \
            -d "{\"to\": \"$LINE_USER_ID\", \"messages\": [{\"type\": \"text\", \"text\": \"$full_message\"}]}" \
            > /dev/null 2>&1 || log "LINE notification failed" "WARN"
    fi
    
    # Telegram
    if [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]]; then
        curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
            -d "chat_id=$TELEGRAM_CHAT_ID" \
            -d "text=$full_message" \
            > /dev/null 2>&1 || log "Telegram notification failed" "WARN"
    fi
    
    # ntfy.sh
    if [[ -n "${NTFY_TOPIC:-}" ]]; then
        curl -s -X POST "https://ntfy.sh/$NTFY_TOPIC" \
            -H "Title: Claude Code 🤖" \
            -H "Priority: default" \
            -d "$full_message" \
            > /dev/null 2>&1 || log "ntfy notification failed" "WARN"
    fi
    
    # Discord
    if [[ -n "${DISCORD_WEBHOOK:-}" ]]; then
        curl -s -X POST "$DISCORD_WEBHOOK" \
            -H "Content-Type: application/json" \
            -d "{\"content\": \"$full_message\"}" \
            > /dev/null 2>&1 || log "Discord notification failed" "WARN"
    fi
    
    # Slack
    if [[ -n "${SLACK_WEBHOOK:-}" ]]; then
        curl -s -X POST "$SLACK_WEBHOOK" \
            -H "Content-Type: application/json" \
            -d "{\"text\": \"$full_message\"}" \
            > /dev/null 2>&1 || log "Slack notification failed" "WARN"
    fi
}

# ============ Git 操作 ============
checkpoint() {
    log "📸 Creating checkpoint..." "INFO"
    git add -A 2>/dev/null || true
    git commit -m "🤖 auto-checkpoint: iteration $ITERATION [$(get_progress)]" --no-verify 2>/dev/null || true
}

ensure_branch() {
    local current_branch=$(git branch --show-current 2>/dev/null || echo "")
    if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
        log "⚠️  Currently on $current_branch branch, creating auto branch..." "WARN"
        git checkout -b "auto/$TASK_NAME-$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
    fi
}

# ============ 進度追蹤 ============
get_progress() {
    if [[ -f "$TASK_FILE" ]]; then
        local total=$(grep -c '^\s*- \[' "$TASK_FILE" 2>/dev/null || echo "0")
        local done=$(grep -c '^\s*- \[x\]' "$TASK_FILE" 2>/dev/null || echo "0")
        echo "$done/$total"
    else
        echo "0/0"
    fi
}

check_completion() {
    if [[ -f "$TASK_FILE" ]]; then
        local total=$(grep -c '^\s*- \[' "$TASK_FILE" 2>/dev/null || echo "0")
        local done=$(grep -c '^\s*- \[x\]' "$TASK_FILE" 2>/dev/null || echo "0")
        [[ "$total" -gt 0 && "$done" -eq "$total" ]]
    else
        return 1
    fi
}

# ============ 清理函數 ============
cleanup() {
    local end_time=$(date +%s)
    local duration=$(( (end_time - START_TIME) / 60 ))
    
    log "🛑 Runner stopping..." "WARN"
    checkpoint
    notify "Runner stopped after $ITERATION iterations (${duration}m). Progress: $(get_progress)" "🛑"
    
    exit 0
}

trap cleanup SIGINT SIGTERM SIGHUP

# ============ 前置檢查 ============
preflight_check() {
    log "🔍 Running preflight checks..." "INFO"
    
    # 檢查 Claude CLI
    if ! command -v claude &> /dev/null; then
        log "❌ Claude CLI not found. Install with: npm install -g @anthropic-ai/claude-code" "ERROR"
        exit 1
    fi
    
    # 檢查 Git
    if ! git rev-parse --git-dir &> /dev/null; then
        log "❌ Not a git repository" "ERROR"
        exit 1
    fi
    
    # 確保不在 main/master
    ensure_branch
    
    # 檢查通知設定
    if [[ -z "${LINE_CHANNEL_ACCESS_TOKEN:-}" && -z "${TELEGRAM_BOT_TOKEN:-}" && -z "${NTFY_TOPIC:-}" && -z "${DISCORD_WEBHOOK:-}" && -z "${SLACK_WEBHOOK:-}" ]]; then
        log "⚠️  No notification method configured!" "WARN"
        echo ""
        echo "建議設定通知，編輯此腳本填入："
        echo "  LINE_CHANNEL_ACCESS_TOKEN 和 LINE_USER_ID"
        echo "  或 TELEGRAM_BOT_TOKEN 和 TELEGRAM_CHAT_ID"
        echo "  或 NTFY_TOPIC"
        echo ""
        read -p "繼續執行嗎（不會收到通知）？[y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    log "✅ Preflight checks passed" "SUCCESS"
}

# ============ 初始化任務 ============
init_task() {
    if [[ ! -f "$TASK_FILE" ]]; then
        log "📝 Initializing task: $TASK_NAME" "INFO"
        
        # 讓 Claude 初始化任務
        claude -p \
            "Initialize autonomous task '$TASK_NAME'. 
             Create .autonomous/$TASK_NAME/task_list.md with a detailed task breakdown.
             Use checkbox format: - [ ] Task description
             Also create .autonomous/$TASK_NAME/progress.md for notes.
             Be thorough - break down into 10-30 small, specific tasks." \
            --dangerously-skip-permissions \
            --max-turns 20 \
            > "$LOG_DIR/init.log" 2>&1 || true
        
        if [[ -f "$TASK_FILE" ]]; then
            log "✅ Task initialized with $(grep -c '^\s*- \[' "$TASK_FILE" || echo 0) tasks" "SUCCESS"
        else
            log "❌ Failed to initialize task" "ERROR"
            exit 1
        fi
    else
        log "📋 Resuming existing task: $(get_progress) completed" "INFO"
    fi
}

# ============ 主循環 ============
main() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     🌙 Sleep-Safe Autonomous Runner v3               ║${NC}"
    echo -e "${GREEN}║     Task: ${CYAN}$TASK_NAME${GREEN}                              ${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    preflight_check
    init_task
    
    log "🚀 Starting autonomous runner" "SUCCESS"
    notify "Started autonomous task. Progress: $(get_progress)" "🚀"
    
    while [[ $ITERATION -lt $MAX_ITERATIONS ]]; do
        ITERATION=$((ITERATION + 1))
        
        echo ""
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "INFO"
        log "📍 Iteration $ITERATION / $MAX_ITERATIONS" "INFO"
        log "📊 Progress: $(get_progress)" "INFO"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "INFO"
        
        SESSION_LOG="$LOG_DIR/session_$(printf '%03d' $ITERATION).log"
        
        # 執行 Claude
        if timeout ${MAX_SESSION_MINUTES}m claude -p \
            "You are continuing autonomous task '$TASK_NAME'.

INSTRUCTIONS:
1. Read .autonomous/$TASK_NAME/task_list.md
2. Find the FIRST uncompleted task (marked with - [ ])
3. Complete that task fully
4. Mark it done by changing - [ ] to - [x]
5. Update .autonomous/$TASK_NAME/progress.md with what you did
6. If blocked, document why and move to next task

RULES:
- Complete 1-3 tasks per session
- Never ask questions - make decisions
- Fix errors without asking
- Test your work before marking done
- Commit changes with descriptive messages

Current progress: $(get_progress)" \
            --dangerously-skip-permissions \
            --max-turns $MAX_TURNS \
            > "$SESSION_LOG" 2>&1; then
            
            FAILURE_COUNT=0
            log "✅ Session completed successfully" "SUCCESS"
        else
            EXIT_CODE=$?
            if [[ $EXIT_CODE -eq 124 ]]; then
                log "⏰ Session timed out (${MAX_SESSION_MINUTES}m)" "WARN"
            else
                log "❌ Session failed (exit code: $EXIT_CODE)" "ERROR"
            fi
            FAILURE_COUNT=$((FAILURE_COUNT + 1))
        fi
        
        # 檢查連續失敗
        if [[ $FAILURE_COUNT -ge $MAX_CONSECUTIVE_FAILURES ]]; then
            log "🔴 Too many consecutive failures ($FAILURE_COUNT)" "ERROR"
            notify "Stopped: $MAX_CONSECUTIVE_FAILURES consecutive failures. Progress: $(get_progress)" "🔴"
            checkpoint
            break
        fi
        
        # 檢查完成
        if check_completion; then
            log "🎉 All tasks completed!" "SUCCESS"
            notify "All tasks completed! 🎉 Total iterations: $ITERATION" "🎉"
            checkpoint
            break
        fi
        
        # 定期 checkpoint
        if [[ $((ITERATION % CHECKPOINT_EVERY)) -eq 0 ]]; then
            checkpoint
            notify "Checkpoint #$ITERATION. Progress: $(get_progress)" "📊"
        fi
        
        log "💤 Sleeping ${SLEEP_BETWEEN_SESSIONS}s..." "INFO"
        sleep $SLEEP_BETWEEN_SESSIONS
    done
    
    # 最終報告
    checkpoint
    local elapsed=$(( ($(date +%s) - START_TIME) / 60 ))
    log "🏁 Runner finished. Iterations: $ITERATION, Duration: ${elapsed}m, Progress: $(get_progress)" "SUCCESS"
    notify "Runner finished. Duration: ${elapsed}m, Progress: $(get_progress)" "🏁"
}

# ============ 執行 ============
main "$@"
