#!/usr/bin/env bash
# r12-gate.sh — R-12 self-containment gate（單一出處，勿再手抄 grep）
#
# 用法：bin/r12-gate.sh <target-dir>
#   退出碼 0 = 零命中（過關，target self-contained）
#   退出碼 1 = 有命中（把命中行印到 stdout）
#   退出碼 2 = 用法錯誤 / target-dir 不存在
#
# 檢查語意以 docs/universal-care-rules.md R-12「落地自檢」為準：
# 顧問寫進 target 的落地檔不可洩漏 meta-harness 自身的內部 artifact / 行話。
# 關鍵字集合、include 副檔名、node_modules 排除都與該處原文一致——
# 這支 script 是那份 grep 的唯一出處，改檢查語意改這裡。
set -u

target="${1:-}"
if [ -z "${target}" ]; then
  echo "用法：$0 <target-dir>" >&2
  exit 2
fi
if [ ! -d "${target}" ]; then
  echo "錯誤：target-dir 不存在或不是目錄：${target}" >&2
  exit 2
fi

# R-12 洩漏關鍵字（大小寫敏感，同 universal-care-rules.md 原文）：
#   meta-harness / prescription / 設計軸 / 設計面向 / 設計方案 / universal-care / consultant / 顧問
#   / Stage [0-9] / R-[0-9]
# 「設計面向」「設計方案」是 2026-08-05 文件白話化後的新講法，跟舊詞 一併擋——
# 否則新詞散進 target 時這道關卡會失效。命中不等於洩漏，仍需看語境（target 自身文案不算）。
pattern='meta-harness\|prescription\|設計軸\|設計面向\|設計方案\|universal-care\|consultant\|顧問\|Stage [0-9]\|R-[0-9]'

hits=$(grep -rn "${pattern}" "${target}" \
  --include='*.md' --include='*.mjs' --include='*.ts' \
  | grep -v node_modules)

if [ -n "${hits}" ]; then
  echo "❌ R-12 gate FAIL：${target} 命中框架身分 / 行話（非 target 自身文案的才算洩漏，需看語境）："
  echo "${hits}"
  exit 1
fi

echo "✅ R-12 gate PASS：${target} 零命中（self-contained）"
exit 0
