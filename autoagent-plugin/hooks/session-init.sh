#!/usr/bin/env bash
# SessionStart hook — 检测项目状态，输出提示
# 不阻塞，仅信息性输出
# 注意：此脚本从 cache 目录运行，不能依赖相对路径推导项目位置
# 使用 pwd（Claude Code 的工作目录）检测 autoagent 项目

PROJECT_DIR="$(pwd)/project"

# 检测是否在 autoagent 项目中（pwd 下有 project/ 和 soul.md）
if [[ ! -d "$PROJECT_DIR" ]] || [[ ! -f "$(pwd)/soul.md" ]]; then
  exit 0
fi

# 统计项目状态
active=0
total=0
for state in "$PROJECT_DIR"/*/STATE.json; do
  [[ -f "$state" ]] || continue
  total=$((total + 1))
  name=$(basename "$(dirname "$state")")
  status=$(jq -r '.layers["4"].status // "pending"' "$state" 2>/dev/null)
  if [[ "$status" != "passed" ]]; then
    active=$((active + 1))
  fi
done

if [[ $total -eq 0 ]]; then
  echo "📍 AutoAgent: 无活跃项目。输入 /aa <project-name> 开始新项目。"
else
  echo "📍 AutoAgent: $active 个活跃项目 / $total 个总计。输入 /aa 查看状态。"
fi
