#!/bin/bash
# pattern: A
# covers: skill:consultant
# 驗 consultant SKILL.md v2「合約層」關鍵段完整 + 顧問核心 vocab 未漂走。
# v2（Stage 5 鬆綁）：SKILL 只留合約，做法搬去 docs/consultant-flow.md 建議路徑章。
#   → 本 scorer 驗合約層五個關鍵段（模式表 / 每步合約 / 污染警示 / 轉場義務 / 指路行）都在，
#     加上核心 vocab（Step 1 / 設計軸 / prescription / R-10 / R-N / target·builder·human）未漂。
# 這是 Pattern A 結構近似——真實 Pattern C（LLM-judge 輸出品質）待 eval 基建擴充。
set -u
HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$HUB" || exit 1
SKILL=.claude/skills/consultant/SKILL.md

CHECKS=0; FAILS=0
pass(){ CHECKS=$((CHECKS+1)); echo "  ✓ $1"; }
fail(){ CHECKS=$((CHECKS+1)); FAILS=$((FAILS+1)); echo "  ✗ $1"; }

echo "▶ consultant SKILL v2 合約層 + 核心 vocab（Pattern A 近似；Pattern C LLM-judge 待補）"
[ -f "$SKILL" ] || { echo "  ✗ ${SKILL} 不存在"; exit 1; }

declare_concept(){
  local label="$1" pattern="$2"
  if grep -qE "$pattern" "$SKILL"; then
    pass "${label}（pattern: ${pattern}）"
  else
    fail "${label} 缺失（找不到 ${pattern}）"
  fi
}

# ── 合約層五段（v2 鬆綁後 SKILL 本體必留的合約骨架，缺任一 = 掏空徵兆）──
declare_concept "模式表（五模式 command 對應）"       "模式表"
declare_concept "每步合約（產出物/證據/閘門）"        "每步合約"
declare_concept "污染警示（取代禁讀清單）"           "污染警示"
declare_concept "轉場義務（摘要貼對話/中文功能名）"  "轉場義務"
declare_concept "指路行（做法在 consultant-flow）"   "consultant-flow"

# ── 核心 vocab（顧問身分不能漂走）──
declare_concept "Step 1 訪談"              "Phase 0|Step 1"
declare_concept "12/13 設計軸"             "設計軸|design.axis|design-axes"
declare_concept "prescription 產出"        "prescription|設計圖"
declare_concept "R-10 自驗紀律"            "R-10|可機驗"
declare_concept "universal-care-rules"     "universal.care.rules|R-[0-9]+"
declare_concept "target / builder / human" "target|builder|human"

echo
[ "${FAILS}" -eq 0 ] && { echo "✅ consultant SKILL v2 結構 ${CHECKS}/${CHECKS}"; exit 0; } || { echo "❌ ${FAILS}/${CHECKS} 失敗"; exit 1; }
