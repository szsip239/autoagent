#!/usr/bin/env bash
# PostToolUse hook (Skill) — 记录 Skill 调用
# 来源: scripts/track-skill.sh (ISS-041)
# Claude Code 通过 stdin 传 JSON

INPUT=$(cat)

SKILL_NAME=$(echo "$INPUT" | jq -r '.tool_input.skill // empty' 2>/dev/null)
[[ -z "$SKILL_NAME" ]] && exit 0

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $SKILL_NAME" >> "$(pwd)/.skill-invocations.log" 2>/dev/null || true
