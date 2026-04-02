#!/usr/bin/env bash
# check-notepads.sh — Claude Code Stop hook
# 检查：有代码变更但 notepads/ 未更新 → 提醒 Worker
set -euo pipefail

INPUT=$(cat)
PROJECT_DIR="$(pwd)"

# 非项目目录或无 notepads/ → 静默通过
if [[ ! -d "$PROJECT_DIR/notepads" ]]; then
  echo '{}'
  exit 0
fi

# 检查代码变更（排除 notepads/ 自身）
CODE_CHANGES=$(git diff --name-only HEAD 2>/dev/null | grep -v '^notepads/' | head -5 || true)
if [[ -z "$CODE_CHANGES" ]]; then
  echo '{}'
  exit 0
fi

# 检查 notepads 是否有更新
NOTEPAD_CHANGES=$(git diff --name-only HEAD -- notepads/ 2>/dev/null || true)
if [[ -z "$NOTEPAD_CHANGES" ]]; then
  printf '{"systemMessage":"[check-notepads] 你有代码变更但未更新 notepads/。请在 notepads/learnings.md 中记录本次实验结论再结束。(soul.md #7: 经验必须流通)"}\n'
  exit 0
fi

echo '{}'
