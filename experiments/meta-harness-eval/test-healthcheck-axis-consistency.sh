#!/bin/bash
# pattern: A
# 驗 healthcheck command 引用的軸數與實際 design-axes/ 檔案數一致
set -u
HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$HUB" || exit 1

CHECKS=0; FAILS=0
pass(){ CHECKS=$((CHECKS+1)); echo "  ✓ $1"; }
fail(){ CHECKS=$((CHECKS+1)); FAILS=$((FAILS+1)); echo "  ✗ $1"; }

echo "▶ healthcheck command 軸數 vs design-axes/ 實際檔數"

ACTUAL=$(ls docs/design-axes/*.md 2>/dev/null | wc -l | tr -d ' ')
[ "${ACTUAL:-0}" -eq 0 ] && { echo "  ✗ design-axes/ 找不到 .md"; exit 1; }

# 從 healthcheck.md 找形如「13 設計軸」「13 軸」「13 條」這類數字
HC_REFS=$(grep -oE "[0-9]+[[:space:]]*(設計軸|軸|條)" .claude/commands/healthcheck.md 2>/dev/null | grep -oE "^[0-9]+" | sort -u)
if echo "${HC_REFS}" | grep -qx "${ACTUAL}"; then
  pass "healthcheck.md 引用 [${HC_REFS}] 包含實際軸數 ${ACTUAL}"
else
  fail "healthcheck.md 引用 [${HC_REFS}] 不含 ${ACTUAL}（drift：軸數對不上）"
fi

# design-axes.md 索引也驗
IDX_REFS=$(grep -oE "[0-9]+[[:space:]]*大設計軸" docs/design-axes.md 2>/dev/null | grep -oE "^[0-9]+" | sort -u)
if echo "${IDX_REFS}" | grep -qx "${ACTUAL}"; then
  pass "design-axes.md 索引提到 [${IDX_REFS}] 包含 ${ACTUAL}"
else
  fail "design-axes.md 索引提到 [${IDX_REFS}] 不含 ${ACTUAL}"
fi

echo
[ "${FAILS}" -eq 0 ] && { echo "✅ healthcheck axis consistency ${CHECKS}/${CHECKS}"; exit 0; } || { echo "❌ ${FAILS}/${CHECKS} 失敗"; exit 1; }
