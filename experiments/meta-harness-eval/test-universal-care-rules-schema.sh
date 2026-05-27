#!/bin/bash
# pattern: A
# 驗 universal-care-rules.md 的 R-N section 編號連續、每條都有內容
set -u
HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$HUB" || exit 1
RULES=docs/universal-care-rules.md

CHECKS=0; FAILS=0
pass(){ CHECKS=$((CHECKS+1)); echo "  ✓ $1"; }
fail(){ CHECKS=$((CHECKS+1)); FAILS=$((FAILS+1)); echo "  ✗ $1"; }

echo "▶ universal-care-rules.md R-N schema"
NUMS=$(grep -oE "^## R-[0-9]+" "${RULES}" 2>/dev/null | grep -oE "[0-9]+" | sort -n)
[ -z "${NUMS}" ] && { echo "  ✗ 找不到任何 R-N section"; exit 1; }

N=$(echo "${NUMS}" | wc -l | tr -d ' ')
EXPECTED=$(seq 1 "${N}")
if diff <(echo "${NUMS}") <(echo "${EXPECTED}") >/dev/null; then
  pass "R-N 編號連續 1..${N}（共 ${N} 條）"
else
  fail "R-N 編號不連續：$(echo "${NUMS}" | tr '\n' ' ')"
fi

# 每個 R-N 後面應有至少一條 bullet 或內文
MISSING=""
for n in ${NUMS}; do
  # 抓 R-N 標題後到下個 ## 之前的內容，看是否 trim 後非空
  BODY=$(awk -v r="^## R-${n}([^0-9]|\$)" '
    $0 ~ r {f=1; next}
    f && /^## / {exit}
    f {print}
  ' "${RULES}" | sed '/^[[:space:]]*$/d')
  [ -z "${BODY}" ] && MISSING="${MISSING} R-${n}"
done

if [ -z "${MISSING}" ]; then
  pass "每個 R-N 都有內容（無空 section）"
else
  fail "以下 R-N 空白：${MISSING}"
fi

echo
[ "${FAILS}" -eq 0 ] && { echo "✅ universal-care-rules schema ${CHECKS}/${CHECKS}"; exit 0; } || { echo "❌ ${FAILS}/${CHECKS} 失敗"; exit 1; }
