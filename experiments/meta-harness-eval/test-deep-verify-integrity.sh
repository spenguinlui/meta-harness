#!/bin/bash
# pattern: B
# covers: eval:run-deep-verify.sh
# test-deep-verify-integrity.sh — 離線驗深驗 runner 的合約（觸發 + 斷言）
#
# 不呼叫真 claude：端到端用 stub claude（沙箱 PATH 前置）驗 verdict 解析、
# 退出碼語意（0=全實質 / 1=有空殼 / 2=環境不可用）與報告滾動 ≤10 筆。
# Stop hook 套件必須保持離線快速——本 scorer 全程無網路。
set -u

HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "${HUB}" || { echo "cd HUB 失敗：${HUB}"; exit 1; }

CHECKS=0; FAILS=0
pass(){ CHECKS=$((CHECKS+1)); echo "  ✓ $1"; }
fail(){ CHECKS=$((CHECKS+1)); FAILS=$((FAILS+1)); echo "  ✗ $1"; }
section(){ echo; echo "▶ $1"; }

RUNNER="experiments/meta-harness-eval/run-deep-verify.sh"
RUBRIC="experiments/meta-harness-eval/judges/prescription-substance.md"

section "檔案與語法"
if [ -f "$RUNNER" ] && bash -n "$RUNNER" 2>/dev/null; then
  pass "runner 存在且 bash -n 過"
else
  fail "runner 缺或語法錯（$RUNNER）"
fi
if [ -f "$RUBRIC" ] && awk '/^```json$/,/^```$/' "$RUBRIC" | grep -v '^```' | python3 -c 'import sys,json; json.load(sys.stdin)' 2>/dev/null; then
  pass "rubric 存在且輸出格式範例是合法 JSON"
else
  fail "rubric 缺、或其 JSON 範例不合法（$RUBRIC）"
fi

section "參數與環境防呆"
bash "$RUNNER" --bogus >/dev/null 2>&1
[ $? -eq 2 ] && pass "未知參數 → exit 2" || fail "未知參數應 exit 2"
# 剝掉 claude 所在 PATH（/usr/bin:/bin 仍有 python3/awk）→ 應走「CLI 不可用」誠實路徑
out=$(PATH="/usr/bin:/bin" bash "$RUNNER" 2>&1); rc=$?
if [ "${rc}" -eq 2 ] && printf '%s' "$out" | grep -q "深驗未跑"; then
  pass "claude CLI 缺席 → exit 2 + ⚠️ 訊息（不假裝跑過）"
else
  fail "CLI 缺席應 exit 2 並明說未跑（rc=${rc}）"
fi

section "端到端（stub claude，無網路）"
TMP=$(mktemp -d)
mkdir -p "$TMP/experiments/meta-harness-eval/judges" "$TMP/prescriptions" "$TMP/stubbin"
cp "$RUNNER" "$TMP/experiments/meta-harness-eval/"
cp "$RUBRIC" "$TMP/experiments/meta-harness-eval/judges/" 2>/dev/null
cat > "$TMP/prescriptions/sample.md" <<'EOF'
---
target_repo: sample
generated_at: 2026-07-05
status: draft
---
## Part A：測試用樣本
EOF
cat > "$TMP/stubbin/claude" <<'EOF'
#!/bin/bash
V="${STUB_VERDICT:-true}"
printf '{"result": "{\\"substantive\\": %s, \\"score\\": 5, \\"reasons\\": [\\"stub\\"]}", "is_error": false}\n' "$V"
EOF
chmod +x "$TMP/stubbin/claude" "$TMP/experiments/meta-harness-eval/run-deep-verify.sh"
SANDBOX_RUNNER="$TMP/experiments/meta-harness-eval/run-deep-verify.sh"
SB_PATH="$TMP/stubbin:/usr/bin:/bin"

STUB_VERDICT=true  PATH="$SB_PATH" CLAUDE_PROJECT_DIR="$TMP" bash "$SANDBOX_RUNNER" --runs 1 >/dev/null 2>&1
[ $? -eq 0 ] && pass "stub 判實質 → exit 0" || fail "stub 判實質應 exit 0"
STUB_VERDICT=false PATH="$SB_PATH" CLAUDE_PROJECT_DIR="$TMP" bash "$SANDBOX_RUNNER" --runs 1 >/dev/null 2>&1
[ $? -eq 1 ] && pass "stub 判空殼 → exit 1" || fail "stub 判空殼應 exit 1"
[ -f "$TMP/experiments/meta-harness-eval/deep-verify-report.md" ] \
  && pass "報告檔已產生" || fail "報告檔未產生"
i=0
while [ "$i" -lt 12 ]; do
  STUB_VERDICT=true PATH="$SB_PATH" CLAUDE_PROJECT_DIR="$TMP" bash "$SANDBOX_RUNNER" --runs 1 >/dev/null 2>&1
  i=$((i+1))
done
n=$(grep -c '^## ' "$TMP/experiments/meta-harness-eval/deep-verify-report.md" 2>/dev/null || echo 0)
[ "$n" -le 10 ] && [ "$n" -ge 1 ] && pass "報告滾動保留 ≤10 筆（現 ${n} 筆）" || fail "報告滾動失效（${n} 筆）"
rm -rf "$TMP"

echo
if [ "${FAILS}" -eq 0 ]; then
  echo "✅ deep-verify runner 合約 ${CHECKS} 項全過"
  exit 0
else
  echo "❌ ${FAILS} / ${CHECKS} 項失敗"
  exit 1
fi
