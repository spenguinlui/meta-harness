#!/usr/bin/env bash
# 讀 runs/NNN.json，做關鍵字覆蓋率打分，輸出 runs/NNN.eval.json
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 runs/NNN.json" >&2
  exit 1
fi

raw="$1"
[[ -f "$raw" ]] || { echo "not found: $raw" >&2; exit 1; }
eval_out="${raw%.json}.eval.json"

# claude -p --output-format json 的輸出是 JSON，內含 result 欄位是 assistant 文字
text=$(jq -r '.result // .content // .' "$raw" 2>/dev/null || cat "$raw")

# 必要關鍵字（regex；台繁 / 英文都收）
# 第 1 項：共現判定 — 同段落內必須同時出現「合併動詞」與「專案/機器名詞」，避免 "合併節點" false positive
required=(
  '__COOCCUR__:合併|consolidat|merge|bin[- ]?pack::專案|projects?|機器|instances?|hosts?|workloads?'
  'docker|container|容器|ECS|ecs-fargate|kubernetes|k8s'
  '利用率|utilization|CPU ?(avg|max|usage)|cpu_pct|avg_pct|max_pct'
  '省|saving|cost|成本'
  't3\.|t2\.|r7i\.|EC2 ?(實例|instance)'
)
required_labels=( "合併+專案(共現)" "docker/容器化技術" "利用率數據" "省/cost" "實例型號" )

# 加分項
bonus=(
  'api-server|core-web|ai-task|e-trading|roof-crm|jv-project|data-platform'
  '\$[0-9]+|NT\$|[0-9]+\s*台|[0-9]+\.[0-9]+\s*%|[0-9]+%'
  'ECS|docker[- ]?compose|kubernetes|k8s'
  '隔離|故障域|noisy[- ]neighbor|風險'
)
bonus_labels=( "具體專案名" "具體數字" "具體實作" "風險討論" )

# 反例（命中代表結論偏離）
antipatterns=(
  'PG ?1[26]|Extended Support|刪除? ?ALB|delete ALB'
  'Reserved Instance|預留實例|Savings Plan'
)
anti_labels=( "已做過的優化" "純財務優化(非合併)" )

count_hit() {
  local pat="$1"
  if [[ "$pat" == __COOCCUR__:* ]]; then
    # __COOCCUR__:patA::patB → 同段落（空行分隔）內 patA、patB 都出現才算
    local rest="${pat#__COOCCUR__:}"
    local pa="${rest%%::*}"
    local pb="${rest#*::}"
    # awk: 以空行為段落分隔；每段檢查兩個 pattern 是否都命中
    echo "$text" | awk -v pa="$pa" -v pb="$pb" '
      BEGIN { RS=""; count=0 }
      {
        if (tolower($0) ~ tolower(pa) && tolower($0) ~ tolower(pb)) count++
      }
      END { print count }
    '
  else
    echo "$text" | grep -E -i -c "$pat" || true
  fi
}

req_hits=0; req_detail="["
for i in "${!required[@]}"; do
  h=$(count_hit "${required[$i]}")
  [[ $h -gt 0 ]] && req_hits=$((req_hits+1))
  [[ $i -gt 0 ]] && req_detail+=","
  req_detail+=$(printf '{"label":"%s","hit":%s,"count":%s}' "${required_labels[$i]}" "$([[ $h -gt 0 ]] && echo true || echo false)" "$h")
done
req_detail+="]"

bonus_hits=0; bonus_detail="["
for i in "${!bonus[@]}"; do
  h=$(count_hit "${bonus[$i]}")
  [[ $h -gt 0 ]] && bonus_hits=$((bonus_hits+1))
  [[ $i -gt 0 ]] && bonus_detail+=","
  bonus_detail+=$(printf '{"label":"%s","hit":%s,"count":%s}' "${bonus_labels[$i]}" "$([[ $h -gt 0 ]] && echo true || echo false)" "$h")
done
bonus_detail+="]"

anti_hits=0; anti_detail="["
for i in "${!antipatterns[@]}"; do
  h=$(count_hit "${antipatterns[$i]}")
  [[ $h -gt 0 ]] && anti_hits=$((anti_hits+1))
  [[ $i -gt 0 ]] && anti_detail+=","
  anti_detail+=$(printf '{"label":"%s","hit":%s,"count":%s}' "${anti_labels[$i]}" "$([[ $h -gt 0 ]] && echo true || echo false)" "$h")
done
anti_detail+="]"

req_total=${#required[@]}
coverage=$(awk -v a="$req_hits" -v b="$req_total" 'BEGIN{printf "%.3f", a/b}')

# 通過門檻：coverage >= 0.6 且至少 1 個加分
# 反「請業主選視角」短回應：若 token 數 < 600 且含「請業主」「請選」「請補 flag」「業主」其一 → 視為「未提供分析」短路 fail
text_chars=$(echo "$text" | wc -c | tr -d ' ')
intent_prompt=0
if [[ $text_chars -lt 1800 ]]; then  # ~600 token, rough heuristic
  if echo "$text" | grep -E -i -q '請業主|請選定|請選擇|請補.*flag|--intent|出發視角|未指定視角'; then
    intent_prompt=1
  fi
fi

pass="false"
fail_reason=""
if [[ $intent_prompt -eq 1 ]]; then
  pass="false"
  fail_reason="short_intent_prompt_not_analysis"
elif awk -v c="$coverage" 'BEGIN{exit !(c+0 >= 0.6)}' && [[ $bonus_hits -ge 1 ]]; then
  pass="true"
fi

cat > "$eval_out" <<EOF
{
  "run": "$(basename "$raw" .json)",
  "required_hits": $req_hits,
  "required_total": $req_total,
  "coverage": $coverage,
  "bonus_hits": $bonus_hits,
  "anti_hits": $anti_hits,
  "pass": $pass,
  "fail_reason": "$fail_reason",
  "text_chars": $text_chars,
  "intent_prompt": $intent_prompt,
  "required_detail": $req_detail,
  "bonus_detail": $bonus_detail,
  "anti_detail": $anti_detail
}
EOF

echo "→ $eval_out"
jq '{run, coverage, required_hits, required_total, bonus_hits, anti_hits, pass}' "$eval_out"
