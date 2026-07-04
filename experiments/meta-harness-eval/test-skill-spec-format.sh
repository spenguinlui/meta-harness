#!/bin/bash
# pattern: A
# covers: skill:consultant, skill:document
# 驗 .claude/skills/*/SKILL.md 都有 YAML frontmatter + name + description
set -u
HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$HUB" || exit 1

CHECKS=0; FAILS=0
pass(){ CHECKS=$((CHECKS+1)); echo "  ✓ $1"; }
fail(){ CHECKS=$((CHECKS+1)); FAILS=$((FAILS+1)); echo "  ✗ $1"; }

echo "▶ .claude/skills/*/SKILL.md frontmatter"
found_any=0
for f in .claude/skills/*/SKILL.md; do
  [ -f "$f" ] || continue
  found_any=1
  name=$(basename "$(dirname "$f")")
  first=$(head -1 "$f")
  if [ "$first" != "---" ]; then
    fail "${name} → 首行非 ---（無 YAML frontmatter）"; continue
  fi
  fm=$(awk '/^---$/{c++; next} c==1 {print} c>=2 {exit}' "$f")
  missing=""
  for key in name description; do
    echo "${fm}" | grep -qE "^${key}:" || missing="${missing} ${key}"
  done
  if [ -z "${missing}" ]; then
    pass "${name} → frontmatter 完整（name + description）"
  else
    fail "${name} → frontmatter 缺：${missing}"
  fi
done

[ "${found_any}" -eq 0 ] && { echo "  ⚠️ 沒找到 SKILL.md（meta-harness 應有 consultant/document 等）"; FAILS=$((FAILS+1)); CHECKS=$((CHECKS+1)); }

echo
[ "${FAILS}" -eq 0 ] && { echo "✅ skill spec format ${CHECKS}/${CHECKS}"; exit 0; } || { echo "❌ ${FAILS}/${CHECKS} 失敗"; exit 1; }
