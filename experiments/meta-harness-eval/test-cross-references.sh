#!/bin/bash
# pattern: A
# test-cross-references.sh — 驗「活文件」引用的 R-N / 軸 N / 路徑真實存在
# Pattern A：單一真實來源 + drift 偵測
#   (A) R-N 真實清單  = docs/universal-care-rules.md 的 `^## R-\d+`
#   (B) 軸 N 真實清單 = docs/design-axes/NN-*.md 檔名（有檔的編號才算數；N ≤ 13）
#   驗證項：
#     (a) 文中 R-N，N ≤ 12 且該節存在於 universal-care-rules.md，否則 fail
#     (b) 文中「軸 N / 設計軸 N / Design Axis N」，N ≤ 13 且 design-axes/ 有該編號檔，否則 fail
#     (c) 文中引用到 docs/pillars/（已改名為 docs/design-axes/）這類失效路徑 → fail
#
# 掃描範圍：
#   legacy（沿用原涵蓋，只驗 R-N + 中文軸 N）：prescriptions/*.md
#   active（新納入，跑完整誠實化檢查 a/b/c）：.claude/commands/*.md、.claude/skills/*/SKILL.md、
#       README.md、README.en.md、CONTRIBUTING.md、CONTRIBUTING.en.md、BACKLOG.md
# 【明確不掃 sessions/】：那是過去某時間點的歷史快照，當時的軸數 / 規則數本就與現在不同，
#   用現在的清單回溯打臉歷史紀錄沒有意義（歷史快照原則）。prescriptions/ 同屬設計圖歷史 artifact，
#   故只保留原本的 R-N/軸 N 檢查、不對它跑 pillars 失效路徑檢查（當年的舊路徑名不回溯打臉）。
#   docs/ 本身也不掃——universal-care-rules.md 與 design-axes/ 是 source-of-truth，不是被驗對象。
#
# 用法：bash experiments/meta-harness-eval/test-cross-references.sh
#       退出碼 0=全過，1=有 drift（哪份引用了哪個失效 ref）
set -u

HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "${HUB}" || { echo "cd HUB 失敗：${HUB}"; exit 1; }

# ─── 用 Python 做解析（避開 grep locale + CJK 議題） ────────────────
result=$(python3 <<'PY'
import os, re, sys, glob

MAX_AXIS = 13

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

# (B) 軸 N 真實清單 = design-axes/NN-*.md 檔名（有檔案的編號才算數）
valid_axes = set()
axes_dir = "docs/design-axes"
if os.path.isdir(axes_dir):
    for fn in os.listdir(axes_dir):
        mm = re.match(r"^(\d+)-", fn)
        if mm:
            valid_axes.add(int(mm.group(1)))

# 印 source-of-truth 摘要（給 stdout 報告用）
print("SRC\trules\t" + ",".join(f"R-{n}" for n in sorted(valid_rules)))
print("SRC\taxes\t" + ",".join(f"軸{n}" for n in sorted(valid_axes)))

# ── 掃描檔清單 ────────────────────────────────────────────────────
# legacy_scan：prescriptions/*.md —— 沿用原 script 的涵蓋方式（只驗 R-N + 中文軸 N）。
#   prescriptions 是設計圖歷史 artifact；當年寫下時的路徑名（如舊 docs/pillars/）是那個時間點
#   的事實，不該用現在改名後的路徑回溯打臉 → 不對 prescriptions 跑 pillars / 英文 axis 檢查。
legacy_scan = sorted(glob.glob("prescriptions/*.md"))

# active_scan：新納入的活文件 —— 跑完整誠實化檢查（R-N + 軸 N(中/英) + pillars 失效路徑）。
active_scan = []
active_scan += sorted(glob.glob(".claude/commands/*.md"))
active_scan += sorted(glob.glob(".claude/skills/*/SKILL.md"))
active_scan += ["README.md", "README.en.md",
                "CONTRIBUTING.md", "CONTRIBUTING.en.md", "BACKLOG.md"]

rn_re     = re.compile(r"R-(\d+)")
axis_cn   = re.compile(r"軸[\s　]+(\d+)")           # 軸 N / 設計軸 N（中文，含全形空白）
axis_en   = re.compile(r"[Aa]xis\s+(\d+)")          # Design Axis N / axis N（英文）
pillars_re= re.compile(r"[\w./-]*pillars/[\w./-]*") # docs/pillars/ 這類失效路徑

total_refs = 0
bad = []  # (file, kind, ref)

def check_rn(path, text):
    global total_refs
    for m in rn_re.finditer(text):          # (a) R-N：N ≤ 12 且 section 存在
        total_refs += 1
        if int(m.group(1)) not in valid_rules:
            bad.append((path, "R", f"R-{m.group(1)}"))

def check_axis(path, text, regexes):
    global total_refs
    for rx in regexes:                      # (b) 軸/axis N：N ≤ 13 且 design-axes/ 有該編號檔
        for m in rx.finditer(text):
            total_refs += 1
            n = int(m.group(1))
            if n > MAX_AXIS or n not in valid_axes:
                bad.append((path, "AXIS", f"axis {n}"))

def check_pillars(path, text):
    global total_refs
    for m in pillars_re.finditer(text):     # (c) docs/pillars/ 已改名/不存在路徑
        total_refs += 1
        bad.append((path, "PILLARS", m.group(0)))

# prescriptions：維持原涵蓋（R-N + 中文軸 N），不加新檢查
for path in legacy_scan:
    if not os.path.isfile(path):
        continue
    with open(path, encoding="utf-8") as f:
        text = f.read()
    check_rn(path, text)
    check_axis(path, text, [axis_cn])

# 活文件：完整誠實化檢查
for path in active_scan:
    if not os.path.isfile(path):
        continue
    with open(path, encoding="utf-8") as f:
        text = f.read()
    check_rn(path, text)
    check_axis(path, text, [axis_cn, axis_en])
    check_pillars(path, text)

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
echo "▶ test-cross-references — 活文件引用是否都對得到 source（sessions/ 歷史快照不掃）"
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
  case "${kind}" in
    PILLARS) echo "  ✗ ${path} 引用了已改名/不存在的路徑：${ref}（docs/pillars/ 已改名為 docs/design-axes/）" ;;
    *)       echo "  ✗ ${path} 引用了不存在的 ${kind}：${ref}" ;;
  esac
done <<< "${bad_lines}"

bad_count=$(echo "${bad_lines}" | grep -c '^BAD' || true)
echo
echo "（共 ${total} 處引用，${bad_count} 處失效）"
exit 1
