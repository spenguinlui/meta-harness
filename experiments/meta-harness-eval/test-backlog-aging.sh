#!/bin/bash
# pattern: A
# test-backlog-aging.sh — BACKLOG.md 每條「### 」待消化條目必含入庫日期（機器可算齡；軸 3 / V5）。
#   缺日期 → FAIL（機器算不了齡，登記簿就不可維生）。
#   帶日期但 > 90 天未消化 → WARN 不 FAIL（消化與否是業主判斷，機器只負責讓它可見）。
#   接受兩種日期寫法：「（YYYY-MM-DD 入庫」或「≤YYYY-MM-DD 入庫」（實日不可考時的上界標註）。
#   今天用 `date +%Y-%m-%d`（不 hardcode）。
#
# 用法：bash experiments/meta-harness-eval/test-backlog-aging.sh
# 退出碼：0=每條待消化條目都帶日期（不論是否超期），1=有條目缺日期 / BACKLOG.md 不存在
set -u
HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "${HUB}" || { echo "cd HUB 失敗：${HUB}"; exit 1; }

BACKLOG="BACKLOG.md"
if [ ! -f "${BACKLOG}" ]; then
  echo "❌ 找不到 ${BACKLOG}（HUB=${HUB}）"
  exit 1
fi

TODAY=$(date +%Y-%m-%d)

python3 - "${BACKLOG}" "${TODAY}" <<'PY'
import sys, re, datetime

path, today_str = sys.argv[1], sys.argv[2]
today = datetime.date.fromisoformat(today_str)
STALE_DAYS = 90

text = open(path, encoding="utf-8").read()
lines = text.split("\n")

# 只掃「待消化」段內的「### 」條目（避開「## 寫入紀律 / 半年回顧」等非待消化 level-2 段）。
in_pending = False
items = []  # (title, has_date, date_or_None, is_upper_bound)
DATE_RE = re.compile(r"[（(]?\s*(≤)?\s*(\d{4}-\d{2}-\d{2})\s*入庫")

for ln in lines:
    if re.match(r"^##\s", ln):
        in_pending = ("待消化" in ln)
        continue
    if in_pending and ln.startswith("### "):
        title = ln[4:].strip()
        m = DATE_RE.search(title)
        if m:
            try:
                d = datetime.date.fromisoformat(m.group(2))
            except ValueError:
                d = None
            items.append((title, d is not None, d, bool(m.group(1))))
        else:
            items.append((title, False, None, False))

print("▶ BACKLOG.md 待消化條目齡檢（今天 = %s）" % today_str)
print()

if not items:
    print("（『待消化』段無 ### 條目 — 視為通過）")
    print()
    print("✅ 0 / 0 條目 — 無待消化項")
    sys.exit(0)

missing = [t for t, has, d, ub in items if not has]
stale = []
for t, has, d, ub in items:
    if has and d is not None:
        age = (today - d).days
        if age > STALE_DAYS:
            stale.append((t, age, ub))

total = len(items)
print("待消化條目：%d 條；帶日期：%d 條；缺日期：%d 條" % (total, total - len(missing), len(missing)))
print()

if stale:
    print("⚠️  超過 %d 天未消化（WARN，不 fail — 消化與否是業主判斷）：" % STALE_DAYS)
    for t, age, ub in sorted(stale, key=lambda x: -x[1]):
        mark = "（≤上界）" if ub else ""
        short = t if len(t) <= 60 else t[:57] + "..."
        print("   · %d 天%s — %s" % (age, mark, short))
    print()

if missing:
    print("❌ 以下條目缺『入庫日期』（機器算不了齡）：")
    for t in missing:
        short = t if len(t) <= 70 else t[:67] + "..."
        print("   · %s" % short)
    print()
    print("❌ %d / %d 條缺日期 — 每條 ### 待消化條目必含「（YYYY-MM-DD 入庫」或「≤YYYY-MM-DD 入庫」"
          % (len(missing), total))
    sys.exit(1)

print("✅ %d / %d 條待消化條目皆帶入庫日期（%d 條超期為 WARN，不 fail）" % (total, total, len(stale)))
sys.exit(0)
PY
rc=$?
exit $rc
