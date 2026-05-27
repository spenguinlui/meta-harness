#!/bin/bash
# pattern: A
# test-cross-references.sh — 一鍵驗 prescriptions 引用的 R-N / 軸 N 真實存在
# Pattern A：單一真實來源 + drift 偵測
#   (A) R-N 真實清單  = docs/universal-care-rules.md 的 `^## R-\d+`
#   (B) 軸 N 真實清單 = docs/design-axes.md 的「軸 N」 ∪ docs/design-axes/NN-*.md 檔名
#   (C) 對每份 prescriptions/*.md：grep R-\d+ 與「軸 \d+」→ 比對 (A)(B)
# 用法：bash experiments/meta-harness-eval/test-cross-references.sh
#       退出碼 0=全過，1=有 drift（哪份引用了哪個失效 ref）
set -u

HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "${HUB}" || { echo "cd HUB 失敗：${HUB}"; exit 1; }

# ─── 用 Python 做解析（避開 grep locale + CJK 議題） ────────────────
result=$(python3 <<'PY'
import os, re, sys, glob

# (A) R-N 真實清單 = universal-care-rules.md `^## R-\d+`
rules_path = "docs/universal-care-rules.md"
try:
    with open(rules_path, encoding="utf-8") as f:
        rules_text = f.read()
except FileNotFoundError:
    print(f"FATAL\tsource_missing\t{rules_path}")
    sys.exit(2)

valid_rules = set()
for m in re.finditer(r"^## R-(\d+)", rules_text, flags=re.MULTILINE):
    valid_rules.add(int(m.group(1)))

# (B) 軸 N 真實清單 = design-axes.md 「軸 N」 ∪ design-axes/NN-*.md 檔名
valid_axes = set()
axes_doc = "docs/design-axes.md"
if os.path.exists(axes_doc):
    with open(axes_doc, encoding="utf-8") as f:
        for m in re.finditer(r"軸\s+(\d+)", f.read()):
            valid_axes.add(int(m.group(1)))

axes_dir = "docs/design-axes"
if os.path.isdir(axes_dir):
    for fn in os.listdir(axes_dir):
        m = re.match(r"^(\d+)-", fn)
        if m:
            valid_axes.add(int(m.group(1)))

# 印 source-of-truth 摘要（給 stdout 報告用）
print("SRC\trules\t" + ",".join(f"R-{n}" for n in sorted(valid_rules)))
print("SRC\taxes\t" + ",".join(f"軸{n}" for n in sorted(valid_axes)))

# (C) 掃 prescriptions/*.md
total_refs = 0
bad = []  # (file, kind, ref)
for path in sorted(glob.glob("prescriptions/*.md")):
    base = os.path.basename(path)
    # README 也掃，反正合法就沒事
    with open(path, encoding="utf-8") as f:
        text = f.read()

    # R-N 引用（任何位置）
    for m in re.finditer(r"R-(\d+)", text):
        total_refs += 1
        n = int(m.group(1))
        if n not in valid_rules:
            bad.append((path, "R", f"R-{n}"))

    # 軸 N 引用（中文「軸」+ 空白 + 數字；允許全形空白 / 多空白）
    for m in re.finditer(r"軸[\s　]+(\d+)", text):
        total_refs += 1
        n = int(m.group(1))
        if n not in valid_axes:
            bad.append((path, "AXIS", f"軸 {n}"))

print(f"TOTAL\t{total_refs}")
for path, kind, ref in bad:
    print(f"BAD\t{path}\t{kind}\t{ref}")
PY
)
rc=$?
if [ "${rc}" -ne 0 ]; then
  echo "${result}"
  echo "✗ python3 解析失敗（rc=${rc}）"
  exit 1
fi

# ─── 輸出 / 判定 ──────────────────────────────────────────────────
echo "▶ test-cross-references — prescriptions 引用是否都對得到 source"
echo
while IFS=$'\t' read -r tag a b c; do
  case "${tag}" in
    SRC)
      echo "  source ${a}: ${b}"
      ;;
  esac
done <<< "${result}"

total=$(echo "${result}" | awk -F'\t' '$1=="TOTAL"{print $2}')
bad_lines=$(echo "${result}" | awk -F'\t' '$1=="BAD"')

echo
if [ -z "${bad_lines}" ]; then
  echo "✅ 全部 ${total} 處引用皆有效"
  exit 0
fi

echo "❌ 偵測到失效引用（drift）:"
while IFS=$'\t' read -r tag path kind ref; do
  [ "${tag}" != "BAD" ] && continue
  echo "  ✗ ${path} 引用了不存在的 ${kind}：${ref}"
done <<< "${bad_lines}"

bad_count=$(echo "${bad_lines}" | grep -c '^BAD' || true)
echo
echo "（共 ${total} 處引用，${bad_count} 處失效）"
exit 1
