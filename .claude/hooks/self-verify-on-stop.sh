#!/bin/bash
# Stop hook：本輪動過「架構」才跑全 repo 自驗；drift → exit 2 擋住結束
# 對應 R-10（可機驗 outcome 必先自驗再交付）的硬規則層。
#
# 觸發條件（gate）：架構檔指紋 != 上次通過自驗時的指紋。
#   · 純諮詢 / 純閱讀 session → 指紋不變 → 靜默放行，不跑套件
#   · 動過 .claude/ bin/ docs/ experiments/ prescriptions/ targets.yml BACKLOG.md → 跑
#   · 指紋只在自驗「通過後」才寫入 → 失敗的改動下輪仍會被抓，不會被漏掉
#   · META_HARNESS_VERIFY=always 可強制跑（CI / 手動全驗）
# runner 不存在或自驗通過 → exit 0 安靜放行。
set -u
HUB_DIR="${CLAUDE_PROJECT_DIR:?CLAUDE_PROJECT_DIR not set}"
RUNNER="${HUB_DIR}/experiments/meta-harness-eval/run-self-verify.sh"
STATE="${HUB_DIR}/.claude/.state/last-verified.sha"

[ -f "${RUNNER}" ] || exit 0   # 還沒佈 runner → 放行

# 架構檔指紋：內容雜湊（非 mtime），排除 runtime 產出（log / 報告 / runs / 本狀態檔）
fingerprint() {
  cd "${HUB_DIR}" 2>/dev/null || return 1
  find .claude bin docs experiments prescriptions targets.yml BACKLOG.md \
       -type f \
       -not -path '*/runs/*' \
       -not -path '.claude/.state/*' \
       -not -name 'scheduled_tasks.lock' \
       -not -name 'upkeep-log.md' \
       -not -name 'deep-verify-report.md' \
       -print0 2>/dev/null \
    | sort -z | xargs -0 shasum 2>/dev/null | shasum | awk '{print $1}'
}

NOW_SHA="$(fingerprint)"
PREV_SHA=""
[ -f "${STATE}" ] && PREV_SHA="$(cat "${STATE}" 2>/dev/null)"

# gate：指紋算得出、與上次一致、且沒強制 → 本輪沒動架構，靜默放行
if [ "${META_HARNESS_VERIFY:-auto}" != "always" ] \
   && [ -n "${NOW_SHA}" ] && [ -n "${PREV_SHA}" ] && [ "${NOW_SHA}" = "${PREV_SHA}" ]; then
  exit 0
fi

OUT=$(bash "${RUNNER}" 2>&1); rc=$?
if [ "${rc}" -ne 0 ]; then
  {
    echo ""
    echo "${OUT}"
    echo ""
    echo "⛔ Stop hook 擋下本輪結束：自驗失敗（drift 與設計圖不一致）。"
    echo "   修到 \`bash experiments/meta-harness-eval/run-self-verify.sh\` 通過再結束。"
    echo "   依據：R-10 可機驗 outcome 必先自驗再交付。"
  } >&2
  exit 2
fi

# 通過才記指紋（含套件自身跑動造成的檔案異動 → 重算一次，避免下輪空跑）
mkdir -p "$(dirname "${STATE}")" 2>/dev/null && fingerprint > "${STATE}" 2>/dev/null
exit 0
