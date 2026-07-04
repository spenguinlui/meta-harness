#!/bin/bash
# pattern: A
# test-prescription-contract.sh — 驗 prescriptions/*.md 的「語義合約」（不只格式標題齊）
#
# 動機：2026-06 掏空事故——一份 prescription 把 Part A–F 標題留著、語義全部掏空，
#       只 grep 標題的 test-prescription-format.sh 照樣全綠。本 scorer 驗「內容合約」，
#       讓掏空被機器抓到（軸 8 Evaluation loop / 軸 4 lite 分級 / redesign D.5）。
#
# 分級規則（source of truth = 各 prescription frontmatter）：
#   - template: 鍵；缺省視為 full。
#   - status: superseded → 整份跳過（被取代的設計圖不再受合約約束）。
#   - generated_at < HARD_GATE_DATE（2026-07-01）→ 歷史檔寬限：檢查照跑但失敗只列 WARN 不計 fail。
#       理由：合約格式（### Design Axis 五欄位、V 條目證據欄）是 2026-07 起的新規約，
#       回溯打臉 2026-05/06 的舊設計圖沒有意義（同 cross-references 的歷史快照原則）。
#   - generated_at >= 2026-07-01 → 硬 gate：失敗即 fail（exit 1）。
#
# full 版檢查：
#   (a) 存在 ≥1 個 `### Design Axis` 區塊，且每區塊內含
#       **Required** / **Status** / **Trace** / **Static config** / **Mechanism** 五欄位字樣。
#   (b) 任何 `Status: ✅ passing` 的 V 條目，同區塊內須有非空 `Live-fired at:`（真時間戳，非 🚧/空白）。
#   (c) `Verify level: script` 且 ✅ 的 V 條目，須有非空 `Self-verify runs:`（非 N/A/🚧/空白）。
#   (d) 生命週期：status: draft 且 generated_at 距今 >30 天 → WARN 提示該轉 active/superseded（永遠只 WARN）。
# lite 版檢查（軸 4：證據紀律不變，表格重量縮放）：
#   - 存在 V 條目表（`### V` 區塊 ≥1）＋ 含「不動」字樣的清單段；五欄位塊不要求。
#   - 證據紀律 (b)(c) 對 lite 同樣適用（redesign 軸 4「V 表與證據欄不可省」）。
#
# 用法：bash experiments/meta-harness-eval/test-prescription-contract.sh
# 退出碼：0=全過（含只有 WARN 的情況），1=有硬 gate 失敗
set -u

HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "${HUB}" || { echo "cd HUB 失敗：${HUB}"; exit 1; }

CHECKS=0; FAILS=0
pass(){ CHECKS=$((CHECKS+1)); echo "  ✓ $1"; }
fail(){ CHECKS=$((CHECKS+1)); FAILS=$((FAILS+1)); echo "  ✗ $1"; }
warn(){ echo "  ⚠️ $1"; }
section(){ echo; echo "▶ $1"; }

