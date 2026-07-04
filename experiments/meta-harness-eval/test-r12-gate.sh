#!/bin/bash
# pattern: B
# covers: bin:r12-gate.sh
# 驗 bin/r12-gate.sh 三種退出碼語意：
#   乾淨 target-dir（零命中框架行話）→ exit 0；含「prescription」字樣的 .md → exit 1；無參數 → exit 2。
# 沙箱：mktemp -d 造 target，用真 gate 跑，斷 rc。
set -u
HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
GATE="$HUB/bin/r12-gate.sh"
[ -f "$GATE" ] || { echo "  ✗ $GATE 不存在"; echo "❌ 0 / 1 失敗"; exit 1; }

CHECKS=0; FAILS=0
pass(){ CHECKS=$((CHECKS+1)); echo "  ✓ $1"; }
fail(){ CHECKS=$((CHECKS+1)); FAILS=$((FAILS+1)); echo "  ✗ $1"; }

echo "▶ r12-gate.sh 退出碼語意"

TMP=$(mktemp -d -t r12gate-XXXX); trap "rm -rf $TMP" EXIT
CLEAN="$TMP/clean"; DIRTY="$TMP/dirty"
mkdir -p "$CLEAN" "$DIRTY"
printf '# Widget 使用說明\n每天用這個做事。\n' > "$CLEAN/README.md"          # 零框架行話
printf '# Notes\n這裡誤抄了 prescription 字樣，會被 gate 抓。\n' > "$DIRTY/leak.md"  # 命中洩漏關鍵字

# Case 1：乾淨 target-dir → exit 0
bash "$GATE" "$CLEAN" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "乾淨 target-dir → exit 0" || fail "乾淨 dir 應 exit 0（rc=${rc}）"

# Case 2：含「prescription」字樣 → exit 1
bash "$GATE" "$DIRTY" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 1 ] && pass "含框架行話 → exit 1" || fail "含 prescription 字樣應 exit 1（rc=${rc}）"

# Case 3：無參數 → exit 2
bash "$GATE" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && pass "無參數 → exit 2（用法錯誤）" || fail "無參數應 exit 2（rc=${rc}）"

echo
[ "${FAILS}" -eq 0 ] && { echo "✅ r12-gate ${CHECKS}/${CHECKS}"; exit 0; } || { echo "❌ ${FAILS}/${CHECKS} 失敗"; exit 1; }
