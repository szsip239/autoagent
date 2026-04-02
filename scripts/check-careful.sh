#!/usr/bin/env bash
# check-careful.sh — PreToolUse hook (matcher: Bash)
# 拦截破坏性命令和密钥泄露，四级决策: block / allow
# 依赖: jq (必须), bash
set -euo pipefail

INPUT=$(cat)

# 只处理 Bash 工具
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
if [[ "$TOOL_NAME" != "Bash" ]]; then
  echo '{}'
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
if [[ -z "$COMMAND" ]]; then
  echo '{}'
  exit 0
fi

# === 安全白名单（不拦截） ===
SAFE_PATTERNS=(
  'rm -rf node_modules'
  'rm -rf __pycache__'
  'rm -rf \.cache'
  'rm -rf dist/'
  'rm -rf build/'
  'rm -rf \.pytest_cache'
  'rm -rf \.mypy_cache'
  'rm -rf \.venv'
  'git tag -f'
)

for safe in "${SAFE_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE -e "$safe"; then
    echo '{}'
    exit 0
  fi
done

# === 破坏性命令正则 ===
DESTRUCTIVE_PATTERNS=(
  'rm -rf /'
  'rm -rf ~'
  'rm -rf \.\.'
  'rm -rf \*'
  'git push --force'
  'git push -f '
  'git reset --hard'
  'git clean -fd'
  'DROP TABLE'
  'DROP DATABASE'
  'TRUNCATE TABLE'
  'kubectl delete'
  'docker rm -f'
  'docker system prune -a'
  'chmod -R 777'
  'mkfs\.'
  '> /dev/sd'
)

for pattern in "${DESTRUCTIVE_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE -e "$pattern"; then
    printf '{"decision":"block","reason":"[check-careful] 检测到破坏性命令: %s。如确需执行，请向 Leader 确认。"}\n' "$pattern"
    exit 0
  fi
done

# === 密钥泄露检测（硬编码在命令中的密钥） ===
SECRET_PATTERNS=(
  'sk-[a-zA-Z0-9]{20,}'
  'AKIA[0-9A-Z]{16}'
  '-----BEGIN.*PRIVATE KEY-----'
  'ghp_[a-zA-Z0-9]{36}'
  'xoxb-[0-9]+-[a-zA-Z0-9]+'
)

for pattern in "${SECRET_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE -e "$pattern"; then
    printf '{"decision":"block","reason":"[check-careful] 命令中检测到疑似密钥/token。请勿在命令行中硬编码敏感信息。"}\n'
    exit 0
  fi
done

# 默认放行
echo '{}'
