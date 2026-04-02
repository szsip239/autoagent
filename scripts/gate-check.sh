#!/usr/bin/env bash
#
# gate-check.sh — AutoAgent 五层门控检查
#
# 用法:
#   gate-check.sh <project-name> check [layer]   检查指定层的门控条件（默认当前层）
#   gate-check.sh <project-name> pass  [layer]    标记人工确认通过
#   gate-check.sh <project-name> fail  [layer]    标记门控失败 + 回退路由
#   gate-check.sh <project-name> status            显示项目状态
#   gate-check.sh <project-name> init              初始化项目状态文件
#
# 依赖: jq, clawteam (可选)

set -euo pipefail

AUTOAGENT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_DIR="$AUTOAGENT_ROOT/project"

# --- 颜色 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- 工具函数 ---
now() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

die() { echo -e "${RED}ERROR: $1${NC}" >&2; exit 1; }

require_jq() {
  command -v jq >/dev/null 2>&1 || die "需要安装 jq: brew install jq"
}

# macOS/Linux 兼容 md5
calc_md5() {
  if command -v md5sum >/dev/null 2>&1; then
    md5sum "$1" | awk '{print $1}'
  elif command -v md5 >/dev/null 2>&1; then
    md5 -q "$1"
  else
    echo "no-md5-tool"
  fi
}

state_file() {
  echo "$PROJECT_DIR/$1/STATE.json"
}

