#!/bin/bash
# pattern: B
# 驗 run-self-verify.sh runner：無 test→0、全綠→0、任一紅→1、summary 對
# 沙箱 HUB：複製 runner、放不同 test-*.sh 組合
set -u
HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
RUNNER_SRC="$HUB/experiments/meta-harness-eval/run-self-verify.sh"
[ -f "$RUNNER_SRC" ] || { echo "$RUNNER_SRC 不存在"; exit 1; }

CHECKS=0; FAILS=0
pass(){ CHECKS=$((CHECKS+1)); echo "  ✓ $1"; }
fail(){ CHECKS=$((CHECKS+1)); FAILS=$((FAILS+1)); echo "  ✗ $1"; }

echo "▶ run-self-verify.sh runner 行為"

TMP=$(mktemp -d -t rrtest-XXXX); trap "rm -rf $TMP" EXIT
mkdir -p "$TMP/experiments/meta-harness-eval"
cp "$RUNNER_SRC" "$TMP/experiments/meta-harness-eval/run-self-verify.sh"

run(){ CLAUDE_PROJECT_DIR="$TMP" bash "$TMP/experiments/meta-harness-eval/run-self-verify.sh" 2>&1; }

# Case 1：無 test-*.sh → exit 0 + 「視為通過」訊息
out=$(run); rc=$?
{ [ "$rc" -eq 0 ] && echo "$out" | grep -qE "視為通過|無 test"; } \
  && pass "無 test-*.sh → exit 0 + 「視為通過」訊息" \
  || fail "rc=$rc / 訊息：$(echo "$out" | head -3 | tr '\n' '|')"

# Case 2：一支綠 test → exit 0
cat > "$TMP/experiments/meta-harness-eval/test-green.sh" <<'T'
#!/bin/bash
echo "✅ all green"
exit 0
T
chmod +x "$TMP/experiments/meta-harness-eval/test-green.sh"
out=$(run); rc=$?
[ "$rc" -eq 0 ] && pass "全 test 綠 → exit 0" || fail "rc=$rc 應 0"

# Case 3：加一支紅 test → exit 1
cat > "$TMP/experiments/meta-harness-eval/test-red.sh" <<'T'
#!/bin/bash
echo "❌ broken"
exit 1
T
chmod +x "$TMP/experiments/meta-harness-eval/test-red.sh"
out=$(run); rc=$?
[ "$rc" -eq 1 ] && pass "任一 test 紅 → exit 1" || fail "rc=$rc 應 1"

# Case 4：summary 行對得上實際 1 紅 / 2 共
{ echo "$out" | grep -qE "1 / 2|1/2"; } \
  && pass "summary 1/2 失敗（綠+紅各 1）" \
  || fail "summary 行不對：$(echo "$out" | tail -3 | tr '\n' '|')"

echo
[ "${FAILS}" -eq 0 ] && { echo "✅ runner integrity ${CHECKS}/${CHECKS}"; exit 0; } || { echo "❌ ${FAILS}/${CHECKS} 失敗"; exit 1; }
