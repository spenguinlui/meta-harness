#!/bin/bash
# pattern: A
# covers: eval:generate-coverage.sh
# 驗各 coverage.json 符合軸 13 spec（docs/design-axes/13-self-verify-coverage.md）的 schema
# 來源：meta-harness 自身 + targets.yml 列出且已落地的 target
set -u
HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$HUB" || exit 1

CHECKS=0; FAILS=0
pass(){ CHECKS=$((CHECKS+1)); echo "  ✓ $1"; }
fail(){ CHECKS=$((CHECKS+1)); FAILS=$((FAILS+1)); echo "  ✗ $1"; }

echo "▶ coverage.json schema 一致性（跨 target）"

# 找所有要驗的 coverage.json：meta-harness 自身 + targets.yml 落地者
COV_LIST=$(mktemp); trap "rm -f $COV_LIST" EXIT
# meta-harness 自身
[ -f experiments/meta-harness-eval/coverage.json ] && echo "meta-harness	experiments/meta-harness-eval/coverage.json" >> "$COV_LIST"
# 每個 target（讀 targets.yml + eval_dir 推路徑）
python3 - <<'PY' >> "$COV_LIST"
import os, yaml
try:
    data = yaml.safe_load(open('targets.yml'))
except FileNotFoundError:
    exit(0)
if not isinstance(data, list):
    exit(0)
for item in data:
    if not isinstance(item, dict): continue
    name = item.get('name'); path = item.get('path')
    if not name or not path: continue
    eval_dir = item.get('eval_dir') or f"experiments/{name}-eval"
    cov = f"{path}/{eval_dir}/coverage.json"
    if os.path.isfile(cov):
        print(f"{name}\t{cov}")
PY

[ ! -s "$COV_LIST" ] && { echo "  ⚠️ 找不到任何 coverage.json"; FAILS=$((FAILS+1)); CHECKS=$((CHECKS+1)); echo; echo "❌ ${FAILS}/${CHECKS} 失敗"; exit 1; }

# 對每個 coverage.json 驗 schema
while IFS=$'\t' read -r name cov; do
  [ -z "$name" ] && continue
  result=$(python3 - "$cov" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception as e:
    print(f"FAIL: 無法解析 JSON：{e}"); sys.exit(0)

errs = []
# 必要 top-level 鍵
for k in ['target','generated_at','runner','scorers','totals','mechanisms_inventory','last_run']:
    if k not in d: errs.append(f"缺鍵 {k}")
# 型別
if 'scorers' in d and not isinstance(d['scorers'], list):
    errs.append("scorers 應為 array")
elif 'scorers' in d:
    for i, s in enumerate(d['scorers']):
        if not isinstance(s, dict): errs.append(f"scorers[{i}] 應為 object"); continue
        for k in ['name','pattern','checks','last_pass']:
            if k not in s: errs.append(f"scorers[{i}] 缺 {k}")
if 'totals' in d and isinstance(d['totals'], dict):
    for k in ['scorers','checks_total','checks_passed']:
        if k not in d['totals']: errs.append(f"totals 缺 {k}")
if 'mechanisms_inventory' in d and isinstance(d['mechanisms_inventory'], dict):
    for k in ['total','covered','coverage_pct','uncovered']:
        if k not in d['mechanisms_inventory']: errs.append(f"mechanisms_inventory 缺 {k}")
if 'last_run' in d and isinstance(d['last_run'], dict):
    for k in ['timestamp','rc']:
        if k not in d['last_run']: errs.append(f"last_run 缺 {k}")

if errs:
    print("FAIL: " + "; ".join(errs))
else:
    print("OK")
PY
)
  if [ "$result" = "OK" ]; then
    pass "${name} → schema 完整"
  else
    fail "${name} (${cov}) → ${result}"
  fi
done < "$COV_LIST"

echo
[ "${FAILS}" -eq 0 ] && { echo "✅ coverage.json schema ${CHECKS}/${CHECKS}"; exit 0; } || { echo "❌ ${FAILS}/${CHECKS} 失敗"; exit 1; }
