#!/bin/bash
# 全 repo 自驗 runner — 跑 experiments/meta-harness-eval/test-*.sh 所有支
# 用法：
#   bash experiments/meta-harness-eval/run-self-verify.sh             # 正常自驗（Stop hook / /done / CI 都叫這個）
#   bash experiments/meta-harness-eval/run-self-verify.sh --negative  # 陰性自檢：每支 scorer 對 seeded-bad fixture 必須 fail
# 退出碼 0=全過、1=有 drift（正常模式）／ 有 scorer 抓不到自己的陰性樣本（--negative 模式）。
# 【正常模式行為與 Stop hook 依賴不變】：--negative 是獨立分支、提前返回，無參數路徑完全不受影響。
set -u
HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "${HUB}" || { echo "cd HUB 失敗"; exit 1; }

# 找所有 test-*.sh（先只看 experiments/meta-harness-eval/；未來別處需要可擴）
TESTS=$(ls experiments/meta-harness-eval/test-*.sh 2>/dev/null)
if [ -z "${TESTS}" ]; then
  echo "（無 test-*.sh 自驗腳本，視為通過）"; exit 0
fi

# ─── --negative：陰性自檢（mutation testing 精神，軸 13）────────────────────
if [ "${1:-}" = "--negative" ]; then
  FIX_DIR="experiments/meta-harness-eval/fixtures"
  EXC="${FIX_DIR}/EXCEPTIONS.md"
  echo "▶ Negative self-check（每支 scorer 對自己的 seeded-bad fixture 必須 fail）"
  bad=0; ran=0; skipped=0
  for f in ${TESTS}; do
    name=$(basename "$f" .sh)
    fix="${FIX_DIR}/${name}"
    if [ -d "${fix}" ]; then
      ran=$((ran+1))
      CLAUDE_PROJECT_DIR="${HUB}/${fix}" bash "$f" >/dev/null 2>&1; rc=$?
      if [ "${rc}" -ne 0 ]; then
        echo "  ✓ ${name} → 陰性樣本如預期 fail（rc=${rc}）"
      else
        echo "  ✗ ${name} → 陰性樣本竟 PASS（rc=0）— scorer 抓不到自己的 seeded-bad！"
        bad=$((bad+1))
      fi
    elif [ -f "${EXC}" ] && grep -q "${name}" "${EXC}"; then
      echo "  ↷ ${name} → 無 fixture（EXCEPTIONS.md 具名例外，跳過）"
      skipped=$((skipped+1))
    else
      echo "  ✗ ${name} → 無 fixture 且未列入 EXCEPTIONS.md（不許沉默跳過）"
      bad=$((bad+1))
    fi
  done
  echo
  echo "例外（無 fixture、EXCEPTIONS.md 具名）：${skipped} 支（上限 3）"
  if [ "${skipped}" -gt 3 ]; then
    echo "  ✗ 例外支數 ${skipped} > 3 — 太多 scorer 沒配陰性樣本"; bad=$((bad+1))
  fi
  echo
  if [ "${bad}" -eq 0 ]; then
    echo "✅ Negative self-check：${ran} 支對陰性樣本皆如預期 fail；${skipped} 支具名例外 — 全部通過"
    exit 0
  else
    echo "❌ Negative self-check：${bad} 項不如預期（見上方 ✗）— scorer 品質底線破口"
    exit 1
  fi
fi

echo "▶ Self-verify suite（${HUB}）"
fails=0; ran=0
for f in ${TESTS}; do
  ran=$((ran+1))
  echo
  echo "──── $(basename "$f") ────"
  bash "$f"; rc=$?
  [ "${rc}" -ne 0 ] && fails=$((fails+1))
done
echo
if [ "${fails}" -eq 0 ]; then
  echo "✅ Self-verify: ${ran} 支腳本全過"
  exit 0
else
  echo "❌ Self-verify: ${fails} / ${ran} 支腳本失敗 — drift detected（按 R-10 須修到一致才能交付）"
  exit 1
fi
