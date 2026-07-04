#!/bin/bash
# pattern: A
# covers: eval:derive-targets.sh
# test-registry-freshness.sh — 薄 scorer：呼叫 derive-targets.sh --check。
#   驗 targets.yml 的 machine 欄（status / dormant / last_evidence / prescriptions）仍等於證據推導值。
#   人手改 machine 欄、或 prescriptions/ 有新 target 沒補登 → --check 非零 → 本 scorer fail（軸 3 V3）。
#   來源缺失（figma2code path 不存在 / 無 prescriptions/）→ derive 判 unknown、不算 drift。
#
# 用法：bash experiments/meta-harness-eval/test-registry-freshness.sh
# 退出碼：0=machine 欄與證據一致，1=drift（人手改 machine / 漏補登 / wiring 增刪未 --apply）
set -u
HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
DERIVE="${SCRIPT_DIR}/derive-targets.sh"

echo "▶ targets.yml 登記簿保鮮（derive-targets.sh --check）"
[ -f "$DERIVE" ] || { echo "  ✗ 找不到 derive-targets.sh：$DERIVE"; echo; echo "❌ 0 / 1 失敗"; exit 1; }

OUT=$(CLAUDE_PROJECT_DIR="$HUB" bash "$DERIVE" --check 2>&1); rc=$?
printf '%s\n' "$OUT" | sed 's/^/  /'
echo
if [ "$rc" -eq 0 ]; then
  echo "✅ targets.yml machine 欄與證據一致（1 / 1 項檢查通過）"
  exit 0
else
  echo "❌ 1 / 1 失敗 — 登記簿失修（machine 欄被手改？漏補登？跑 derive-targets.sh --apply 重建）"
  exit 1
fi
