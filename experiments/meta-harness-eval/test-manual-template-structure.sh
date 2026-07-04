#!/bin/bash
# pattern: A
# covers: docs:manual-template.md
# 驗 manual-template.md 自身有三大結構區塊（對照 test-prescription-template-structure.sh 的驗法）：
#   Viewer 說明書段、維護者文件段、雙語慣例段（另檢「兩種讀者=兩份文件」開宗段）。
#   缺任一 → fail（模板失去教「怎麼分讀者、怎麼雙語」的能力）。
set -u
HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$HUB" || exit 1
TPL=docs/manual-template.md

CHECKS=0; FAILS=0
pass(){ CHECKS=$((CHECKS+1)); echo "  ✓ $1"; }
fail(){ CHECKS=$((CHECKS+1)); FAILS=$((FAILS+1)); echo "  ✗ $1"; }

echo "▶ manual-template.md 自身結構"
[ -f "${TPL}" ] || { echo "  ✗ ${TPL} 不存在"; echo "❌ 0 / 1 失敗"; exit 1; }

# 兩種讀者=兩份文件（開宗段，讀者分流）
if grep -qE "^## 兩種讀者" "${TPL}"; then
  pass "「兩種讀者=兩份文件」開宗段存在"
else
  fail "「兩種讀者」開宗段缺失"
fi

# Viewer 說明書段
if grep -qE "^## Viewer 說明書結構" "${TPL}"; then
  pass "Viewer 說明書結構段存在"
else
  fail "Viewer 說明書結構段缺失"
fi

# 維護者文件段
if grep -qE "^## 維護者文件結構" "${TPL}"; then
  pass "維護者文件結構段存在"
else
  fail "維護者文件結構段缺失"
fi

# 雙語慣例段
if grep -qE "^## 雙語慣例" "${TPL}"; then
  pass "雙語慣例段存在"
else
  fail "雙語慣例段缺失"
fi

echo
[ "${FAILS}" -eq 0 ] && { echo "✅ manual-template ${CHECKS}/${CHECKS}"; exit 0; } || { echo "❌ ${FAILS}/${CHECKS} 失敗"; exit 1; }