# --- 事件日志 (gate-events.jsonl) ---
# 每次 check/pass/fail/reassess-done 自动追加一条记录
# 项目结束后 RETRO.md 从这个文件生成统计
log_gate_event() {
  local project="$1"
  local cmd="$2"
  local layer="$3"
  shift 3
  # 剩余参数作为 JSON 键值对: key1 val1 key2 val2 ...
  local logfile="$PROJECT_DIR/$project/gate-events.jsonl"
  local ts
  ts="$(now)"

  # 构建基础 JSON
  local json
  json=$(jq -n --arg at "$ts" --arg cmd "$cmd" --arg layer "$layer" \
    '{at: $at, cmd: $cmd, layer: ($layer | tonumber)}')

  # 追加额外字段
  while [[ $# -ge 2 ]]; do
    local key="$1" val="$2"
    shift 2
    json=$(echo "$json" | jq --arg k "$key" --arg v "$val" '. + {($k): $v}')
  done

  echo "$json" | jq -c '.' >> "$logfile" 2>/dev/null || true
}

read_state() {
  local sf
  sf="$(state_file "$1")"
  [[ -f "$sf" ]] || die "STATE.json 不存在，先运行: gate-check.sh $1 init"
  cat "$sf"
}

write_state() {
  local sf
  sf="$(state_file "$1")"
  echo "$2" | jq '.' > "$sf"
}

current_layer() {
  read_state "$1" | jq -r '.current_layer'
}

# --- 命令: init ---
cmd_init() {
  local project="$1"
  local pdir="$PROJECT_DIR/$project"
  local sf="$pdir/STATE.json"

  [[ -d "$pdir" ]] || die "项目目录不存在: $pdir"

  if [[ -f "$sf" ]]; then
    echo -e "${YELLOW}STATE.json 已存在，跳过初始化${NC}"
    return 0
  fi

  # 从模板生成
  local ts
  ts="$(now)"
  jq --arg p "$project" --arg t "$ts" \
    '.project = $p | .created_at = $t | .layers["0"].status = "active" | .layers["0"].entered_at = $t' \
    "$AUTOAGENT_ROOT/templates/STATE.json" > "$sf"

  echo -e "${GREEN}已初始化 STATE.json: $sf${NC}"

  # === notepads 初始化 ===
  local notepads_dir="$pdir/notepads"
  if [[ ! -d "$notepads_dir" ]]; then
    mkdir -p "$notepads_dir"
    for f in learnings.md decisions.md issues.md problems.md; do
      cat > "$notepads_dir/$f" << NOTEPAD
# ${f%.md}

> Worker 共享记忆文件。只追加，不删除。
> 格式: \`## [日期] Task: {task-id} by {worker-name}\`

NOTEPAD
    done
    echo -e "${GREEN}已创建 notepads/（learnings/decisions/issues/problems）${NC}"
  fi

  # === OV 配置诊断 (v0.2.11+) ===
  local ov_cmd="$HOME/.openviking/venv/bin/ov"
  if [[ -x "$ov_cmd" ]]; then
    "$ov_cmd" doctor 2>/dev/null && echo -e "${GREEN}OV doctor: 配置正常${NC}" \
      || echo -e "${YELLOW}OV doctor: 有配置问题，请检查 ov doctor 输出${NC}"
  fi

  # === OV 历史经验注入 ===
  if [[ -x "$ov_cmd" ]]; then
    local inherited="$notepads_dir/inherited.md"
    echo "# 历史项目经验（从 OV 自动注入）" > "$inherited"
    echo "" >> "$inherited"
    "$ov_cmd" find "$project" --uri "viking://resources/cases/" 2>/dev/null >> "$inherited" \
      || echo "(OV 无匹配或不可用)" >> "$inherited"
    echo -e "${GREEN}已从 OV 注入历史经验 → notepads/inherited.md${NC}"
  fi

  # === hooks 注册 ===
  local claude_dir="$pdir/.claude"
  local settings_file="$claude_dir/settings.json"
  if [[ ! -f "$settings_file" ]]; then
    mkdir -p "$claude_dir"
    cat > "$settings_file" << 'HOOKS'
{
  "hooks": {
    "Stop": [
      {
        "type": "command",
        "command": "bash ${AUTOAGENT_ROOT}/scripts/check-notepads.sh"
      },
      {
        "type": "command",
        "command": "bash ${AUTOAGENT_ROOT}/scripts/sync-clawteam.sh"
      },
      {
        "type": "command",
        "command": "bash ${AUTOAGENT_ROOT}/scripts/check-skills.sh"
      }
    ],
    "PostToolUse": [
      {
        "type": "command",
        "command": "bash ${AUTOAGENT_ROOT}/scripts/track-skill.sh",
        "matcher": "Skill"
      }
    ],
    "PreToolUse": [
      {
        "type": "command",
        "command": "bash ${AUTOAGENT_ROOT}/scripts/check-careful.sh",
        "matcher": "Bash"
      }
    ]
  }
}
HOOKS
    # 替换 AUTOAGENT_ROOT 为实际路径
    sed -i'' -e "s|\${AUTOAGENT_ROOT}|${AUTOAGENT_ROOT}|g" "$settings_file"
    echo -e "${GREEN}已注册 hooks → .claude/settings.json (Stop×3 + PostToolUse×1 + PreToolUse×1)${NC}"
  fi

  # === ISS-041: 必选 Skills 清单生成 ===
  local required_skills="$pdir/.required-skills"
  if [[ ! -f "$required_skills" ]]; then
    cat > "$required_skills" << 'SKILLS'
# 必选 Skills — Worker 退出时 check-skills.sh 会检查
# 每行一个 skill 名（与 /skill-name 中的 name 一致）
# 由 gate-check init 生成，Leader 可根据项目需求增删
docs
security-review
# 以下按项目类型启用（去掉 # 注释）:
# frontend-design    # 含前端的项目
# tdd                # 需要测试驱动的项目
# api-design         # 含 REST API 的项目
SKILLS
    echo -e "${GREEN}已生成 .required-skills（必选 Skills 清单，可编辑）${NC}"
  fi

  # === git 初始化 ===
  if [[ ! -d "$pdir/.git" ]]; then
    git -C "$pdir" init -q
    git -C "$pdir" add -A
    git -C "$pdir" commit -q -m "init: 项目初始化 by gate-check"
    echo -e "${GREEN}已初始化 git 仓库 + 初始 commit${NC}"
  fi

  # 自动扫描已有产物
  cmd_check "$project" 0
}

# --- 命令: status ---
cmd_status() {
  local project="$1"
  local state
  state="$(read_state "$project")"
  local cl
  cl="$(echo "$state" | jq -r '.current_layer')"

  echo -e "${BLUE}=== 项目: $project ===${NC}"
  echo -e "当前层: Layer $cl"
  echo ""

  for layer in 0 1 2 3 4; do
    local ls
    ls="$(echo "$state" | jq -r ".layers[\"$layer\"].status")"
    local icon
    case "$ls" in
      passed)  icon="${GREEN}✅${NC}" ;;
      active)  icon="${YELLOW}🔶${NC}" ;;
      failed)  icon="${RED}❌${NC}" ;;
      pending) icon="⬜" ;;
      *)       icon="❓" ;;
    esac

    local layer_names=("需求+数据" "技术选型" "实现" "评估" "交付")
    echo -e "  Layer $layer ${layer_names[$layer]}: $icon $ls"

    # 显示门控条件
    if [[ "$ls" == "active" ]]; then
      echo "$state" | jq -r ".layers[\"$layer\"].gate_conditions | to_entries[] | \"    ├─ \(.key): \(if .value then \"✅\" else \"⬜\" end)\"" 2>/dev/null
    fi
  done

  echo ""

  # 显示历史
  local hcount
  hcount="$(echo "$state" | jq '.history | length')"
  if [[ "$hcount" -gt 0 ]]; then
    echo -e "${BLUE}最近事件:${NC}"
    echo "$state" | jq -r '.history[-5:][] | "  [\(.at)] \(.event)"'
  fi
}

# --- 命令: check ---
cmd_check() {
  local project="$1"
  local layer="${2:-$(current_layer "$project")}"
  local state
  state="$(read_state "$project")"

  echo -e "${BLUE}检查 Layer $layer 门控条件...${NC}"

  local pdir="$PROJECT_DIR/$project"
  local all_pass=true
  local results=()

  case "$layer" in
    0)
      # Layer 0: 需求 + 数据
      # 条件1: REQUIREMENTS.md 存在且非空
      if [[ -s "$pdir/REQUIREMENTS.md" ]]; then
        state="$(echo "$state" | jq '.layers["0"].artifacts["REQUIREMENTS.md"] = true')"
        results+=("${GREEN}✅ REQUIREMENTS.md 存在${NC}")

        # ISS-019: 内容质量检查
        local req_sections=0
        grep -qi 'Must Have\|必须满足' "$pdir/REQUIREMENTS.md" 2>/dev/null && req_sections=$((req_sections+1))
        grep -qi 'Evaluation Criteria\|评估标准' "$pdir/REQUIREMENTS.md" 2>/dev/null && req_sections=$((req_sections+1))
        grep -qi '约束\|Constraint' "$pdir/REQUIREMENTS.md" 2>/dev/null && req_sections=$((req_sections+1))
        if [[ $req_sections -ge 2 ]]; then
          results+=("${GREEN}✅ REQUIREMENTS.md 内容完整 ($req_sections/3 关键章节)${NC}")
        else
          all_pass=false
          results+=("${RED}⬜ REQUIREMENTS.md 内容不完整（需含 Must Have + Evaluation Criteria + 约束，当前 $req_sections/3）${NC}")
        fi
      else
        all_pass=false
        results+=("${RED}⬜ REQUIREMENTS.md 缺失或为空${NC}")
      fi

      # 条件2: DATA_QUALITY.md
      # 有数据的项目必须有；仅当数据清单明确标注"无"或"纯逻辑"时跳过
      if [[ -s "$pdir/DATA_QUALITY.md" ]]; then
        state="$(echo "$state" | jq '.layers["0"].artifacts["DATA_QUALITY.md"] = true')"
        results+=("${GREEN}✅ DATA_QUALITY.md 存在${NC}")
      else
        # 严格检查：数据清单章节中明确写了"无（纯逻辑项目）"
        if grep -q "^## 数据清单" "$pdir/REQUIREMENTS.md" 2>/dev/null && \
           grep -A2 "^## 数据清单" "$pdir/REQUIREMENTS.md" 2>/dev/null | grep -qi "无（纯逻辑"; then
          state="$(echo "$state" | jq '.layers["0"].gate_conditions.no_red_blockers = true')"
          results+=("${YELLOW}⏭️  DATA_QUALITY.md 不适用（纯逻辑项目）${NC}")
        else
          all_pass=false
          results+=("${RED}⬜ DATA_QUALITY.md 缺失（有数据的项目必须提供）${NC}")
        fi
      fi

      # 条件3: 用户确认（需要手动 pass）
      local confirmed
      confirmed="$(echo "$state" | jq -r '.layers["0"].gate_conditions.requirements_confirmed')"
      if [[ "$confirmed" == "true" ]]; then
        results+=("${GREEN}✅ 用户已确认需求${NC}")
      else
        all_pass=false
        results+=("${YELLOW}⏳ 等待用户确认（运行: gate-check.sh $project pass 0）${NC}")
      fi
      ;;

    0.5)
      # Layer 0.5: TC 创建与审核
      # TC 由 tc-creator agent 生成，写入 REQUIREMENTS.md 的 TC 章节

      # 条件1: REQUIREMENTS.md 中有 TC 章节
      if grep -qiE 'TC-|F[0-9]+-TC|Test Case|验收测试' "$pdir/REQUIREMENTS.md" 2>/dev/null; then
        state="$(echo "$state" | jq '.layers["0.5"].gate_conditions.tc_exists = true')"
        local tc_count
        tc_count="$(grep -coE 'TC-[A-Z0-9]+|F[0-9]+-TC[0-9]+' "$pdir/REQUIREMENTS.md" 2>/dev/null | awk '{s+=$1}END{print s+0}')"
        results+=("${GREEN}✅ TC 已存在（$tc_count 条）${NC}")
      else
        all_pass=false
        results+=("${RED}⬜ REQUIREMENTS.md 中无 TC 章节（需运行 tc-creator 或手动编写）${NC}")
      fi

      # 条件2: 覆盖矩阵完整性（P0 功能 ≥5 TC）
      local p0_features p0_under
      p0_features="$(grep -cE '^\|.*P0' "$pdir/REQUIREMENTS.md" 2>/dev/null || echo 0)"
      if [[ "$p0_features" -gt 0 ]]; then
        state="$(echo "$state" | jq '.layers["0.5"].gate_conditions.coverage_matrix_complete = true')"
        results+=("${GREEN}✅ P0 功能已定义（$p0_features 个）${NC}")
      else
        results+=("${YELLOW}⚠️  未检测到 P0 功能定义${NC}")
      fi

      # 条件3: 等待用户审核
      local tc_reviewed
      tc_reviewed="$(echo "$state" | jq -r '.layers["0.5"].gate_conditions.user_reviewed')"
      if [[ "$tc_reviewed" == "true" ]]; then
        results+=("${GREEN}✅ 用户已审核 TC${NC}")
      else
        all_pass=false
        results+=("${YELLOW}⏳ 等待用户审核 TC（运行: gate-check.sh $project pass 0.5）${NC}")
      fi
      ;;

    1)
      # Layer 1: 技术选型（调研 + POC）

      # ISS-055: RESEARCH_REPORT.md 存在性
      if [[ -s "$pdir/RESEARCH_REPORT.md" ]]; then
        state="$(echo "$state" | jq '.layers["1"].artifacts["RESEARCH_REPORT.md"] = true')"
        results+=("${GREEN}✅ RESEARCH_REPORT.md 存在${NC}")
      else
        all_pass=false
        results+=("${RED}⬜ RESEARCH_REPORT.md 缺失（调研报告必须先于 POC）${NC}")
      fi

      # ISS-055: 中文平台检索结果章节（强制）
      if grep -qi '中文平台检索\|CSDN\|知乎\|阿里云\|微信公众号\|jisu-wechat' "$pdir/RESEARCH_REPORT.md" 2>/dev/null; then
        results+=("${GREEN}✅ RESEARCH_REPORT.md 含中文平台检索结果${NC}")
      else
        all_pass=false
        results+=("${RED}⬜ RESEARCH_REPORT.md 缺少中文平台检索结果章节（ISS-055 强制项）${NC}")
      fi

      # ISS-056: POC 量化数据（≥10 次试验）
      if grep -qi 'n_trials\|success_rate\|试验次数\|成功率.*[0-9]\|有效性.*[0-9]\|AUC.*[0-9]\|accuracy.*[0-9]\|可执行\|POC.*耗时' "$pdir/TECH_SELECTION.md" 2>/dev/null; then
        results+=("${GREEN}✅ POC 量化数据已包含${NC}")
      else
        all_pass=false
        results+=("${RED}⬜ TECH_SELECTION.md 缺少 POC 量化数据（需 ≥10 次试验的 n_trials/success_rate）${NC}")
      fi

      if [[ -s "$pdir/TECH_SELECTION.md" ]]; then
        state="$(echo "$state" | jq '.layers["1"].artifacts["TECH_SELECTION.md"] = true')"
        results+=("${GREEN}✅ TECH_SELECTION.md 存在${NC}")
      else
        all_pass=false
        results+=("${RED}⬜ TECH_SELECTION.md 缺失${NC}")
      fi

      if [[ -s "$pdir/DECISIONS.md" ]]; then
        state="$(echo "$state" | jq '.layers["1"].artifacts["DECISIONS.md"] = true')"
        results+=("${GREEN}✅ DECISIONS.md 存在${NC}")
      else
        all_pass=false
        results+=("${RED}⬜ DECISIONS.md 缺失（选型决策必须记录）${NC}")
      fi

      # POC 数据对比
      if grep -qi "对比\|comparison\|benchmark\|POC\|方案.*得分\|验证结果" "$pdir/TECH_SELECTION.md" 2>/dev/null; then
        state="$(echo "$state" | jq '.layers["1"].gate_conditions.poc_data_compared = true')"
        results+=("${GREEN}✅ POC 对比数据已包含${NC}")
      else
        all_pass=false
        results+=("${RED}⬜ TECH_SELECTION.md 中未检测到 POC 对比数据${NC}")
      fi

      # ISS-033: POC 成本对比
      if grep -qi '成本\|cost\|费用\|预算\|budget' "$pdir/TECH_SELECTION.md" 2>/dev/null; then
        results+=("${GREEN}✅ POC 成本对比已包含${NC}")
      else
        all_pass=false
        results+=("${RED}⬜ TECH_SELECTION.md 缺少成本对比（POC 耗时/费用）${NC}")
      fi

      # 生产部署成本预估
      if grep -qi '生产.*成本\|部署.*成本\|月.*估算\|production.*cost' "$pdir/TECH_SELECTION.md" 2>/dev/null; then
        results+=("${GREEN}✅ 生产部署成本预估已包含${NC}")
      else
        results+=("${YELLOW}⚠️  TECH_SELECTION.md 缺少生产部署成本预估（Layer 4 交付时必须有）${NC}")
      fi

      # 推荐 Skills
      if grep -qi "推荐.*[Ss]kill\|Skills" "$pdir/TECH_SELECTION.md" 2>/dev/null; then
        results+=("${GREEN}✅ 推荐 Skills 已包含${NC}")
      else
        all_pass=false
        results+=("${RED}⬜ TECH_SELECTION.md 缺少推荐 Skills 章节${NC}")
      fi

      # 推荐领域 Agent
      if grep -qi "推荐.*[Aa]gent\|领域.*Agent" "$pdir/TECH_SELECTION.md" 2>/dev/null; then
        results+=("${GREEN}✅ 推荐领域 Agent 已包含${NC}")
      else
        all_pass=false
        results+=("${RED}⬜ TECH_SELECTION.md 缺少推荐领域 Agent 章节${NC}")
      fi

      # 用户确认
      local confirmed
      confirmed="$(echo "$state" | jq -r '.layers["1"].gate_conditions.user_confirmed')"
      if [[ "$confirmed" == "true" ]]; then
        results+=("${GREEN}✅ 用户已确认选型${NC}")
      else
        all_pass=false
        results+=("${YELLOW}⏳ 等待用户确认（运行: gate-check.sh $project pass 1）${NC}")
      fi
      ;;

    2)
      # Layer 2: 实现
      # 条件1: 编排文件存在（兼容旧版 ORCHESTRATION.md 和新版 ORCHESTRATION-leader.md）
      if [[ -s "$pdir/ORCHESTRATION-leader.md" ]]; then
        results+=("${GREEN}✅ ORCHESTRATION-leader.md 存在${NC}")
      elif [[ -s "$pdir/ORCHESTRATION.md" ]]; then
        results+=("${GREEN}✅ ORCHESTRATION.md 存在（旧版格式）${NC}")
      else
        all_pass=false
        results+=("${RED}⬜ ORCHESTRATION-leader.md 缺失（编排方案）${NC}")
      fi

      # ISS-007: ClawTeam team 已创建
      if command -v clawteam >/dev/null 2>&1; then
        if clawteam team status "$project" >/dev/null 2>&1; then
          results+=("${GREEN}✅ ClawTeam team '$project' 已创建${NC}")
        else
          results+=("${YELLOW}⚠️  ClawTeam team '$project' 未创建（可选）${NC}")
        fi
      fi

      # 条件2: Plans.md 存在且有 Owner 列
      if [[ -s "$pdir/Plans.md" ]]; then
        state="$(echo "$state" | jq '.layers["2"].artifacts["Plans.md"] = true')"
        results+=("${GREEN}✅ Plans.md 存在${NC}")

        # 检查 Owner 列 + 完整性
        if grep -q 'Owner\|owner' "$pdir/Plans.md" 2>/dev/null; then
          # ISS-006: 检查是否每个任务都分配了 Owner
          local empty_owner
          empty_owner="$(grep -E '^\|' "$pdir/Plans.md" | grep -v '^| *Task\|^| *---' | awk -F'|' '{gsub(/^ +| +$/,"",$6); if($6=="") print $2}' 2>/dev/null | head -5)"
          if [[ -z "$empty_owner" ]]; then
            results+=("${GREEN}✅ Plans.md 所有任务已分配 Owner${NC}")
          else
            all_pass=false
            results+=("${RED}⬜ Plans.md 以下任务未分配 Owner: $empty_owner${NC}")
          fi
        else
          all_pass=false
          results+=("${RED}⬜ Plans.md 缺少 Owner 列${NC}")
        fi

        # 统计未完成任务
        local todo_count
        todo_count="$(grep -c 'cc:TODO\|cc:WIP\|cc:blocked' "$pdir/Plans.md" 2>/dev/null)" || todo_count=0
        local done_count
        done_count="$(grep -c 'cc:完了' "$pdir/Plans.md" 2>/dev/null)" || done_count=0

        if [[ "$todo_count" -eq 0 && "$done_count" -gt 0 ]]; then
          state="$(echo "$state" | jq '.layers["2"].gate_conditions.all_tasks_done = true')"
          results+=("${GREEN}✅ 所有任务已完成 ($done_count 个)${NC}")
        else
          all_pass=false
          results+=("${RED}⬜ 未完成任务: $todo_count 个，已完成: $done_count 个${NC}")
        fi
      else
        all_pass=false
        results+=("${RED}⬜ Plans.md 缺失${NC}")
      fi
      ;;

    3)
      # Layer 3: 评估

      # ISS-032: eval/ md5 校验（pass 2 时 seal，check 3 时 verify）
      local sealed_md5
      sealed_md5="$(echo "$state" | jq -r '.eval_md5_seal // empty')"
      if [[ -n "$sealed_md5" && "$sealed_md5" != "null" ]]; then
        local tampered=false
        for ef in "$pdir"/eval/*.py; do
          [[ -f "$ef" ]] || continue
          local fname
          fname="$(basename "$ef")"
          local expected
          expected="$(echo "$sealed_md5" | jq -r --arg f "$fname" '.[$f] // "missing"')"
          local actual
          actual="$(calc_md5 "$ef")"
          if [[ "$expected" != "$actual" ]]; then
            tampered=true
            results+=("${RED}❌ eval/$fname md5 不匹配（已被修改！sealed=$expected actual=$actual）${NC}")
          fi
        done
        if $tampered; then
          all_pass=false
          results+=("${RED}❌ eval/ 评估脚本被篡改，Layer 3 结果不可信${NC}")
        else
          state="$(echo "$state" | jq '.layers["3"].gate_conditions.eval_integrity = true')"
          results+=("${GREEN}✅ eval/ md5 校验通过（未被篡改）${NC}")
        fi
      else
        results+=("${YELLOW}⚠️  无 eval/ md5 签名（Layer 2 pass 未记录，跳过校验）${NC}")
      fi

      if [[ -s "$pdir/EVAL_REPORT.md" ]]; then
        state="$(echo "$state" | jq '.layers["3"].artifacts["EVAL_REPORT.md"] = true')"
        results+=("${GREEN}✅ EVAL_REPORT.md 存在${NC}")

        # === VDD: TC 通过率分级门控 (ISS-045/051) ===
        # 解析通过率摘要表格（第 6 列 = 通过率，第 7 列 = 阈值）:
        # | 优先级 | TC 总数 | ✅ | ❌ | 通过率 | 阈值 | 结果 |
        # | P0     | 5      | 5  | 0  | 100%   | 100% | PASS |
        local p0_rate p1_rate
        p0_rate="$(grep -E '^\|\s*\*{0,2}P0' "$pdir/EVAL_REPORT.md" 2>/dev/null | awk -F'|' '{gsub(/[^0-9.]/, "", $6); if($6!="") print $6}' | head -1)"
        p1_rate="$(grep -E '^\|\s*\*{0,2}P1' "$pdir/EVAL_REPORT.md" 2>/dev/null | awk -F'|' '{gsub(/[^0-9.]/, "", $6); if($6!="") print $6}' | head -1)"

        if [[ -n "$p0_rate" ]]; then
          state="$(echo "$state" | jq --arg r "$p0_rate" '.layers["3"].tc_pass_rate.P0 = ($r | tonumber)')"
          if awk "BEGIN {exit !($p0_rate >= 100)}"; then
            state="$(echo "$state" | jq '.layers["3"].gate_conditions.p0_tc_100 = true')"
            results+=("${GREEN}✅ P0 TC 通过率: ${p0_rate}% (= 100%)${NC}")
          else
            all_pass=false
            results+=("${RED}❌ P0 TC 通过率: ${p0_rate}% (< 100%，P0 必须全部通过)${NC}")
          fi
        fi

        if [[ -n "$p1_rate" ]]; then
          state="$(echo "$state" | jq --arg r "$p1_rate" '.layers["3"].tc_pass_rate.P1 = ($r | tonumber)')"
          # P1 阈值从 REQUIREMENTS.md 读取，默认 80%
          local p1_threshold=80
          local req_threshold
          req_threshold="$(grep -A1 '| P1' "$pdir/REQUIREMENTS.md" 2>/dev/null | sed -n 's/.*| *\([0-9]*\)% *|.*/\1/p' | head -1)"
          [[ -n "$req_threshold" ]] && p1_threshold="$req_threshold"
          if awk "BEGIN {exit !($p1_rate >= $p1_threshold)}"; then
            state="$(echo "$state" | jq '.layers["3"].gate_conditions.p1_tc_threshold = true')"
            results+=("${GREEN}✅ P1 TC 通过率: ${p1_rate}% (≥ ${p1_threshold}%)${NC}")
          else
            results+=("${YELLOW}⚠️  P1 TC 通过率: ${p1_rate}% (< ${p1_threshold}%，建议 ITERATE)${NC}")
          fi
        fi

        # === 兼容旧版: 加权总分 ===
        local score
        score="$(sed -n 's/.*加权总分[：: ]*\**\([0-9.]*\)\%.*/\1/p' "$pdir/EVAL_REPORT.md" 2>/dev/null | head -1)"
        if [[ -n "$score" ]]; then
          state="$(echo "$state" | jq --arg s "$score" '.layers["3"].eval_score = ($s | tonumber)')"
          if awk "BEGIN {exit !($score >= 80)}"; then
            state="$(echo "$state" | jq '.layers["3"].gate_conditions.weighted_score_ge_80 = true')"
            results+=("${GREEN}✅ 加权总分: ${score}% (≥ 80%)${NC}")
          else
            all_pass=false
            results+=("${RED}❌ 加权总分: ${score}% (< 80%)${NC}")
          fi
        fi

        # 如果有 TC 通过率但无加权总分，TC 通过率作为主要门控
        if [[ -n "$p0_rate" && -z "$score" ]]; then
          # TC 模式下，P0 100% 且 P1 达标 = 通过
          if [[ "$(echo "$state" | jq -r '.layers["3"].gate_conditions.p0_tc_100 // false')" == "true" ]]; then
            state="$(echo "$state" | jq '.layers["3"].gate_conditions.weighted_score_ge_80 = true')"
          fi
        fi

        # 检查 hard_fail（排除表头、历史记录段、修复确认段）
        local real_fail_count=0
        real_fail_count="$(grep -c '| \*\*❌\*\*\|| ❌ \|' "$pdir/EVAL_REPORT.md" 2>/dev/null || echo 0)"
        real_fail_count="$(echo "$real_fail_count" | tr -d '[:space:]')"
        if [[ "$real_fail_count" -gt 0 ]]; then
          all_pass=false
          results+=("${RED}❌ 检测到 ${real_fail_count} 条 TC FAIL${NC}")
        else
          state="$(echo "$state" | jq '.layers["3"].gate_conditions.no_hard_fail = true')"
          results+=("${GREEN}✅ 无 TC FAIL${NC}")
        fi

        # === Evaluator 独立性验证 ===
        # 1) EVAL_REPORT 必须有独立性声明
        if grep -qi '独立.*[Ee]valuator\|非.*Worker.*自评\|Evaluator.*Agent' "$pdir/EVAL_REPORT.md" 2>/dev/null; then
          results+=("${GREEN}✅ Evaluator 独立性声明已标注${NC}")
        else
          all_pass=false
          results+=("${RED}❌ EVAL_REPORT.md 缺少 Evaluator 独立性声明（必须标注由独立 Evaluator 执行，非 Worker 自评）${NC}")
        fi

        # 2) ISS-060: 验证 Evaluator 确实是独立 session（非自评）
        #    检查 ClawTeam 是否有 evaluator 角色的任务记录
        local eval_spawned=false
        if command -v clawteam &>/dev/null; then
          if clawteam task list "$project" 2>/dev/null | grep -qi 'evaluator\|评估'; then
            eval_spawned=true
            state="$(echo "$state" | jq '.layers["3"].gate_conditions.evaluator_independent = true')"
            results+=("${GREEN}✅ ClawTeam 有 evaluator 任务记录（独立 session 已确认）${NC}")
          else
            all_pass=false
            state="$(echo "$state" | jq '.layers["3"].gate_conditions.evaluator_independent = false')"
            results+=("${RED}❌ ClawTeam 无 evaluator 任务记录 — 必须 clawteam spawn evaluator（ISS-060）${NC}")
          fi
        else
          # clawteam 不可用时仅靠文字声明（降级）
          if grep -qi '独立.*[Ee]valuator\|非.*Worker.*自评\|Evaluator.*Agent' "$pdir/EVAL_REPORT.md" 2>/dev/null; then
            state="$(echo "$state" | jq '.layers["3"].gate_conditions.evaluator_independent = true')"
            results+=("${YELLOW}⚠️  clawteam 不可用，仅凭 EVAL_REPORT 文字声明通过（建议安装 clawteam 做实质验证）${NC}")
          else
            all_pass=false
            results+=("${RED}❌ clawteam 不可用且 EVAL_REPORT 无独立性声明${NC}")
          fi
        fi

        # 3) ISS-060: 禁止"需人工" PASS — TC 标 PASS 但证据含"需人工/待验证"则阻塞
        local fake_pass_count=0
        fake_pass_count="$(grep -iE 'PASS' "$pdir/EVAL_REPORT.md" 2>/dev/null | grep -icE '需人工|待验证|manual|人工抽验|需.*抽.*验' || echo 0)"
        fake_pass_count="$(echo "$fake_pass_count" | tr -d '[:space:]')"
        if [[ "$fake_pass_count" -gt 0 ]]; then
          all_pass=false
          results+=("${RED}❌ ${fake_pass_count} 条 TC 标 PASS 但含「需人工」— 应标 PENDING（ISS-060）${NC}")
        else
          results+=("${GREEN}✅ 无「需人工 PASS」虚假通过${NC}")
        fi

        # === 前端项目截图证据检查 ===
        # 如果 TC 中有截图/交互/chrome 类验证 → eval/screenshots/ 必须有文件
        local has_visual_tc=false
        # 只在 TC 明确要求浏览器截图/交互验证时触发（排除"图表截图"类描述）
        if grep -qi 'claude-in-chrome\|浏览器.*截图\|交互.*测试\|click.*screenshot\|playwright' "$pdir/REQUIREMENTS.md" 2>/dev/null; then
          has_visual_tc=true
        elif grep -qi '前端\|frontend\|React\|Vue\|localhost:[0-9]' "$pdir/REQUIREMENTS.md" 2>/dev/null; then
          # 前端项目默认需要截图
          has_visual_tc=true
        fi
        if $has_visual_tc; then
          local screenshot_count=0
          if [[ -d "$pdir/eval/screenshots" ]]; then
            screenshot_count="$(find "$pdir/eval/screenshots" -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.gif' \) 2>/dev/null | wc -l | tr -d ' ')"
          fi
          if [[ "$screenshot_count" -gt 0 ]]; then
            state="$(echo "$state" | jq --arg n "$screenshot_count" '.layers["3"].gate_conditions.screenshots_exist = true | .layers["3"].screenshot_count = ($n | tonumber)')"
            results+=("${GREEN}✅ 前端截图证据: ${screenshot_count} 张（eval/screenshots/）${NC}")
          else
            all_pass=false
            results+=("${RED}❌ TC 含截图/交互验证但 eval/screenshots/ 为空 — 前端项目必须有浏览器截图证据${NC}")
          fi
        fi

        # 解析决策
        local decision
        decision="$(grep -oP '决策[：:]\s*\K\S+' "$pdir/EVAL_REPORT.md" 2>/dev/null || echo "")"
        if [[ -n "$decision" ]]; then
          state="$(echo "$state" | jq --arg d "$decision" '.layers["3"].eval_decision = $d')"
          results+=("${BLUE}📋 评估决策: $decision${NC}")
        fi
      else
        all_pass=false
        results+=("${RED}⬜ EVAL_REPORT.md 缺失${NC}")
      fi
      ;;

    4)
      # Layer 4: 交付
      local review_confirmed
      review_confirmed="$(echo "$state" | jq -r '.layers["4"].gate_conditions.review_passed')"
      if [[ "$review_confirmed" == "true" ]]; then
        results+=("${GREEN}✅ Review 已通过${NC}")
      else
        all_pass=false
        results+=("${YELLOW}⏳ 等待代码审查通过（/aa-ship Step 1）${NC}")
      fi

      local docs_confirmed
      docs_confirmed="$(echo "$state" | jq -r '.layers["4"].gate_conditions.docs_updated')"
      if [[ "$docs_confirmed" == "true" ]]; then
        results+=("${GREEN}✅ 文档已更新${NC}")
      else
        all_pass=false
        results+=("${YELLOW}⏳ 等待文档更新确认${NC}")
      fi
      ;;

    *)
      die "未知 Layer: $layer（有效值: 0-4）"
      ;;
  esac

  # 输出结果
  echo ""
  for r in "${results[@]}"; do
    echo -e "  $r"
  done
  echo ""

  # 更新 STATE.json
  write_state "$project" "$state"

  # --- 观测记录: 按 Layer 采集不同数据 ---
  local check_result="FAIL"
  $all_pass && check_result="PASS"

  case "$layer" in
    0)
      # 观测: 需求文档存在性 + TC 覆盖矩阵是否有
      local has_tc="false"
      grep -q "覆盖矩阵" "$pdir/REQUIREMENTS.md" 2>/dev/null && has_tc="true"
      log_gate_event "$project" "check" "$layer" "result" "$check_result" "has_tc" "$has_tc"
      ;;
    1)
      # 观测: POC 方案数 + 是否有成本对比
      local poc_count
      poc_count="$(grep -c '方案\|Track\|候选' "$pdir/TECH_SELECTION.md" 2>/dev/null || echo 0)"
      log_gate_event "$project" "check" "$layer" "result" "$check_result" "poc_tracks" "$poc_count"
      ;;
    2)
      # 观测: 任务完成率 + Worker 数 + 编排选型
      local total done
      total="$(grep -c 'cc:' "$pdir/Plans.md" 2>/dev/null || echo 0)"
      done="$(grep -c 'cc:完了' "$pdir/Plans.md" 2>/dev/null || echo 0)"
      local orchestration_type="unknown"
      local orch_file="$pdir/ORCHESTRATION-leader.md"
      [[ ! -f "$orch_file" ]] && orch_file="$pdir/ORCHESTRATION.md"
      grep -q 'Agent Teams' "$orch_file" 2>/dev/null && orchestration_type="hybrid"
      grep -q 'ClawTeam' "$orch_file" 2>/dev/null && [[ "$orchestration_type" == "unknown" ]] && orchestration_type="clawteam"
      log_gate_event "$project" "check" "$layer" "result" "$check_result" "tasks_total" "$total" "tasks_done" "$done" "orchestration" "$orchestration_type"
      ;;
    3)
      # 观测: TC 通过率 + 迭代轮次 + Evaluator 是否独立
      local p0r p1r iter_count
      p0r="$(echo "$state" | jq -r '.layers["3"].tc_pass_rate.P0 // "N/A"')"
      p1r="$(echo "$state" | jq -r '.layers["3"].tc_pass_rate.P1 // "N/A"')"
      iter_count="$(echo "$state" | jq -r '.layers["3"].iterate_count // 0')"
      log_gate_event "$project" "check" "$layer" "result" "$check_result" "p0_rate" "$p0r" "p1_rate" "$p1r" "iterate_round" "$iter_count"
      ;;
    4)
      # 观测: review 是否通过 + 是否有 RETRO.md
      local has_retro="false"
      [[ -f "$pdir/RETRO.md" ]] && has_retro="true"
      log_gate_event "$project" "check" "$layer" "result" "$check_result" "has_retro" "$has_retro"
      ;;
  esac

  if $all_pass; then
    echo -e "${GREEN}🎉 Layer $layer 所有门控条件已满足！${NC}"
    return 0
  else
    echo -e "${YELLOW}⏳ Layer $layer 门控条件未全部满足${NC}"
    return 1
  fi
}

# --- 命令: pass ---
cmd_pass() {
  local project="$1"
  local layer="${2:-$(current_layer "$project")}"
  local pdir="$PROJECT_DIR/$project"
  local state
  state="$(read_state "$project")"

  local ts
  ts="$(now)"

  # 先运行 check 更新产物状态
  cmd_check "$project" "$layer" || true

  state="$(read_state "$project")"

  # 标记所有门控条件为 true
  state="$(echo "$state" | jq --arg l "$layer" '
    .layers[$l].gate_conditions |= with_entries(.value = true)
  ')"

  # 更新层状态
  state="$(echo "$state" | jq --arg l "$layer" --arg t "$ts" '
    .layers[$l].status = "passed" |
    .layers[$l].gate_passed_at = $t |
    .layers[$l].gate_result = "PASS"
  ')"

  # Layer 3 pass: 清除 iterate_count 和 circuit_breaker（为未来重入准备）
  if [[ "$layer" == "3" ]]; then
    state="$(echo "$state" | jq '.layers["3"].iterate_count = 0 | .layers["3"].circuit_breaker = null')"
  fi

  # 推进到下一层（0→0.5→1→2→3→4）
  local next_layer
  case "$layer" in
    0)   next_layer="0.5" ;;
    0.5) next_layer="1" ;;
    *)   next_layer=$((layer + 1)) ;;
  esac

  if [[ "$next_layer" == "0.5" || $next_layer -le 4 ]] 2>/dev/null; then
    state="$(echo "$state" | jq --arg nl "$next_layer" --arg t "$ts" '
      .current_layer = (if $nl == "0.5" then $nl else ($nl | tonumber) end) |
      .layers[$nl].status = "active" |
      .layers[$nl].entered_at = $t
    ')"
    echo -e "${GREEN}✅ Layer $layer 门控通过 → 进入 Layer $next_layer${NC}"
  else
    echo -e "${GREEN}🎉 Layer 4 完成，项目交付！${NC}"
  fi

  # === Layer 2 pass: 汇总 notepads ===
  if [[ "$layer" == "2" ]]; then
    local pdir="$PROJECT_DIR/$project"
    local notepads_dir="$pdir/notepads"
    local summary="$pdir/LAYER2_SUMMARY.md"
    if [[ -d "$notepads_dir" ]]; then
      {
        echo "# Layer 2 实现总结"
        echo ""
        echo "> 自动生成于 $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo ""
        for f in learnings.md decisions.md issues.md problems.md; do
          if [[ -s "$notepads_dir/$f" ]]; then
            echo "## ${f%.md}"
            echo ""
            cat "$notepads_dir/$f"
            echo ""
          fi
        done
      } > "$summary"
      echo -e "${GREEN}已汇总 notepads/ → LAYER2_SUMMARY.md${NC}"
    fi

    # === ISS-032: seal eval/ md5（Layer 2 完成时 eval/ 应已存在）===
    if [[ -d "$pdir/eval" ]]; then
      local eval_md5="{}"
      for ef in "$pdir"/eval/*.py; do
        [[ -f "$ef" ]] || continue
        local fname
        fname="$(basename "$ef")"
        local hash
        hash="$(calc_md5 "$ef")"
        eval_md5="$(echo "$eval_md5" | jq --arg f "$fname" --arg h "$hash" '. + {($f): $h}')"
      done
      state="$(echo "$state" | jq --argjson m "$eval_md5" '.eval_md5_seal = $m')"
      echo -e "${GREEN}已记录 eval/ md5 签名 ($(echo "$eval_md5" | jq 'length') 个文件)${NC}"
    fi
  fi

  # === Layer 4 pass: 写入 OV 经验池 ===
  if [[ "$layer" == "4" ]]; then
    local ov_cmd="$HOME/.openviking/venv/bin/ov"
    local summary="$pdir/LAYER2_SUMMARY.md"
    local experience="$pdir/PROJECT_EXPERIENCE.md"
    {
      echo "# 项目经验: $project"
      echo ""
      echo "> 自动生成于 $(date -u +%Y-%m-%dT%H:%M:%SZ)"
      echo ""
      echo "## 项目概要"
      head -20 "$pdir/REQUIREMENTS.md" 2>/dev/null || echo "(无)"
      echo ""
      echo "## 技术选型摘要"
      head -20 "$pdir/TECH_SELECTION.md" 2>/dev/null || echo "(无)"
      echo ""
      echo "## 实现经验"
      cat "$summary" 2>/dev/null || echo "(无 LAYER2_SUMMARY.md)"
      echo ""
      echo "## 评估结果"
      head -30 "$pdir/EVAL_REPORT.md" 2>/dev/null || echo "(无)"
    } > "$experience"

    if [[ -x "$ov_cmd" ]]; then
      "$ov_cmd" add-resource "$experience" \
        --to "viking://resources/cases/$project/" \
        --reason "项目 $project 交付经验" 2>/dev/null \
        && echo -e "${GREEN}已写入 OV: viking://resources/cases/$project/${NC}" \
        || echo -e "${YELLOW}OV 写入失败，经验已保存到 $experience${NC}"
    else
      echo -e "${YELLOW}ov 不可用，经验已保存到 $experience${NC}"
    fi
  fi

  # === git tag ===
  if [[ -d "$pdir/.git" ]]; then
    local tag="layer${layer}-pass"
    git -C "$pdir" tag -f "$tag" 2>/dev/null \
      && echo -e "${GREEN}已打标签: $tag${NC}"
  fi

  # 记录历史
  state="$(echo "$state" | jq --arg t "$ts" --arg e "Layer $layer gate PASSED" '
    .history += [{"at": $t, "event": $e}]
  ')"

  # --- 观测记录: pass ---
  log_gate_event "$project" "pass" "$layer"

  write_state "$project" "$state"
}

# --- 命令: progress ---
cmd_progress() {
  local project="$1"
  local pdir="$PROJECT_DIR/$project"
  local plans="$pdir/Plans.md"

  if [[ ! -f "$plans" ]]; then
    die "Plans.md 不存在: $plans"
  fi

  local done_count todo_count wip_count blocked_count total
  done_count="$(grep -c 'cc:完了' "$plans" 2>/dev/null || echo 0)" && done_count="${done_count//[^0-9]/}"
  todo_count="$(grep -c 'cc:TODO' "$plans" 2>/dev/null || echo 0)" && todo_count="${todo_count//[^0-9]/}"
  wip_count="$(grep -c 'cc:WIP' "$plans" 2>/dev/null || echo 0)" && wip_count="${wip_count//[^0-9]/}"
  blocked_count="$(grep -c 'cc:blocked' "$plans" 2>/dev/null || echo 0)" && blocked_count="${blocked_count//[^0-9]/}"
  total=$((done_count + todo_count + wip_count + blocked_count))

  echo -e "${BLUE}=== $project 任务进度 ===${NC}"
  echo ""
  [[ $total -gt 0 ]] && echo -e "  进度: $done_count/$total ($(( done_count * 100 / total ))%)"
  echo -e "  ${GREEN}✅ 完成: $done_count${NC}"
  echo -e "  ${YELLOW}🔶 进行中: $wip_count${NC}"
  echo -e "  ⬜ 待做: $todo_count"
  echo -e "  ${RED}🚫 阻塞: $blocked_count${NC}"

  if [[ $wip_count -gt 0 || $blocked_count -gt 0 ]]; then
    echo ""
    echo -e "${BLUE}详情:${NC}"
    grep -E 'cc:WIP|cc:blocked' "$plans" | while IFS='|' read -r _ tid content _ _ _ status _; do
      tid=$(echo "$tid" | xargs)
      status=$(echo "$status" | xargs)
      content=$(echo "$content" | xargs | head -c 50)
      echo "  $tid: $content [$status]"
    done
  fi
}

# --- 命令: fail ---
cmd_fail() {
  local project="$1"
  local layer="${2:-$(current_layer "$project")}"
  local reason="${3:-"门控检查未通过"}"
  local state
  state="$(read_state "$project")"

  local ts
  ts="$(now)"

  # === ISS-053: Circuit Breaker — 检测是否需要触发 Critical Thinker ===
  local iterate_count
  iterate_count="$(echo "$state" | jq -r '.layers["3"].iterate_count // 0')"

  # 检查是否已触发过 CB（防止重复触发后 count 无限累积）
  local cb_triggered
  cb_triggered="$(echo "$state" | jq -r '.layers["3"].circuit_breaker // empty')"

  # 决定回退目标
  local target_layer
  case "$layer" in
    3)
      # Layer 3 失败：看 eval_decision
      local decision
      decision="$(echo "$state" | jq -r '.layers["3"].eval_decision // "ITERATE"')"
      case "$decision" in
        *FAIL*)    target_layer=1; echo -e "${RED}FAIL → 回退到 Layer 1 重新选型${NC}" ;;
        *ITERATE*)
          # 如果已触发 CB 但用户未处理，阻塞而非继续累积
          if [[ -n "$cb_triggered" && "$cb_triggered" != "null" ]]; then
            echo -e "${RED}⛔ Critical Thinker 已触发（${cb_triggered}）但未处理${NC}"
            echo -e "${RED}请先生成 REASSESSMENT.md 并确认路由，再继续迭代${NC}"
            echo -e "${YELLOW}处理完成后运行: gate-check.sh $project reassess-done${NC}"
            target_layer=$layer  # 阻塞在 Layer 3
          else
            # 累计 ITERATE 次数
            iterate_count=$((iterate_count + 1))
            state="$(echo "$state" | jq --arg c "$iterate_count" '.layers["3"].iterate_count = ($c | tonumber)')"

            if [[ "$iterate_count" -ge 3 ]]; then
              # CB-1: Build→QA 循环耗尽 → 触发 Critical Thinker
              echo -e "${RED}⚠️  ITERATE 已达 ${iterate_count} 轮（≥3），触发 Critical Thinker 重评${NC}"
              echo -e "${YELLOW}请执行: 读取 agents/core/critical-thinker.md，按流程生成 REASSESSMENT.md${NC}"
              echo -e "${YELLOW}REASSESSMENT.md 路由建议确认后运行: gate-check.sh $project reassess-done${NC}"
              state="$(echo "$state" | jq '.layers["3"].circuit_breaker = "CB-1: Build-QA循环耗尽"')"
              target_layer=$layer  # 阻塞在 Layer 3
            else
              target_layer=2
              echo -e "${YELLOW}ITERATE (Round ${iterate_count}/3) → 回退到 Layer 2 继续迭代${NC}"
            fi
          fi
          ;;
        *)         target_layer=2; echo -e "${YELLOW}默认 → 回退到 Layer 2${NC}" ;;
      esac
      ;;
    *)
      # 其他层失败：停在当前层
      target_layer=$layer
      echo -e "${RED}Layer $layer 门控失败，需要修复后重试${NC}"
      ;;
  esac

  # 更新状态
  state="$(echo "$state" | jq --arg l "$layer" --arg t "$ts" --arg r "$reason" '
    .layers[$l].status = "failed" |
    .layers[$l].gate_result = "FAIL"
  ')"

  # 如果回退，重置目标层
  if [[ "$target_layer" != "$layer" ]]; then
    state="$(echo "$state" | jq --arg tl "$target_layer" --arg t "$ts" '
      .current_layer = ($tl | tonumber) |
      .layers[$tl].status = "active" |
      .layers[$tl].entered_at = $t |
      .layers[$tl].gate_passed_at = null |
      .layers[$tl].gate_result = null |
      .layers[$tl].gate_conditions |= with_entries(.value = false)
    ')"
  fi

  # 记录历史
  state="$(echo "$state" | jq --arg t "$ts" --arg e "Layer $layer gate FAILED: $reason → target Layer $target_layer" '
    .history += [{"at": $t, "event": $e}]
  ')"

  # --- 观测记录: fail ---
  log_gate_event "$project" "fail" "$layer" "target" "$target_layer" "iterate_count" "$iterate_count" "reason" "$reason"

  write_state "$project" "$state"
}

# --- ISS-053: Critical Thinker 重评完成 → 按路由建议执行 ---
cmd_reassess_done() {
  local project="$1"
  local route="${2:-}"
  local pdir="project/$project"
  local state
  state="$(read_state "$project")"

  # 验证 REASSESSMENT.md 存在
  if [[ ! -s "$pdir/REASSESSMENT.md" ]]; then
    die "REASSESSMENT.md 不存在。请先执行 Critical Thinker 生成重评报告。"
  fi

  # 如果未指定路由，从 REASSESSMENT.md 解析
  if [[ -z "$route" ]]; then
    route="$(grep -oP '^\*\*\K(PERSIST|PIVOT|REGRESS|ABORT)' "$pdir/REASSESSMENT.md" 2>/dev/null | head -1)"
    [[ -z "$route" ]] && route="$(grep -oP '路由建议.*\*\*\K(PERSIST|PIVOT|REGRESS|ABORT)' "$pdir/REASSESSMENT.md" 2>/dev/null | head -1)"
  fi

  if [[ -z "$route" ]]; then
    die "无法解析路由建议。请指定: gate-check.sh $project reassess-done PERSIST|PIVOT|REGRESS|ABORT"
  fi

  local ts
  ts="$(now)"

  echo -e "${BLUE}📋 Critical Thinker 路由: $route${NC}"

  # 清除 CB 标记 + 重置 iterate_count
  state="$(echo "$state" | jq '
    .layers["3"].circuit_breaker = null |
    .layers["3"].iterate_count = 0
  ')"

  case "$route" in
    PERSIST)
      echo -e "${GREEN}PERSIST → 继续 Layer 2 迭代（附 REASSESSMENT.md 中的调整建议）${NC}"
      state="$(echo "$state" | jq --arg t "$ts" '
        .current_layer = 2 |
        .layers["2"].status = "active" |
        .layers["2"].entered_at = $t
      ')"
      ;;
    PIVOT)
      echo -e "${YELLOW}PIVOT → 回到 Layer 2 换方案（iterate_count 已重置）${NC}"
      state="$(echo "$state" | jq --arg t "$ts" '
        .current_layer = 2 |
        .layers["2"].status = "active" |
        .layers["2"].entered_at = $t
      ')"
      ;;
    REGRESS)
      local regress_to
      regress_to="$(grep -oP '回退到.*Layer\s*\K[01]' "$pdir/REASSESSMENT.md" 2>/dev/null | head -1)"
      regress_to="${regress_to:-0}"
      echo -e "${RED}REGRESS → 回退到 Layer $regress_to 重新审视${NC}"
      state="$(echo "$state" | jq --arg tl "$regress_to" --arg t "$ts" '
        .current_layer = ($tl | tonumber) |
        .layers[$tl].status = "active" |
        .layers[$tl].entered_at = $t
      ')"
      ;;
    ABORT)
      echo -e "${RED}ABORT → 项目暂停，目标在当前约束下不可达${NC}"
      state="$(echo "$state" | jq --arg t "$ts" '
        .status = "aborted" |
        .aborted_at = $t
      ')"
      ;;
    *)
      die "无效路由: $route。可选: PERSIST / PIVOT / REGRESS / ABORT"
      ;;
  esac

  # 记录历史
  state="$(echo "$state" | jq --arg t "$ts" --arg e "Critical Thinker reassess-done: $route" '
    .history += [{"at": $t, "event": $e}]
  ')"

  # --- 观测记录: reassess-done ---
  log_gate_event "$project" "reassess-done" "3" "route" "$route"

  write_state "$project" "$state"
}

# --- 子门控: check-research (Layer 1 POC 前置检查) ---
# ISS-055/056: POC spawn 前必须通过此检查
cmd_check_research() {
  local project="$1"
  local pdir="$PROJECT_DIR/$project"
  local all_pass=true
  local results=()

  echo -e "${BLUE}=== Layer 1 调研子门控: $project ===${NC}"
  echo ""

  # 1. RESEARCH_REPORT.md 存在
  if [[ -s "$pdir/RESEARCH_REPORT.md" ]]; then
    results+=("${GREEN}✅ RESEARCH_REPORT.md 存在${NC}")
  else
    all_pass=false
    results+=("${RED}⬜ RESEARCH_REPORT.md 缺失（调研报告必须先于 POC）${NC}")
  fi

  # 2. 中文平台检索结果章节（强制）
  if grep -qi '中文平台检索\|CSDN\|知乎\|阿里云\|微信公众号\|jisu-wechat' "$pdir/RESEARCH_REPORT.md" 2>/dev/null; then
    results+=("${GREEN}✅ 含中文平台检索结果${NC}")
  else
    all_pass=false
    results+=("${RED}⬜ 缺少中文平台检索结果章节（ISS-055 强制项）${NC}")
  fi

  # 3. 方案对比总表
  if grep -qi '方案对比\|对比总表\|候选方案\|推荐.*POC' "$pdir/RESEARCH_REPORT.md" 2>/dev/null; then
    results+=("${GREEN}✅ 含方案对比/推荐${NC}")
  else
    all_pass=false
    results+=("${RED}⬜ 缺少方案对比或 POC 推荐章节${NC}")
  fi

  # 4. 英文生态检索
  if grep -qi 'GitHub\|PyPI\|npm\|英文.*检索\|论文\|arxiv' "$pdir/RESEARCH_REPORT.md" 2>/dev/null; then
    results+=("${GREEN}✅ 含英文生态检索结果${NC}")
  else
    results+=("${YELLOW}⚠️  未检测到英文生态检索结果${NC}")
  fi

  # 输出结果
  for r in "${results[@]}"; do echo -e "  $r"; done
  echo ""

  # 记录事件
  local check_result="PASS"
  if ! $all_pass; then check_result="FAIL"; fi
  log_gate_event "$project" "check-research" "1" "result" "$check_result"

  if $all_pass; then
    echo -e "${GREEN}✅ 调研子门控通过 — 可以开始 POC${NC}"

    # 写入 STATE.json 标记
    local state
    state="$(read_state "$project")"
    local ts; ts="$(now)"
    state="$(echo "$state" | jq --arg t "$ts" '
      .layers["1"].gate_conditions.research_done = true
      | .history += [{"at": $t, "event": "check-research PASS"}]
    ')"
    write_state "$project" "$state"
  else
    echo -e "${RED}❌ 调研子门控未通过 — 请完成调研后再 spawn POC Worker${NC}"
    exit 1
  fi
}

# --- 主入口 ---
main() {
  require_jq

  if [[ $# -lt 2 ]]; then
    echo "用法: gate-check.sh <project-name> <command> [layer]"
    echo ""
    echo "命令:"
    echo "  init       初始化项目状态文件"
    echo "  status     显示项目状态"
    echo "  check [N]  检查 Layer N 门控条件（默认当前层）"
    echo "  pass  [N]  标记 Layer N 门控通过 + 推进"
    echo "  fail  [N]  标记 Layer N 门控失败 + 回退（Layer 3 ≥3次 ITERATE 自动触发 Critical Thinker）"
    echo "  check-research  Layer 1 调研子门控（POC spawn 前必须通过）"
    echo "  reassess-done [PERSIST|PIVOT|REGRESS|ABORT]  Critical Thinker 重评完成后执行路由"
    echo "  progress   显示 Plans.md 任务进度"
    exit 1
  fi

  local project="$1"
  local command="$2"
  shift 2

  case "$command" in
    init)   cmd_init "$project" ;;
    status) cmd_status "$project" ;;
    check)  cmd_check "$project" "${1:-}" ;;
    pass)   cmd_pass "$project" "${1:-}" ;;
    fail)   cmd_fail "$project" "${1:-}" ;;
    progress) cmd_progress "$project" ;;
    check-research) cmd_check_research "$project" ;;
    reassess-done) cmd_reassess_done "$project" "${1:-}" ;;
    *)        die "未知命令: $command" ;;
  esac
}

main "$@"
