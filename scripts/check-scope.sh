#!/usr/bin/env bash
# check-scope.sh — 范围偏离检测（信息性，不阻塞）
# 用法: check-scope.sh <project> <task-id>
# 输出: DoD + git diff 摘要，供 Agent 自行判断是否偏离
set -euo pipefail

AUTOAGENT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_DIR="$AUTOAGENT_ROOT/project"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ $# -lt 2 ]]; then
  echo "用法: check-scope.sh <project> <task-id>"
  echo "  从 Plans.md 提取 DoD，对照 git diff，输出偏离分析"
  exit 1
fi

project="$1"
task_id="$2"
pdir="$PROJECT_DIR/$project"
plans="$pdir/Plans.md"

# --- 提取 DoD ---
if [[ ! -f "$plans" ]]; then
  echo -e "${RED}Plans.md 不存在: $plans${NC}" >&2
  exit 1
fi

# Plans.md 表格: | Task | 内容 | DoD | Depends | Owner | Status |
task_row=$(grep -E "^\| *${task_id} *\|" "$plans" 2>/dev/null | head -1)
if [[ -z "$task_row" ]]; then
  echo -e "${RED}未找到 Task: $task_id${NC}" >&2
  exit 1
fi

task_content=$(echo "$task_row" | awk -F'|' '{gsub(/^ +| +$/, "", $3); print $3}')
task_dod=$(echo "$task_row" | awk -F'|' '{gsub(/^ +| +$/, "", $4); print $4}')
task_owner=$(echo "$task_row" | awk -F'|' '{gsub(/^ +| +$/, "", $6); print $6}')

echo -e "${BLUE}=== Task $task_id 范围检查 ===${NC}"
echo ""
echo -e "${BLUE}内容:${NC} $task_content"
echo -e "${BLUE}DoD:${NC}  $task_dod"
echo -e "${BLUE}Owner:${NC} $task_owner"
echo ""

# --- git diff ---
if [[ ! -d "$pdir/.git" ]]; then
  echo -e "${YELLOW}项目无 .git，跳过 diff 分析${NC}"
  exit 0
fi

echo -e "${BLUE}=== 最近 commit 变更 ===${NC}"
echo ""

# 最近一次 commit 信息
git -C "$pdir" log --oneline -1 2>/dev/null || true
echo ""

# 变更文件列表
diff_stat=$(git -C "$pdir" diff --stat HEAD~1 2>/dev/null || git -C "$pdir" diff --stat 2>/dev/null || echo "(无变更)")
echo "$diff_stat"
echo ""

# 变更文件名（纯列表，供对比）
changed_files=$(git -C "$pdir" diff --name-only HEAD~1 2>/dev/null || git -C "$pdir" diff --name-only 2>/dev/null || true)

echo -e "${BLUE}=== 偏离分析 ===${NC}"
echo ""
echo -e "DoD: ${GREEN}$task_dod${NC}"
echo -e "变更文件:"
if [[ -n "$changed_files" ]]; then
  echo "$changed_files" | while read -r f; do echo "  - $f"; done
else
  echo "  (无变更)"
fi
echo ""
echo -e "${YELLOW}请对照 DoD 确认：变更是否在范围内？是否有遗漏？${NC}"
