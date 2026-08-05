#!/bin/bash
# pattern: B
# covers: hook:self-verify-on-stop.sh
# 驗 self-verify-on-stop.sh hook：無 runner→放行、runner 綠→放行、runner 紅→exit 2 擋下
#   + gate：架構指紋未變→跳過不跑 runner；變了→跑；自驗失敗→不記指紋；always→強制跑
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

# ── gate：只有動過架構才該跑 runner ──────────────────────────
HOOK="$TMP/.claude/hooks/self-verify-on-stop.sh"
RUNNER="$TMP/experiments/meta-harness-eval/run-self-verify.sh"
MARK="$TMP/runner-was-called"
# 留痕 runner：被呼叫就 append 一行，用行數判斷「有沒有真的跑」
green_runner(){ cat > "$RUNNER" <<RUN
#!/bin/bash
echo call >> "$MARK"
exit 0
RUN
}
calls(){ [ -f "$MARK" ] && wc -l < "$MARK" | tr -d ' ' || echo 0; }

mkdir -p "$TMP/docs"; echo "seed" > "$TMP/docs/seed.md"
green_runner; rm -f "$MARK"

# Case 4：首次（無指紋）→ 應跑（安全預設）
CLAUDE_PROJECT_DIR="$TMP" bash "$HOOK" >/dev/null 2>&1
[ "$(calls)" -eq 1 ] && pass "無指紋（首跑）→ 跑 runner" || fail "首跑沒跑 runner（calls=$(calls)）"

# Case 5：架構未變 → 跳過，不跑 runner
CLAUDE_PROJECT_DIR="$TMP" bash "$HOOK" >/dev/null 2>&1; rc=$?
{ [ "$(calls)" -eq 1 ] && [ "$rc" -eq 0 ]; } \
  && pass "架構未變 → 跳過不跑 runner（exit 0）" || fail "未變卻跑了（calls=$(calls) rc=$rc）"

# Case 6：動了架構檔 → 重新跑
echo "changed" >> "$TMP/docs/seed.md"
CLAUDE_PROJECT_DIR="$TMP" bash "$HOOK" >/dev/null 2>&1
[ "$(calls)" -eq 2 ] && pass "架構檔異動 → 重新跑 runner" || fail "改了卻沒跑（calls=$(calls)）"

# Case 7：META_HARNESS_VERIFY=always → 無異動也強制跑
CLAUDE_PROJECT_DIR="$TMP" META_HARNESS_VERIFY=always bash "$HOOK" >/dev/null 2>&1
[ "$(calls)" -eq 3 ] && pass "META_HARNESS_VERIFY=always → 強制跑" || fail "always 沒強制跑（calls=$(calls)）"

# Case 8：自驗失敗 → 不記指紋，下輪同樣改動仍會被抓（失敗不可被指紋吃掉）
cat > "$RUNNER" <<RUN
#!/bin/bash
echo call >> "$MARK"
exit 1
RUN
echo "more" >> "$TMP/docs/seed.md"
CLAUDE_PROJECT_DIR="$TMP" bash "$HOOK" >/dev/null 2>&1; rc=$?
before=$(calls)
CLAUDE_PROJECT_DIR="$TMP" bash "$HOOK" >/dev/null 2>&1
{ [ "$rc" -eq 2 ] && [ "$(calls)" -eq $((before+1)) ]; } \
  && pass "自驗失敗 → 不記指紋，下輪仍重驗" || fail "失敗被指紋吃掉（rc=$rc calls=$before→$(calls)）"

# Case 9：runtime 產出（upkeep-log / runs/）不算架構異動 → 不該觸發
green_runner
CLAUDE_PROJECT_DIR="$TMP" bash "$HOOK" >/dev/null 2>&1   # 先收斂到通過並記指紋
base=$(calls)
mkdir -p "$TMP/experiments/meta-harness-eval"
echo "log" >> "$TMP/experiments/meta-harness-eval/upkeep-log.md"
mkdir -p "$TMP/experiments/x/runs"; echo "raw" > "$TMP/experiments/x/runs/r1.txt"
CLAUDE_PROJECT_DIR="$TMP" bash "$HOOK" >/dev/null 2>&1
[ "$(calls)" -eq "$base" ] && pass "runtime 產出（upkeep-log / runs/）不觸發自驗" \
  || fail "runtime 產出誤觸發（calls=$base→$(calls)）"

echo
[ "${FAILS}" -eq 0 ] && { echo "✅ self-verify-on-stop hook ${CHECKS}/${CHECKS}"; exit 0; } || { echo "❌ ${FAILS}/${CHECKS} 失敗"; exit 1; }
