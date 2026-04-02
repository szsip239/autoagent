#!/usr/bin/env bash
# Stop hook — 合并 check-notepads + check-skills + sync-clawteam
# Claude Code 通过 stdin 传 JSON，必须消费 stdin 并输出 JSON
# 信息性输出到 stderr，不阻塞退出

INPUT=$(cat)
PROJECT_DIR="$(pwd)"
MESSAGES=""

# 1. 检查 required-skills 是否被调用
REQUIRED_FILE="$PROJECT_DIR/.required-skills"
LOG_FILE="$PROJECT_DIR/.skill-invocations.log"

if [[ -f "$REQUIRED_FILE" ]] && [[ -f "$LOG_FILE" ]]; then
  missing=""
  while IFS= read -r skill; do
    [[ "$skill" =~ ^#.*$ ]] && continue
    [[ -z "$skill" ]] && continue
    skill=$(echo "$skill" | xargs)
    if ! grep -q "$skill" "$LOG_FILE" 2>/dev/null; then
      missing="$missing $skill"
    fi
  done < "$REQUIRED_FILE"

  if [[ -n "$missing" ]]; then
    MESSAGES="${MESSAGES}必选 Skills 未调用:$missing\n"
  fi
fi

# 2. 检查 notepads/ 是否更新（代码变更时）
if [[ -d "$PROJECT_DIR/notepads" ]]; then
  code_changed=$(git diff --name-only HEAD 2>/dev/null | grep -v 'notepads/' | grep -v '\.md$' | head -1)
  if [[ -n "$code_changed" ]]; then
    notepad_changed=$(git diff --name-only HEAD 2>/dev/null | grep 'notepads/' | head -1)
    if [[ -z "$notepad_changed" ]]; then
      MESSAGES="${MESSAGES}代码有变更但 notepads/ 未更新，建议更新 learnings.md\n"
    fi
  fi
fi

# 3. 同步 ClawTeam 状态（静默）
if command -v clawteam >/dev/null 2>&1 && [[ -f "$PROJECT_DIR/Plans.md" ]]; then
  grep 'cc:完了' "$PROJECT_DIR/Plans.md" 2>/dev/null | while read -r line; do
    task_id=$(echo "$line" | grep -oE 'task-[0-9]+' | head -1)
    if [[ -n "$task_id" ]]; then
      clawteam task update "$task_id" -s completed 2>/dev/null || true
    fi
  done
fi

# 输出提醒（通过 JSON description 字段）
if [[ -n "$MESSAGES" ]]; then
  DESC=$(echo -e "$MESSAGES" | head -3 | tr '\n' ' ')
  echo "{\"description\":\"⚠️ $DESC\"}"
else
  echo '{}'
fi
