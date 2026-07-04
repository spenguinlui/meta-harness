#!/bin/bash
# pattern: B
# covers: hook:post-write-line-check.sh
# 驗 post-write-line-check.sh：PostToolUse stdin 指到 .claude/hooks/*.sh 超過 100 行 → 出 R-3 違規提示；
#   正常（≤100 行）檔 → 靜默。兩條路徑都必須 exit 0（不擋、只給 feedback）。
# 沙箱：造一個 121 行假 hook 與一個 2 行假 hook，餵各自 PostToolUse stdin，斷輸出與 rc。
set -u
HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
HOOK_SRC="$HUB/.claude/hooks/post-write-line-check.sh"
[ -f "$HOOK_SRC" ] || { echo "  ✗ $HOOK_SRC 不存在"; echo "❌ 0 / 1 失敗"; exit 1; }

CHECKS=0; FAILS=0
pass(){ CHECKS=$((CHECKS+1)); echo "  ✓ $1"; }
fail(){ CHECKS=$((CHECKS+1)); FAILS=$((FAILS+1)); echo "  ✗ $1"; }

echo "▶ post-write-line-check hook 行為"

TMP=$(mktemp -d -t pwlc-XXXX); trap "rm -rf $TMP" EXIT
mkdir -p "$TMP/.claude/hooks"
BIG="$TMP/.claude/hooks/bigfake.sh"
SMALL="$TMP/.claude/hooks/smallfake.sh"
{ echo '#!/bin/bash'; for i in $(seq 1 121); do echo "# pad line $i"; done; } > "$BIG"   # 122 行 > 100
printf '#!/bin/bash\necho hi\n' > "$SMALL"                                                # 2 行 ≤ 100

# Case 1：超過 100 行的 hook 檔 → 出 R-3 違規提示 + exit 0
stdin=$(jq -n --arg p "$BIG" '{tool_input:{file_path:$p}}')
out=$(printf '%s' "$stdin" | bash "$HOOK_SRC" 2>&1); rc=$?
{ echo "$out" | grep -qE "R-3|違規" && [ "$rc" -eq 0 ]; } \
  && pass "超過 100 行 hook → R-3 違規提示且 exit 0" \
  || fail "超長 hook 應出 R-3 提示且 exit 0（rc=$rc, out=[$out]）"

# Case 2：正常 hook（≤100 行）→ 靜默 + exit 0
stdin=$(jq -n --arg p "$SMALL" '{tool_input:{file_path:$p}}')
out=$(printf '%s' "$stdin" | bash "$HOOK_SRC" 2>&1); rc=$?
{ [ -z "$out" ] && [ "$rc" -eq 0 ]; } \
  && pass "正常 hook（≤100 行）→ 靜默且 exit 0" \
  || fail "正常 hook 應靜默 exit 0（rc=$rc, out=[$out]）"

echo
[ "${FAILS}" -eq 0 ] && { echo "✅ post-write-line-check hook ${CHECKS}/${CHECKS}"; exit 0; } || { echo "❌ ${FAILS}/${CHECKS} 失敗"; exit 1; }
