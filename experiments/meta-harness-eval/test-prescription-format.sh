#!/bin/bash
# pattern: A
# test-prescription-format.sh — 驗 prescriptions/*.md 結構齊（單一真實來源 + drift 偵測）
#
# 驗每份 prescription：
#   (a) 含 YAML frontmatter（首兩個 --- 之間），且至少有 target_repo / generated_at / status 三個鍵
#   (b) 含 ## Part A ~ ## Part F 六個段標題（中英文冒號皆可）
#
# 真實來源（single source of truth）：本檔內 EXPECTED_PARTS / REQUIRED_FM_KEYS
# 改 prescription 模板規則時，改這裡一處；script 驗所有現存 prescription 跟得上。
#
# 用法：bash experiments/meta-harness-eval/test-prescription-format.sh
# 退出碼：0=全過，1=有 drift
set -u

HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "${HUB}" || { echo "cd HUB 失敗：${HUB}"; exit 1; }

CHECKS=0; FAILS=0
pass(){ CHECKS=$((CHECKS+1)); echo "  ✓ $1"; }
fail(){ CHECKS=$((CHECKS+1)); FAILS=$((FAILS+1)); echo "  ✗ $1"; }
section(){ echo; echo "▶ $1"; }

# ─── 真實來源 ─────────────────────────────────────────────────────────
EXPECTED_PARTS="A B C D E F"
REQUIRED_FM_KEYS="target_repo generated_at status"

# ─── 收集要驗的檔案 ──────────────────────────────────────────────────
# prescriptions/ 在 .gitignore 但檔案實存；README.md 不是 prescription，跳過
FILES=$(ls prescriptions/*.md 2>/dev/null | grep -v '/README\.md$')
if [ -z "${FILES}" ]; then
  echo "（prescriptions/ 下無 .md 檔，視為通過）"; exit 0
fi

TOTAL=0
for f in ${FILES}; do TOTAL=$((TOTAL+1)); done

section "驗 ${TOTAL} 份 prescription 結構"

# ─── (a) frontmatter 檢查 ────────────────────────────────────────────
# 抓首兩個 --- 之間的內容；若首行不是 --- 視為無 frontmatter
extract_frontmatter(){
  awk 'NR==1 && $0!="---"{exit} /^---$/{c++; if(c==2) exit; next} c==1{print}' "$1"
}

for f in ${FILES}; do
  base=$(basename "$f")
  fm=$(extract_frontmatter "$f")
  if [ -z "${fm}" ]; then
    fail "${base} → 無 YAML frontmatter（首行非 --- 或缺收尾 ---）"
    continue
  fi
  missing=""
  for k in ${REQUIRED_FM_KEYS}; do
    if ! echo "${fm}" | grep -qE "^${k}:"; then
      missing="${missing} ${k}"
    fi
  done
  if [ -n "${missing}" ]; then
    fail "${base} → frontmatter 缺鍵：${missing# }"
  else
    pass "${base} → frontmatter OK（${REQUIRED_FM_KEYS}）"
  fi
done

# ─── (b) Part A ~ Part F 段標題檢查 ──────────────────────────────────
section "驗 Part A~F 段標題（## Part [A-F][:：]）"

for f in ${FILES}; do
  base=$(basename "$f")
  missing=""
  for p in ${EXPECTED_PARTS}; do
    # 中英文冒號都接受
    if ! grep -qE "^## Part ${p}[:：]" "$f"; then
      missing="${missing} ${p}"
    fi
  done
  if [ -n "${missing}" ]; then
    fail "${base} → 缺 Part:${missing}"
  else
    pass "${base} → Part A~F 齊"
  fi
done

echo
if [ "${FAILS}" -eq 0 ]; then
  echo "✅ ${TOTAL} 份 prescriptions 結構齊（${CHECKS} 項檢查全過）"
  exit 0
else
  echo "❌ ${FAILS} / ${CHECKS} 項失敗 — 有 prescription 結構 drift（按 R-10 修到一致才能交付）"
  exit 1
fi