FILES=$(ls prescriptions/*.md 2>/dev/null | grep -v '/README\.md$')
if [ -z "${FILES}" ]; then
  echo "（prescriptions/ 下無 .md 檔，視為通過）"; exit 0
fi

TODAY=$(date +%Y-%m-%d)

# ─── Python 做內容解析（避開 grep locale + CJK 議題），逐檔逐檢查吐機器行 ───
RESULT=$(python3 - "$TODAY" ${FILES} <<'PY'
import sys, os, re, glob
from datetime import date

HARD_GATE = date(2026, 7, 1)
today = date.fromisoformat(sys.argv[1])
files = sys.argv[2:]

def parse_frontmatter(text):
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return {}
    fm = {}
    for ln in lines[1:]:
        if ln.strip() == "---":
            break
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):\s*(.*)$", ln)
        if m:
            fm[m.group(1)] = m.group(2)
    return fm

def blocks_by_level3(text):
    """回傳 list of (heading_line, body_text)；每個 ### 區塊到下一個 ###/##/# 或 EOF。"""
    lines = text.splitlines()
    out = []
    cur_head = None
    cur_body = []
    for ln in lines:
        if re.match(r"^#{1,3} ", ln):
            # 收束前一個 level-3 區塊
            if cur_head is not None:
                out.append((cur_head, "\n".join(cur_body)))
                cur_head, cur_body = None, []
            if ln.startswith("### "):
                cur_head = ln
                cur_body = []
            # ## / # 只是收束，不開新 level-3 區塊
        else:
            if cur_head is not None:
                cur_body.append(ln)
    if cur_head is not None:
        out.append((cur_head, "\n".join(cur_body)))
    return out

AXIS_FIELDS = ["Required", "Status", "Trace", "Static config", "Mechanism"]

def gen_at_date(fm):
    raw = (fm.get("generated_at") or "").strip()
    m = re.match(r"(\d{4})-(\d{2})-(\d{2})", raw)
    if not m:
        return None
    try:
        return date(int(m.group(1)), int(m.group(2)), int(m.group(3)))
    except ValueError:
        return None

def emit(level, msg):
    # level ∈ PASS / FAIL / WARN / SKIP
    print(f"{level}\t{msg}")

def status_value(fm):
    return (fm.get("status") or "").split("#")[0].strip().split()[0] if fm.get("status") else ""

for path in files:
    base = os.path.basename(path)
    try:
        text = open(path, encoding="utf-8").read()
    except Exception as e:
        emit("FAIL", f"{base} → 讀檔失敗：{e}")
        continue
    fm = parse_frontmatter(text)
    st = status_value(fm)
    if st == "superseded":
        emit("SKIP", f"{base} → status: superseded（跳過合約檢查）")
        continue

    tmpl = (fm.get("template") or "full").strip() or "full"
    gd = gen_at_date(fm)
    graced = (gd is None) or (gd < HARD_GATE)   # 無日期也寬限（保守）
    tag = "graced/WARN" if graced else "hard-gate"

    def verdict(ok, ok_msg, bad_msg):
        if ok:
            emit("PASS", ok_msg)
        elif graced:
            emit("WARN", bad_msg + f"（{base} generated_at<{HARD_GATE}，歷史寬限不計 fail）")
        else:
            emit("FAIL", bad_msg)

    blocks = blocks_by_level3(text)
    axis_blocks = [(h, b) for (h, b) in blocks if h.startswith("### Design Axis")]
    v_blocks = [(h, b) for (h, b) in blocks if re.match(r"^### V\d", h)]

    # ── full 版：(a) Design Axis 五欄位塊 ──
    if tmpl == "full":
        if not axis_blocks:
            verdict(False,
                    "",
                    f"{base} [full/{tag}] (a) 找不到任何 `### Design Axis` 區塊（掏空徵兆：標題在、語義空）")
        else:
            incomplete = []
            for h, body in axis_blocks:
                missing = [f for f in AXIS_FIELDS if not re.search(r"\*\*" + re.escape(f) + r"\*\*", body)]
                if missing:
                    axname = h[4:].strip()[:40]
                    incomplete.append(f"{axname}(缺 {'/'.join(missing)})")
            if incomplete:
                verdict(False, "",
                        f"{base} [full/{tag}] (a) {len(axis_blocks)} 個 axis 塊中 {len(incomplete)} 個缺欄位：" + "；".join(incomplete[:4]))
            else:
                emit("PASS", f"{base} [full/{tag}] (a) {len(axis_blocks)} 個 Design Axis 塊五欄位齊")

    # ── lite 版：V 表 + 「不動」清單段 ──
    if tmpl == "lite":
        if v_blocks:
            emit("PASS", f"{base} [lite/{tag}] V 表存在（{len(v_blocks)} 個 ### V 區塊）")
        else:
            verdict(False, "", f"{base} [lite/{tag}] 找不到 `### V` 條目表（lite 仍須保留 V 表與證據欄）")
        if re.search(r"不動", text):
            emit("PASS", f"{base} [lite/{tag}] 含「不動 / 保留」清單段")
        else:
            verdict(False, "", f"{base} [lite/{tag}] 缺「不動」清單段（保留邊界未宣告）")

    # ── (b)(c) 證據紀律：full 與 lite 皆適用 ──
    for h, body in v_blocks:
        vname = h[4:].strip()[:30]
        is_pass = bool(re.search(r"Status[:：]\s*✅", body))
        if not is_pass:
            continue
        # (b) Live-fired at 須為真時間戳
        lf = re.search(r"Live-fired at[:：]\s*([^\n　]+)", body)
        lf_val = lf.group(1).strip() if lf else ""
        if re.search(r"\d{4}-\d{2}-\d{2}", lf_val):
            emit("PASS", f"{base} (b) {vname} ✅ passing 有 Live-fired 時間戳（{lf_val[:24]}）")
        else:
            verdict(False, "", f"{base} (b) {vname} 標 ✅ passing 但 Live-fired at 非真時間戳（值：'{lf_val[:24]}'）")
        # (c) Verify level: script + ✅ → Self-verify runs 非空
        vl = re.search(r"Verify level[:：]\s*([^\n　]+)", body)
        vl_val = vl.group(1).strip() if vl else ""
        if vl_val.startswith("script"):
            sv = re.search(r"Self-verify runs[:：]\s*([^\n　]+)", body)
            sv_val = sv.group(1).strip() if sv else ""
            bad = (sv_val == "") or re.match(r"^(N/A|🚧|—|-)\b", sv_val) or sv_val in ("N/A", "🚧", "—", "-")
            if not bad:
                emit("PASS", f"{base} (c) {vname} script+✅ 有 Self-verify runs（{sv_val[:24]}）")
            else:
                verdict(False, "", f"{base} (c) {vname} script+✅ 但 Self-verify runs 空/N/A（值：'{sv_val[:24]}'）")

    # ── (d) 生命週期 nudge（永遠只 WARN）──
    if st == "draft" and gd is not None:
        age = (today - gd).days
        if age > 30:
            emit("WARN", f"{base} (d) status: draft 已 {age} 天（>30）— 建議轉 active/superseded")
PY
)
rc=$?
if [ "${rc}" -ne 0 ]; then
  echo "${RESULT}"
  echo "✗ python3 解析失敗（rc=${rc}）"
  exit 1
fi

# 統計份數（要驗的檔）
TOTAL=0
for f in ${FILES}; do TOTAL=$((TOTAL+1)); done
section "驗 ${TOTAL} 份 prescription 語義合約（superseded 跳過；<2026-07-01 寬限）"

while IFS=$'\t' read -r level msg; do
  [ -z "${level}" ] && continue
  case "${level}" in
    PASS) pass "${msg}" ;;
    FAIL) fail "${msg}" ;;
    WARN) warn "${msg}" ;;
    SKIP) echo "  ↷ ${msg}" ;;
  esac
done <<< "${RESULT}"

echo
if [ "${FAILS}" -eq 0 ]; then
  echo "✅ prescription 語義合約：${CHECKS} 項檢查全過（硬 gate 無失敗）"
  exit 0
else
  echo "❌ ${FAILS} / ${CHECKS} 項語義合約失敗 — 有掏空/證據缺漏（按 R-10 修到一致才能交付）"
  exit 1
fi
