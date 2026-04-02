#!/usr/bin/env bash
# PreToolUse hook (Bash) — 拦截破坏性命令 + 密钥泄露
# 来源: scripts/check-careful.sh (ISS-037)
# Claude Code 通过 stdin 传 JSON: {"tool_name":"Bash","tool_input":{"command":"..."}}
# 输出 JSON {"permissionDecision":"deny","permissionDecisionReason":"..."} 时阻塞

INPUT=$(cat)

# 提取命令
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[[ -z "$CMD" ]] && exit 0

# 安全白名单
SAFE_PATTERNS=(
  'rm -rf node_modules'
  'rm -rf .cache'
  'rm -rf dist'
  'rm -rf __pycache__'
  'rm -rf .pytest_cache'
  'rm -rf build'
  'rm -rf .next'
  'rm -rf .venv'
)

for safe in "${SAFE_PATTERNS[@]}"; do
  if echo "$CMD" | grep -qF "$safe"; then
    exit 0
  fi
done

# 破坏性命令检测
DANGEROUS_PATTERNS=(
  'rm -rf /'
  'rm -rf ~'
  'rm -rf \.'
  'git push --force'
  'git push -f '
  'git reset --hard'
  'git checkout -- \.'
  'git clean -fd'
  'DROP TABLE'
  'DROP DATABASE'
  'TRUNCATE TABLE'
  'kubectl delete'
  'docker system prune -a'
  'chmod -R 777'
  'mkfs\.'
  ':(){:|:&};:'
  'dd if=/dev/'
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$CMD" | grep -qE -- "$pattern"; then
    echo "{\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"破坏性命令被拦截: $pattern\"}"
    exit 0
  fi
done

# 密钥泄露检测
SECRET_PATTERNS=(
  'sk-[a-zA-Z0-9_-]{20,}'
  'AKIA[0-9A-Z]{16}'
  '-----BEGIN.*PRIVATE KEY-----'
  'ghp_[a-zA-Z0-9]{36}'
  'xoxb-[0-9]{10,}'
)

for pattern in "${SECRET_PATTERNS[@]}"; do
  if echo "$CMD" | grep -qE -- "$pattern"; then
    echo "{\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"检测到可能的密钥泄露\"}"
    exit 0
  fi
done

exit 0
