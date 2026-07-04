#!/bin/bash
# pattern: B
# covers: hook:pre-askquestion-reminder.sh
# 驗 pre-askquestion-reminder.sh：輸出合法 JSON，hookSpecificOutput.permissionDecision = "allow"（不擋），
#   且 additionalContext 含 R-5（提問必錨具體 artifact）+ R-6（不用未解釋專有名詞/縮寫）提醒文字。
set -u
HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
HOOK_SRC="$HUB/.claude/hooks/pre-askquestion-reminder.sh"
[ -f "$HOOK_SRC" ] || { echo "  ✗ $HOOK_SRC 不存在"; echo "❌ 0 / 1 失敗"; exit 1; }

CHECKS=0; FAILS=0
pass(){ CHECKS=$((CHECKS+1)); echo "  ✓ $1"; }
fail(){ CHECKS=$((CHECKS+1)); FAILS=$((FAILS+1)); echo "  ✗ $1"; }

echo "▶ pre-askquestion-reminder hook 行為"

out=$(printf '%s' '{}' | bash "$HOOK_SRC" 2>&1); rc=$?

# Case 1：exit 0（不擋）
[ "$rc" -eq 0 ] && pass "hook exit 0（不擋）" || fail "rc=$rc 應 0"

# Case 2：permissionDecision = allow
if echo "$out" | jq -e '.hookSpecificOutput.permissionDecision == "allow"' >/dev/null 2>&1; then
  pass "permissionDecision = allow"
else
  fail "permissionDecision 非 allow 或非合法 JSON（out=[$(echo "$out" | head -3 | tr '\n' '|')]）"
fi

# Case 3：additionalContext 含 R-5 + R-6 提醒
ctx=$(echo "$out" | jq -r '.hookSpecificOutput.additionalContext // ""' 2>/dev/null)
{ echo "$ctx" | grep -q "R-5" && echo "$ctx" | grep -q "R-6"; } \
  && pass "additionalContext 含 R-5 + R-6 提醒" \
  || fail "additionalContext 缺 R-5/R-6（ctx=[$(echo "$ctx" | head -1)]）"

echo
[ "${FAILS}" -eq 0 ] && { echo "✅ pre-askquestion-reminder hook ${CHECKS}/${CHECKS}"; exit 0; } || { echo "❌ ${FAILS}/${CHECKS} 失敗"; exit 1; }
