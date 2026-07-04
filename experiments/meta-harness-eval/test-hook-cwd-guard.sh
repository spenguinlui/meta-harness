#!/bin/bash
# pattern: B
# covers: hook:cwd-guard.sh
# 驗 cwd-guard.sh：cwd basename=meta-harness 時靜默、非 meta-harness 時出 WARNING、永遠 exit 0。
# 沙箱：建 basename=meta-harness 與 basename=somewhere-else 兩個 dir，各自 cd 進去跑 hook，斷輸出與 rc。
set -u
HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
HOOK_SRC="$HUB/.claude/hooks/cwd-guard.sh"
[ -f "$HOOK_SRC" ] || { echo "  ✗ $HOOK_SRC 不存在"; echo "❌ 0 / 1 失敗"; exit 1; }

CHECKS=0; FAILS=0
pass(){ CHECKS=$((CHECKS+1)); echo "  ✓ $1"; }
fail(){ CHECKS=$((CHECKS+1)); FAILS=$((FAILS+1)); echo "  ✗ $1"; }

echo "▶ cwd-guard hook 行為"

TMP=$(mktemp -d -t cwdguard-XXXX); trap "rm -rf $TMP" EXIT
mkdir -p "$TMP/meta-harness" "$TMP/somewhere-else"

# Case 1：cwd basename = meta-harness → 靜默且 exit 0
out=$( (cd "$TMP/meta-harness" && bash "$HOOK_SRC") 2>&1 ); rc=$?
{ [ -z "$out" ] && [ "$rc" -eq 0 ]; } \
  && pass "meta-harness cwd → 靜默且 exit 0" \
  || fail "meta-harness cwd 應靜默 exit 0（rc=$rc, out=[$out]）"

# Case 2：cwd basename ≠ meta-harness → stderr 出 WARNING 且 exit 0
out=$( (cd "$TMP/somewhere-else" && bash "$HOOK_SRC") 2>&1 ); rc=$?
{ echo "$out" | grep -q "WARNING" && [ "$rc" -eq 0 ]; } \
  && pass "非 meta-harness cwd → WARNING 且 exit 0" \
  || fail "非 meta-harness cwd 應出 WARNING 且 exit 0（rc=$rc, out=[$out]）"

echo
[ "${FAILS}" -eq 0 ] && { echo "✅ cwd-guard hook ${CHECKS}/${CHECKS}"; exit 0; } || { echo "❌ ${FAILS}/${CHECKS} 失敗"; exit 1; }
