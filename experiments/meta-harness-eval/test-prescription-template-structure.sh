#!/bin/bash
# pattern: A
# covers: docs:prescription-template.md
# 驗 prescription-template.md 自身有教模板規定的 Header + Part A-F section
# （test-prescription-format 驗的是 prescriptions 用法；本支驗的是 template 自身）
set -u
HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$HUB" || exit 1
TPL=docs/prescription-template.md

CHECKS=0; FAILS=0
pass(){ CHECKS=$((CHECKS+1)); echo "  ✓ $1"; }
fail(){ CHECKS=$((CHECKS+1)); FAILS=$((FAILS+1)); echo "  ✗ $1"; }

echo "▶ prescription-template.md 自身結構"
[ -f "${TPL}" ] || { echo "  ✗ ${TPL} 不存在"; exit 1; }

# Header section
if grep -qE "^## Header" "${TPL}"; then
  pass "Header section 存在"
else
  fail "Header section 缺失"
fi

# Part A-F sections（中英文冒號都吃）
for p in A B C D E F; do
  if grep -qE "^## Part ${p}[:：]" "${TPL}"; then
    pass "Part ${p} section 存在"
  else
    fail "Part ${p} section 缺失"
  fi
done

# 模板使用守則段（出現在 template 末段）
if grep -qE "^## 模板使用守則" "${TPL}"; then
  pass "模板使用守則 section 存在"
else
  fail "模板使用守則 section 缺失"
fi

echo
[ "${FAILS}" -eq 0 ] && { echo "✅ prescription-template ${CHECKS}/${CHECKS}"; exit 0; } || { echo "❌ ${FAILS}/${CHECKS} 失敗"; exit 1; }
