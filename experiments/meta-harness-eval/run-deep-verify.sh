#!/bin/bash
# run-deep-verify.sh — Pattern C 深驗 runner：LLM-judge 評 prescription 實質性
#
# 用法：
#   bash run-deep-verify.sh                          # 評 prescriptions/ 全部非 superseded 檔
#   bash run-deep-verify.sh --target <path> [...]    # 只評指定檔（可多次；superseded 也可顯式指定）
#   bash run-deep-verify.sh --model sonnet --runs 3  # judge 模型與每檔輪數（預設 sonnet / 3）
#
# 設計（redesign 軸 8 / D.5）：
#   - judge 跑在獨立 `claude -p` 進程——天然滿足「不得同 session 自評」（軸 8 反模式 3）
#   - rubric 即 prompt：judges/prescription-substance.md（版本化，改動獨立 commit）
#   - 每檔跑 N 輪多數決；各輪 verdict 不一致標「漂移」——穩定度本身是訊號（R-10）
#   - JSON 解析失敗計為該輪 fail，不得靜默當過（R-10）
#   - 不進 Stop hook / run-self-verify.sh（貴且需網路）；由 Step 4.5 交付前、/upkeep 可選步驟、或手動觸發
# 退出碼：0=全 substantive；1=有檔判空殼或輪次失敗；2=環境不可用（claude CLI / rubric 缺）——不假裝跑過
set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
HUB="${CLAUDE_PROJECT_DIR:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
cd "$HUB" || exit 2
EVAL_DIR=${SCRIPT_DIR#${HUB}/}
RUBRIC="${EVAL_DIR}/judges/prescription-substance.md"
REPORT="${EVAL_DIR}/deep-verify-report.md"

MODEL="sonnet"; RUNS=3; TARGETS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --target) shift; TARGETS="${TARGETS} ${1:?--target 需要路徑}" ;;
    --model)  shift; MODEL="${1:?--model 需要值}" ;;
    --runs)   shift; RUNS="${1:?--runs 需要數字}" ;;
    *) echo "未知參數：$1（可用 --target/--model/--runs）"; exit 2 ;;
  esac
  shift
done

command -v claude >/dev/null 2>&1 || { echo "⚠️ 深驗未跑：claude CLI 不可用。補跑：環境恢復後重跑本腳本"; exit 2; }
[ -f "$RUBRIC" ] || { echo "⚠️ 深驗未跑：rubric 缺（${RUBRIC}）"; exit 2; }

# timeout 相容（macOS 原生無 GNU timeout；homebrew 裝的叫 timeout 或 gtimeout；都沒有就裸跑）
TIMEOUT_CMD=""
command -v timeout  >/dev/null 2>&1 && TIMEOUT_CMD="timeout 180"
[ -z "$TIMEOUT_CMD" ] && command -v gtimeout >/dev/null 2>&1 && TIMEOUT_CMD="gtimeout 180"

# 無 --target → 取全部非 superseded prescription（frontmatter status）
if [ -z "${TARGETS// /}" ]; then
  for f in prescriptions/*.md; do
    [ -f "$f" ] || continue
    case "$f" in */README.md) continue ;; esac
    awk 'NR==1,/^---$/{if($0 ~ /^status:[[:space:]]*superseded/) exit 1}' "$f" || continue
    TARGETS="${TARGETS} $f"
  done
fi
[ -z "${TARGETS// /}" ] && { echo "（無可評的 prescription，視為通過）"; exit 0; }

TS=$(date '+%Y-%m-%d %H:%M')
SUMMARY=""; ANY_FAIL=0

for f in ${TARGETS}; do
  [ -f "$f" ] || { echo "✗ ${f} 不存在"; ANY_FAIL=1; continue; }
  base=$(basename "$f")
  true_n=0; false_n=0; err_n=0; drift=""
  i=1
  while [ "$i" -le "$RUNS" ]; do
    out=$(${TIMEOUT_CMD} claude -p "$(cat "$RUBRIC"; printf '\n--- 以下為受評 PRESCRIPTION 全文 ---\n'; cat "$f")" \
          --model "$MODEL" --output-format json --permission-mode bypassPermissions 2>/dev/null)
    verdict=$(printf '%s' "$out" | python3 -c '
import sys, json
try:
    env = json.load(sys.stdin)
    txt = env.get("result") or ""
    s, e = txt.find("{"), txt.rfind("}")
    v = json.loads(txt[s:e+1])
    print("true" if v.get("substantive") is True else "false")
except Exception:
    print("error")')
    case "$verdict" in
      true)  true_n=$((true_n+1)) ;;
      false) false_n=$((false_n+1)) ;;
      *)     err_n=$((err_n+1)) ;;
    esac
    i=$((i+1))
  done
  # 多數決；解析失敗輪計 fail 票（R-10：不靜默當過）
  if [ "$err_n" -gt 0 ]; then
    final="error(${err_n}/${RUNS} 輪解析失敗)"; ANY_FAIL=1
  elif [ "$true_n" -gt "$false_n" ]; then
    final="substantive"
  else
    final="hollow"; ANY_FAIL=1
  fi
  [ "$true_n" -ne 0 ] && [ "$false_n" -ne 0 ] && drift="（⚠️ 漂移：票數 ${true_n}真/${false_n}空）"
  line="${base}: ${final} [${true_n}真/${false_n}空/${err_n}誤]${drift}"
  echo "  ${line}"
  SUMMARY="${SUMMARY}- ${line}\n"
done

# 報告滾動保留最近 10 筆（條目以 '## ' 開頭）
{
  printf '## %s · model=%s · runs=%s\n\n' "$TS" "$MODEL" "$RUNS"
  printf '%b\n' "${SUMMARY}"
} >> "$REPORT"
python3 - "$REPORT" <<'PY'
import sys, re
p = sys.argv[1]
txt = open(p, encoding="utf-8").read()
entries = re.split(r'(?m)^(?=## )', txt)
entries = [e for e in entries if e.strip()]
open(p, "w", encoding="utf-8").write("".join(entries[-10:]))
PY

if [ "$ANY_FAIL" -eq 0 ]; then
  echo "✅ 深驗：全部 substantive（報告：${REPORT}）"
  exit 0
else
  echo "❌ 深驗：有檔判空殼或輪次失敗（報告：${REPORT}）"
  exit 1
fi
