#!/bin/bash
# pattern: A
# 驗 consultant skill 內含關鍵概念（Phase 0 / 設計軸 / prescription / R-10）
# 這是 Pattern A 結構近似——真實 Pattern C（LLM-judge 輸出品質）待 eval 基建擴充
set -u
HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$HUB" || exit 1
SKILL=.claude/skills/consultant/SKILL.md

CHECKS=0; FAILS=0
pass(){ CHECKS=$((CHECKS+1)); echo "  ✓ $1"; }
fail(){ CHECKS=$((CHECKS+1)); FAILS=$((FAILS+1)); echo "  ✗ $1"; }

echo "▶ consultant skill 結構（Pattern A 近似；Pattern C LLM-judge 待補）"
[ -f "$SKILL" ] || { echo "  ✗ ${SKILL} 不存在"; exit 1; }

# 必含關鍵概念字串（顧問核心 vocab 不能漂走）
declare_concept(){
  local label="$1" pattern="$2"
  if grep -qE "$pattern" "$SKILL"; then
    pass "${label} 提到（pattern: ${pattern}）"
  else
    fail "${label} 缺失（找不到 ${pattern}）"
  fi
}
declare_concept "Phase 0 訪談"           "Phase 0|Step 1"
declare_concept "12/13 設計軸"           "設計軸|design.axis|design-axes"
declare_concept "prescription 產出"      "prescription|設計圖"
declare_concept "R-10 自驗紀律"          "R-10|可機驗"
declare_concept "universal-care-rules"   "universal.care.rules|R-[0-9]+"
declare_concept "target / builder / human" "target|builder|human"

echo
[ "${FAILS}" -eq 0 ] && { echo "✅ consultant skill 結構 ${CHECKS}/${CHECKS}"; exit 0; } || { echo "❌ ${FAILS}/${CHECKS} 失敗"; exit 1; }
