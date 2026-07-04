#!/bin/bash
# pattern: B
# covers: hook:staleness-nudge.sh
# 驗 staleness-nudge.sh（SessionStart, warn-only）：
#   coverage.json.last_run.timestamp 超過 30 天 → stderr 一行警示；新鮮 → 靜默；coverage.json 缺 → 靜默。
#   三種情境都必須 exit 0（warn-only，永不 block）。
# 沙箱：建 basename=meta-harness 的假 repo，塞不同時間戳的 coverage.json，cd 進去跑真 hook。
set -u
HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
HOOK_SRC="$HUB/.claude/hooks/staleness-nudge.sh"
[ -f "$HOOK_SRC" ] || { echo "  ✗ $HOOK_SRC 不存在"; echo "❌ 0 / 1 失敗"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "  ✗ 需要 jq 造時間戳 fixture"; echo "❌ 0 / 1 失敗"; exit 1; }

CHECKS=0; FAILS=0
pass(){ CHECKS=$((CHECKS+1)); echo "  ✓ $1"; }
fail(){ CHECKS=$((CHECKS+1)); FAILS=$((FAILS+1)); echo "  ✗ $1"; }

echo "▶ staleness-nudge hook 行為"

TMP=$(mktemp -d -t stale-XXXX); trap "rm -rf $TMP" EXIT
REPO="$TMP/meta-harness"; COV="$REPO/experiments/meta-harness-eval/coverage.json"
mkdir -p "$(dirname "$COV")"

write_cov(){ # $1 = 幾天前
  local ts; ts=$(jq -nr --argjson d "$1" '(now - ($d*86400)) | todateiso8601')
  jq -n --arg t "$ts" '{last_run:{timestamp:$t}}' > "$COV"
}

# Case 1：45 天前 → stderr 警示 + exit 0
write_cov 45
out=$( (cd "$REPO" && bash "$HOOK_SRC") 2>&1 ); rc=$?
{ echo "$out" | grep -q "天" && echo "$out" | grep -q "run-self-verify" && [ "$rc" -eq 0 ]; } \
  && pass "45 天前 timestamp → stderr 警示且 exit 0" \
  || fail "45 天前應出警示且 exit 0（rc=$rc, out=[$out]）"

# Case 2：當前 timestamp → 靜默 + exit 0
write_cov 0
out=$( (cd "$REPO" && bash "$HOOK_SRC") 2>&1 ); rc=$?
{ [ -z "$out" ] && [ "$rc" -eq 0 ]; } \
  && pass "當前 timestamp → 靜默且 exit 0" \
  || fail "當前 timestamp 應靜默 exit 0（rc=$rc, out=[$out]）"

# Case 3：coverage.json 缺失 → 靜默 + exit 0
rm -f "$COV"
out=$( (cd "$REPO" && bash "$HOOK_SRC") 2>&1 ); rc=$?
{ [ -z "$out" ] && [ "$rc" -eq 0 ]; } \
  && pass "coverage.json 缺失 → 靜默且 exit 0" \
  || fail "coverage.json 缺失應靜默 exit 0（rc=$rc, out=[$out]）"

echo
[ "${FAILS}" -eq 0 ] && { echo "✅ staleness-nudge hook ${CHECKS}/${CHECKS}"; exit 0; } || { echo "❌ ${FAILS}/${CHECKS} 失敗"; exit 1; }
