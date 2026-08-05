#!/usr/bin/env bash
# SessionStart — meta-harness staleness nudge（warn-only，永不 block）
# 讀 coverage.json.last_run.timestamp，距今 > 30 天 → stderr 一行警示；否則靜默。
# 對應 D.2 / 設計面向 11：人不在的時候系統自己維護——隔了幾週沒人來，開機時自己提醒清單過期了。
# 契約：任何情況都 exit 0（warn-only，Stop hook 才是唯一 blocking 層）。
# 防呆一律靜默 exit 0：非 meta-harness cwd / coverage.json 不存在 / jq 缺 / JSON 壞 / timestamp 欄缺 / 非法值。
set -u

# (1) 非 meta-harness cwd → 靜默（沿 cwd-guard.sh 的 basename 判法）
[[ "$(basename "$PWD")" != "meta-harness" ]] && exit 0

COV="$PWD/experiments/meta-harness-eval/coverage.json"
# (2) coverage.json 不存在 → 靜默
[[ -f "$COV" ]] || exit 0
# (3) jq 不可用 → 靜默（不硬性要求依賴才不會擋開機）
command -v jq >/dev/null 2>&1 || exit 0

# (4) 解析 last_run.timestamp 並算天數。
#     JSON 壞 / timestamp 欄缺（→ "NA"）/ 非 ISO8601（fromdateiso8601 丟錯 → 空）→ days 非整數 → 靜默。
days=$(jq -r '
  (.last_run.timestamp // "") as $ts
  | if $ts == "" then "NA"
    else (((now - ($ts | fromdateiso8601)) / 86400) | floor)
    end
' "$COV" 2>/dev/null)

[[ "$days" =~ ^-?[0-9]+$ ]] || exit 0

THRESHOLD=30
if (( days > THRESHOLD )); then
  echo "⚠️ meta-harness 自驗登記簿已 ${days} 天沒跑（coverage.json last_run 超過 ${THRESHOLD} 天）。建議跑 /upkeep 或 bash experiments/meta-harness-eval/run-self-verify.sh 重新自驗並更新登記簿。" >&2
fi

exit 0
