#!/bin/bash
# pattern: A
# 驗 .claude/commands/*.md 結構：frontmatter 完整、引用的檔案實存
# 覆蓋 mechanism: slash-command-{design,retro,document,healthcheck}-flow-integrity
set -u
HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$HUB" || exit 1

CHECKS=0; FAILS=0
pass(){ CHECKS=$((CHECKS+1)); echo "  ✓ $1"; }
fail(){ CHECKS=$((CHECKS+1)); FAILS=$((FAILS+1)); echo "  ✗ $1"; }

echo "▶ .claude/commands/*.md 結構與引用完整性"

found=0
for cmd in .claude/commands/*.md; do
  [ -f "$cmd" ] || continue
  found=1
  name=$(basename "$cmd" .md)

  # frontmatter（首行 ---）
  first=$(head -1 "$cmd")
  if [ "$first" != "---" ]; then
    fail "${name} → 首行非 ---（無 frontmatter）"; continue
  fi
  fm=$(awk '/^---$/{c++; next} c==1 {print} c>=2 {exit}' "$cmd")
  if ! echo "${fm}" | grep -qE "^description:"; then
    fail "${name} → frontmatter 缺 description"; continue
  fi
  pass "${name} → frontmatter OK（含 description）"

  # 引用檔案實存性：抓「Read X」「\`X\`」這類引用，挑明確的 docs/ / .claude/ 路徑驗證
  refs=$(grep -oE '(docs/[a-zA-Z0-9_./-]+\.md|\.claude/[a-zA-Z0-9_./-]+\.md)' "$cmd" | sort -u)
  if [ -z "$refs" ]; then
    pass "${name} → 無 docs/ 或 .claude/ 引用（跳過存在性檢查）"
  else
    missing=""
    for r in $refs; do
      [ -f "$r" ] || missing="${missing} ${r}"
    done
    if [ -z "${missing}" ]; then
      pass "${name} → 引用檔案皆實存（$(echo "$refs" | wc -l | tr -d ' ') 個 ref）"
    else
      fail "${name} → 引用了不存在的檔：${missing}"
    fi
  fi
done

[ "${found}" -eq 0 ] && { echo "  ✗ .claude/commands/ 找不到 .md"; FAILS=$((FAILS+1)); CHECKS=$((CHECKS+1)); }

echo
[ "${FAILS}" -eq 0 ] && { echo "✅ slash command flow integrity ${CHECKS}/${CHECKS}"; exit 0; } || { echo "❌ ${FAILS}/${CHECKS} 失敗"; exit 1; }
