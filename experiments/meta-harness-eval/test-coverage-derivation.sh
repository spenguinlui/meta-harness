#!/bin/bash
# pattern: A
# covers: eval:generate-coverage.sh
# test-coverage-derivation.sh — 薄 scorer：呼叫 generate-coverage.sh --check。
#   驗 coverage.json 的 mechanisms_inventory（分母 total / inventory / covered / uncovered / excluded）
#   仍等於機器重新推導的結果。人手改 total 或 inventory → --check 非零退出 → 本 scorer fail（軸 13 V8）。
#
# 用法：bash experiments/meta-harness-eval/test-coverage-derivation.sh
# 退出碼：0=分母一致，1=drift（人手改了分母 / wiring 增刪未重生 coverage.json）
set -u
HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
GEN="${SCRIPT_DIR}/generate-coverage.sh"

echo "▶ coverage 分母機器推導一致性（generate-coverage.sh --check）"
[ -f "$GEN" ] || { echo "  ✗ 找不到 generate-coverage.sh：$GEN"; echo; echo "❌ 0 / 1 失敗"; exit 1; }

OUT=$(CLAUDE_PROJECT_DIR="$HUB" bash "$GEN" --check 2>&1); rc=$?
printf '%s\n' "$OUT" | sed 's/^/  /'
echo
if [ "$rc" -eq 0 ]; then
  echo "✅ coverage 分母與掃描結果一致（1 / 1 項檢查通過）"
  exit 0
else
  echo "❌ 1 / 1 失敗 — coverage.json 分母 drift（人手改分母？wiring 增刪？跑 generate-coverage.sh 重生）"
  exit 1
fi
