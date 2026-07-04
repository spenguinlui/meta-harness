#!/bin/bash
# pattern: A
# test-target-coverage.sh — 驗 targets.yml 列的 target 都有 coverage.json（軸 13 落地進度儀表板）
#
# 背景：coverage.json 是 Phase 3 才會引入的新概念（軸 13 自驗覆蓋率）。
# 目前所有 target 都還沒有這個檔，所以本腳本對缺失採「WARN 不 FAIL」立場，先當進度儀表板用。
#
# 用法：bash experiments/meta-harness-eval/test-target-coverage.sh
# 退出碼：
#   0 — 正常（不論有沒有 coverage.json）
#   1 — targets.yml 不存在 / 無法解析 / schema 完全不對（找不到任何 target）
set -u

HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "${HUB}" || { echo "cd HUB 失敗：${HUB}"; exit 1; }

TARGETS_YML="targets.yml"
if [ ! -f "${TARGETS_YML}" ]; then
  echo "❌ 找不到 ${TARGETS_YML}（HUB=${HUB}）"
  exit 1
fi

# 解析 targets.yml：list of {name, path, status, ...}。
# 只看有 path 的（concept 階段 path=null 跳過，不算 target）。
# 輸出：每行 "name<TAB>path"
PARSED=$(python3 -c "
import sys, yaml
try:
    data = yaml.safe_load(open('${TARGETS_YML}'))
except Exception as e:
    print('PARSE_ERROR:' + str(e), file=sys.stderr)
    sys.exit(2)

if not isinstance(data, list):
    print('SCHEMA_ERROR: 預期 list，實得 ' + type(data).__name__, file=sys.stderr)
    sys.exit(3)

rows = []
for item in data:
    if not isinstance(item, dict):
        continue
    name = item.get('name')
    path = item.get('path')
    if not name:
        continue
    # path=None / null 是 concept 階段，跳過
    if not path:
        continue
    # eval_dir：新 schema 在 machine 欄；舊 schema 在 top-level（相容 fallback）
    machine = item.get('machine') or {}
    eval_dir = machine.get('eval_dir') or item.get('eval_dir') or ''
    rows.append((name, path, eval_dir))

if not rows:
    print('SCHEMA_ERROR: 找不到任何 target 條目（需有 name + path）', file=sys.stderr)
    sys.exit(3)

for n, p, ed in rows:
    print(n + '\t' + p + '\t' + ed)
" 2>&1)
rc=$?

if [ "${rc}" -ne 0 ]; then
  echo "❌ 解析 ${TARGETS_YML} 失敗（rc=${rc}）："
  echo "${PARSED}"
  exit 1
fi

# 走完每個 target，分類已落地 / 未落地
TOTAL=0
LANDED=0
PENDING=0
LANDED_LIST=""
PENDING_LIST=""

while IFS=$'\t' read -r name path eval_dir; do
  [ -z "${name}" ] && continue
  TOTAL=$((TOTAL + 1))
  # eval_dir 可由 targets.yml 個別 override；無設定則用 experiments/<name>-eval
  EVAL_REL="${eval_dir:-experiments/${name}-eval}"
  COV="${path}/${EVAL_REL}/coverage.json"
  if [ -f "${COV}" ]; then
    LANDED=$((LANDED + 1))
    LANDED_LIST="${LANDED_LIST}  ✅ ${name}  →  ${COV}"$'\n'
  else
    PENDING=$((PENDING + 1))
    PENDING_LIST="${PENDING_LIST}  ⏳ ${name}  →  缺 ${COV}"$'\n'
  fi
done <<< "${PARSED}"

echo "▶ targets.yml 軸 13 自驗覆蓋率進度"
echo
echo "targets.yml 列出 ${TOTAL} 個 target："
echo "  ✅ 已落地（有 coverage.json）：${LANDED} 個"
echo "  ⏳ 未落地：${PENDING} 個（軸 13 落地進度待補）"
echo "覆蓋比例：${LANDED}/${TOTAL}"
echo

if [ "${LANDED}" -gt 0 ]; then
  echo "已落地清單："
  printf "%s" "${LANDED_LIST}"
  echo
fi

if [ "${PENDING}" -gt 0 ]; then
  echo "未落地清單："
  printf "%s" "${PENDING_LIST}"
  echo
  echo "（注意：coverage.json 是 Phase 3 才導入的概念，目前未落地屬正常進度，WARN 不 FAIL。）"
fi

exit 0
