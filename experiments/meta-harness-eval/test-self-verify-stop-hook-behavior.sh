#!/bin/bash
# pattern: B
# covers: hook:self-verify-on-stop.sh
# 驗 self-verify-on-stop.sh hook：無 runner→放行、runner 綠→放行、runner 紅→exit 2 擋下
# 沙箱 HUB：複製 hook 到 tmp，給不同 runner 行為，斷 hook 的 rc 與訊息
set -u
HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
HOOK_SRC="$HUB/.claude/hooks/self-verify-on-stop.sh"
[ -f "$HOOK_SRC" ] || { echo "$HOOK_SRC 不存在"; exit 1; }

CHECKS=0; FAILS=0
pass(){ CHECKS=$((CHECKS+1)); echo "  ✓ $1"; }
fail(){ CHECKS=$((CHECKS+1)); FAILS=$((FAILS+1)); echo "  ✗ $1"; }

echo "▶ self-verify-on-stop hook 行為"

TMP=$(mktemp -d -t svhook-XXXX); trap "rm -rf $TMP" EXIT
mkdir -p "$TMP/.claude/hooks" "$TMP/experiments/meta-harness-eval"
cp "$HOOK_SRC" "$TMP/.claude/hooks/self-verify-on-stop.sh"

# Case 1：無 runner → 安靜放行（hook 對 missing runner 應 graceful exit 0）
out=$(CLAUDE_PROJECT_DIR="$TMP" bash "$TMP/.claude/hooks/self-verify-on-stop.sh" 2>&1); rc=$?
[ "$rc" -eq 0 ] && pass "無 runner → exit 0（graceful）" || fail "rc=$rc 應 0（無 runner 不該 fail）"

# Case 2：runner exit 0 → hook exit 0
cat > "$TMP/experiments/meta-harness-eval/run-self-verify.sh" <<'RUN'
#!/bin/bash
echo "ok"
exit 0
RUN
chmod +x "$TMP/experiments/meta-harness-eval/run-self-verify.sh"
out=$(CLAUDE_PROJECT_DIR="$TMP" bash "$TMP/.claude/hooks/self-verify-on-stop.sh" 2>&1); rc=$?
[ "$rc" -eq 0 ] && pass "runner exit 0 → hook exit 0（安靜放行）" || fail "rc=$rc 應 0"

# Case 3：runner exit 1 → hook exit 2 + 擋下訊息
cat > "$TMP/experiments/meta-harness-eval/run-self-verify.sh" <<'RUN'
#!/bin/bash
echo "test failed" >&2
exit 1
RUN
out=$(CLAUDE_PROJECT_DIR="$TMP" bash "$TMP/.claude/hooks/self-verify-on-stop.sh" 2>&1); rc=$?
{ [ "$rc" -eq 2 ] && echo "$out" | grep -qE "擋下|drift|R-10"; } \
  && pass "runner exit 1 → hook exit 2 + 擋下訊息" \
  || fail "rc=$rc / 訊息：$(echo "$out" | head -3 | tr '\n' '|')"

echo
[ "${FAILS}" -eq 0 ] && { echo "✅ self-verify-on-stop hook ${CHECKS}/${CHECKS}"; exit 0; } || { echo "❌ ${FAILS}/${CHECKS} 失敗"; exit 1; }
