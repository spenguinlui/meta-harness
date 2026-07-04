#!/bin/bash
# derive-targets.sh — 由證據推導 targets.yml 的機器欄（redesign 軸 3「登記簿給機器看」）
#
# 用法：
#   bash derive-targets.sh --check    # 重推導 vs 檔內 machine 欄；不一致 → exit 1 列 drift（不動檔）
#   bash derive-targets.sh --apply    # 重寫每個 target 的 machine 欄；human 欄一字不動；補登缺席 target
#
# 設計（軸 3 / Part D.5）：
#   - 機器讀的檔案由機器維護，人只維護意圖。targets.yml 每個 target 分兩欄：
#       machine:  status / dormant / last_evidence / prescriptions（全由證據推導）+ eval_dir（config，保留）
#       human:    domain / notes / intent（人自由寫，本腳本一字不動保留）
#   - 狀態機（全證據推導、人不手動轉）：
#       registered → designed（有非 superseded 的 prescription）
#                  → installed（該 prescription 內文出現「✅ installed」）
#                  → verified（target repo 的 coverage.json 存在且 last_run.timestamp < 90 天）
#     dormant（獨立布林）：最近證據（prescription generated_at / coverage timestamp）距今 > 90 天。
#   - 證據來源（只 stat 具名路徑，不對 target repo 做遞迴掃描）：
#       (a) prescriptions/*.md 的 frontmatter（target_repo / generated_at / status / template）+ 內文「✅ installed」
#       (b) targets.yml 的 path/eval_dir → 該 repo 的 coverage.json 存在性與 last_run.timestamp
#       (c) 具名檔案 mtime（僅在 prescription 無 generated_at 時作 fallback，維持 --check 決定性）
#   - 優雅降級：target path 不存在（如 figma2code）或 fresh clone 無 prescriptions/ → 機器欄填 unknown；
#     --check 對 unknown 不算 drift（無法核對的東西不謊報）。
#   - 相依：只用 python3 標準庫（無 PyYAML / 無第三方）。
#   - 已知限制（合約）：machine 區 config 欄（如 eval_dir）的「行內註解」不保留——
#     解釋性文字請寫進 human.notes，那裡逐字保留。
# 設計依據：docs/design-axes/3-memory.md、prescriptions/2026-07-04-meta-harness-redesign.md（軸 3 / D.5）
set -u

MODE=""
case "${1:-}" in
  --check) MODE="check" ;;
  --apply) MODE="apply" ;;
  *) echo "用法：bash derive-targets.sh --check|--apply"; exit 2 ;;
esac

# 先解析腳本自身位置——必須在 cd 之前（裸檔名呼叫時 dirname 是相對路徑，cd 後解析錯）
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
HUB="${CLAUDE_PROJECT_DIR:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
cd "$HUB" || { echo "cd HUB 失敗：$HUB"; exit 1; }
TODAY=$(date +%Y-%m-%d)

python3 - "$HUB" "$MODE" "$TODAY" <<'PY'
import sys, os, re, json, glob, datetime

hub, mode, today_str = sys.argv[1:4]
today = datetime.date.fromisoformat(today_str)
FRESH_DAYS = 90
TARGETS_PATH = os.path.join(hub, "targets.yml")
PRESC_DIR = os.path.join(hub, "prescriptions")

# ─── 小工具 ────────────────────────────────────────────────────────────
def parse_date(s):
    m = re.search(r"(\d{4})-(\d{2})-(\d{2})", s or "")
    if not m:
        return None
    try:
        return datetime.date(int(m.group(1)), int(m.group(2)), int(m.group(3)))
    except ValueError:
        return None

def strip_comment(v):
    return re.sub(r"\s+#.*$", "", v or "").strip()

# ─── 1. 掃 prescriptions/ ──────────────────────────────────────────────
def read_frontmatter(path):
    try:
        text = open(path, encoding="utf-8").read()
    except Exception:
        return {}, ""
    fm, body = {}, text
    if text.startswith("---"):
        lines = text.split("\n")
        end = None
        for i in range(1, len(lines)):
            if lines[i].strip() == "---":
                end = i
                break
        if end is not None:
            for ln in lines[1:end]:
                m = re.match(r"^([A-Za-z_][\w-]*):\s?(.*)$", ln)
                if m:
                    fm[m.group(1)] = m.group(2).strip()
            body = "\n".join(lines[end + 1:])
    return fm, body

def name_from_repo(repo):
    m = re.match(r"\s*([A-Za-z0-9_][A-Za-z0-9_-]*)", repo or "")
    return m.group(1) if m else None

def path_from_repo(repo):
    m = re.search(r"(~?/[^\s()]+)", repo or "")
    if not m:
        return None
    p = m.group(1)
    return os.path.expanduser(p) if p.startswith("~") else p

def scan_prescriptions():
    presc = {}   # name -> list of dicts
    if not os.path.isdir(PRESC_DIR):
        return presc  # fresh clone 無 prescriptions/ → 空（後續降級）
    for f in sorted(glob.glob(os.path.join(PRESC_DIR, "*.md"))):
        base = os.path.basename(f)
        if base.lower() == "readme.md":
            continue
        fm, body = read_frontmatter(f)
        repo = fm.get("target_repo", "")
        name = name_from_repo(repo)
        if not name or name == "meta-harness":
            continue  # meta-harness = hub 自身，非登記簿 target
        try:
            mtime = datetime.date.fromtimestamp(os.path.getmtime(f))
        except Exception:
            mtime = None
        presc.setdefault(name, []).append({
            "file": base,
            "status": fm.get("status", "").strip(),
            "template": fm.get("template", "").strip(),
            "generated_at": parse_date(fm.get("generated_at", "")),
            "installed": "✅ installed" in body,
            "repo_path": path_from_repo(repo),
            "mtime": mtime,
        })
    return presc

PRESC = scan_prescriptions()
HAS_PRESC_DIR = os.path.isdir(PRESC_DIR)

# ─── 2. 狀態推導 ───────────────────────────────────────────────────────
def resolve_path(raw):
    if not raw or raw == "null":
        return None
    return raw if os.path.isabs(raw) else os.path.join(hub, raw)

def coverage_ts(abs_path, name, eval_dir):
    ed = eval_dir or ("experiments/%s-eval" % name)
    cov = os.path.join(abs_path, ed, "coverage.json")
    if not os.path.isfile(cov):
        return (False, None)
    try:
        data = json.load(open(cov))
        return (True, parse_date((data.get("last_run") or {}).get("timestamp", "")))
    except Exception:
        return (True, None)

def derive(name, raw_path, eval_dir):
    plist = PRESC.get(name, [])
    presc_files = sorted(p["file"] for p in plist)
    abs_path = resolve_path(raw_path)

    # 優雅降級：宣告了 path 但檔案系統上不存在 → 無法核對 → unknown
    if abs_path is not None and not os.path.exists(abs_path):
        return {
            "status": "unknown", "dormant": "unknown", "last_evidence": "unknown",
            "prescriptions": presc_files, "eval_dir": eval_dir,
            "reason": "target path 不存在（%s）→ 無法核對落地/新鮮證據" % raw_path,
            "unknown": True,
        }
    # 優雅降級：整個 prescriptions/ 缺（fresh clone）→ 推不出 designed 以上 → unknown
    if not HAS_PRESC_DIR:
        return {
            "status": "unknown", "dormant": "unknown", "last_evidence": "unknown",
            "prescriptions": [], "eval_dir": eval_dir,
            "reason": "無 prescriptions/（fresh clone）→ 無證據可推導",
            "unknown": True,
        }

    non_super = [p for p in plist if p["status"] != "superseded"]
    cov_exists, cov_dt = coverage_ts(abs_path, name, eval_dir) if abs_path else (False, None)

    ev_dates = []
    for p in plist:
        d = p["generated_at"] or p["mtime"]  # generated_at 主，mtime 僅 fallback（維持決定性）
        if d:
            ev_dates.append(d)
    if cov_dt:
        ev_dates.append(cov_dt)
    last_ev = max(ev_dates) if ev_dates else None

    fresh = cov_exists and cov_dt is not None and (today - cov_dt).days < FRESH_DAYS
    if fresh:
        status = "verified"
    elif any(p["installed"] for p in non_super):
        status = "installed"
    elif non_super:
        status = "designed"
    else:
        status = "registered"

    dormant = (last_ev is not None) and ((today - last_ev).days > FRESH_DAYS)
    return {
        "status": status,
        "dormant": dormant,
        "last_evidence": last_ev.isoformat() if last_ev else None,
        "prescriptions": presc_files,
        "eval_dir": eval_dir,
        "unknown": False,
    }

# ─── 3. 解析既有 targets.yml（stdlib，結構感知；human 欄逐字保留）────────
def split_file(text):
    lines = text.split("\n")
    header, footer, blocks = [], [], []
    cur = None
    i, n = 0, len(lines)
    while i < n and not re.match(r"^-\s", lines[i]):
        header.append(lines[i]); i += 1
    while i < n:
        ln = lines[i]
        if re.match(r"^-\s", ln):
            if cur is not None:
                blocks.append(cur)
            cur = [ln]
        elif re.match(r"^\s", ln) or ln == "":
            if cur is not None:
                cur.append(ln)
            else:
                header.append(ln)
        else:  # col-0 非 dash（例如結尾 concept 註解區）→ footer 起
            if cur is not None:
                blocks.append(cur); cur = None
            footer.append(ln)
        i += 1
    if cur is not None:
        blocks.append(cur)
    # 去除各 block 尾端空行
    for b in blocks:
        while b and b[-1].strip() == "":
            b.pop()
    return header, blocks, footer

def find_scalar(block, key):
    for ln in block:
        m = re.match(r"^\s*(?:-\s+)?" + re.escape(key) + r":\s?(.*)$", ln)
        if m:
            return strip_comment(m.group(1))
    return None

def find_eval_dir(block):
    for ln in block:
        m = re.match(r"^\s*eval_dir:\s?(.*)$", ln)
        if m:
            return strip_comment(m.group(1)) or None
    return None

def idx_of(block, key):
    for i, ln in enumerate(block):
        if re.match(r"^\s*" + re.escape(key) + r":\s*$", ln):
            return i
    return None

def extract_human(block):
    """新 schema：回傳 human 區塊逐字（含 '  human:' 行）；舊 schema：None。"""
    hi = idx_of(block, "human")
    if hi is None:
        return None
    hb = block[hi:]
    while hb and hb[-1].strip() == "":
        hb.pop()
    return hb

def extract_notes_lines(block):
    """舊 schema notes: | 區塊 → dedent 後的文字行 list。"""
    for i, ln in enumerate(block):
        m = re.match(r"^(\s*)notes:\s*\|\s*$", ln)
        if not m:
            continue
        base = len(m.group(1))
        body = []
        for ln2 in block[i + 1:]:
            if ln2.strip() == "":
                body.append("")
                continue
            ind = len(ln2) - len(ln2.lstrip(" "))
            if ind <= base:
                break
            body.append(ln2)
        indents = [len(b) - len(b.lstrip(" ")) for b in body if b.strip()]
        if indents:
            cut = min(indents)
            body = [(b[cut:] if b.strip() else "") for b in body]
        while body and body[-1] == "":
            body.pop()
        return body
    return None

def machine_lines_of(block):
    mi = idx_of(block, "machine")
    if mi is None:
        return None
    hi = idx_of(block, "human")
    return block[mi:hi] if hi is not None else block[mi:]

def parse_stored_machine(block):
    ml = machine_lines_of(block)
    d = {"status": None, "dormant": None, "last_evidence": None, "prescriptions": []}
    if ml is None:
        return d
    in_presc = False
    for ln in ml:
        for key in ("status", "dormant", "last_evidence"):
            m = re.match(r"^\s{4}" + key + r":\s?(.*)$", ln)
            if m:
                d[key] = strip_comment(m.group(1)); in_presc = False; break
        else:
            m = re.match(r"^\s{4}prescriptions:\s?(.*)$", ln)
            if m:
                rest = m.group(1).strip()
                if rest == "[]":
                    in_presc = False
                else:
                    in_presc = True
                continue
            if in_presc:
                mm = re.match(r"^\s{6}-\s+(.*)$", ln)
                if mm:
                    d["prescriptions"].append(mm.group(1).strip())
                else:
                    in_presc = False
    return d

# ─── 4. 產出 YAML 片段 ─────────────────────────────────────────────────
def y_bool(v):
    if v == "unknown":
        return "unknown"
    return "true" if v else "false"

def build_machine(m):
    out = ["  machine:"]
    out.append("    status: " + str(m["status"]))
    out.append("    dormant: " + y_bool(m["dormant"]))
    le = m["last_evidence"]
    out.append("    last_evidence: " + (le if le else "null"))
    if m["prescriptions"]:
        out.append("    prescriptions:")
        for p in m["prescriptions"]:
            out.append("      - " + p)
    else:
        out.append("    prescriptions: []")
    if m.get("eval_dir"):
        out.append("    eval_dir: " + m["eval_dir"])
    if m.get("reason"):
        out.append("    # unknown 原因：" + m["reason"])
    return out

def build_human_from_old(domain, notes_lines):
    out = ["  human:"]
    if domain and domain != "null":
        out.append("    domain: " + domain)
    if notes_lines:
        out.append("    notes: |")
        for nl in notes_lines:
            out.append(("      " + nl) if nl else "")
    if len(out) == 1:
        out.append("    notes: null")
    return out

def build_human_autoregister(name):
    return [
        "  human:",
        "    notes: |",
        "      自動補登：derive-targets.sh 偵測 prescriptions/ 有 %s 但 targets.yml 未登記。" % name,
        "      intent / domain 待人工補。",
    ]

HEADER = """# 本機 harness repo 清單。顧問 session 開場時從此挑 target，或直接在對話中給絕對路徑。
#
# 每個 target 分兩欄（redesign 軸 3「登記簿是給機器看的」）：
#   machine: 由 derive-targets.sh 從證據推導並維護（status / dormant / last_evidence /
#            prescriptions / eval_dir）。手改會被 test-registry-freshness.sh 抓成 drift。
#            狀態機：registered → designed（有非 superseded prescription）→ installed
#            （Part D 出現「✅ installed」）→ verified（target coverage.json 存在且 last_run < 90 天）。
#            dormant：最近證據距今 > 90 天。來源缺失（path 不存在 / 無 prescriptions/）→ unknown（不算 drift）。
#   human:   隨你寫（domain / notes / intent）。derive-targets.sh 一字不動地保留。
# 重建 / 補登：bash experiments/meta-harness-eval/derive-targets.sh --apply
# 檢查漂移：  bash experiments/meta-harness-eval/derive-targets.sh --check
# 格式範例見 targets.yml.example。""".split("\n")

# ─── 5. 主流程 ─────────────────────────────────────────────────────────
existing_text = ""
if os.path.isfile(TARGETS_PATH):
    existing_text = open(TARGETS_PATH, encoding="utf-8").read()
header, blocks, footer = split_file(existing_text) if existing_text else ([], [], [])

# 每個既有 block 抽 identity + config + human
targets = []           # 有序：既有 target
seen_names = set()
for b in blocks:
    name = find_scalar(b, "name")
    if not name:
        continue
    raw_path = find_scalar(b, "path")
    eval_dir = find_eval_dir(b)
    human = extract_human(b)  # 新 schema 逐字；舊 schema None
    domain = None
    notes_lines = None
    if human is None:  # 舊 schema → 建 human
        domain = find_scalar(b, "domain")
        notes_lines = extract_notes_lines(b)
    stored_machine = parse_stored_machine(b)
    targets.append({
        "name": name, "raw_path": raw_path, "eval_dir": eval_dir,
        "human": human, "domain": domain, "notes_lines": notes_lines,
        "stored_machine": stored_machine, "auto": False,
    })
    seen_names.add(name)

# 補登：prescriptions/ 有、targets.yml 沒有的 target
for name in sorted(PRESC.keys()):
    if name in seen_names:
        continue
    raw_path = None
    for p in PRESC[name]:
        if p.get("repo_path"):
            raw_path = p["repo_path"]; break
    targets.append({
        "name": name, "raw_path": raw_path, "eval_dir": None,
        "human": None, "domain": None, "notes_lines": None,
        "stored_machine": {"status": None, "dormant": None, "last_evidence": None, "prescriptions": []},
        "auto": True,
    })

# 逐 target 推導
for t in targets:
    t["derived"] = derive(t["name"], t["raw_path"], t["eval_dir"])

# ─── CHECK 模式：比對推導 vs 檔內 machine 欄 ───────────────────────────
if mode == "check":
    if not os.path.isfile(TARGETS_PATH):
        print("ERROR\ttargets.yml 不存在（先跑 --apply）"); sys.exit(1)
    drifts = []
    unknowns = []
    missing_reg = [t["name"] for t in targets if t["auto"]]  # 該補登但檔內沒有
    for t in targets:
        d = t["derived"]
        if d.get("unknown"):
            unknowns.append((t["name"], d.get("reason", "")))
            continue
        if t["auto"]:
            continue  # 補登缺席者交由下方 missing_reg 報
        s = t["stored_machine"]
        want = {
            "status": str(d["status"]),
            "dormant": y_bool(d["dormant"]),
            "last_evidence": d["last_evidence"] if d["last_evidence"] else "null",
            "prescriptions": list(d["prescriptions"]),
        }
        got = {
            "status": s["status"],
            "dormant": s["dormant"],
            "last_evidence": s["last_evidence"],
            "prescriptions": s["prescriptions"],
        }
        for k in ("status", "dormant", "last_evidence", "prescriptions"):
            if want[k] != got[k]:
                drifts.append((t["name"], k, got[k], want[k]))
    for name in missing_reg:
        drifts.append((name, "(缺登記)", "不在 targets.yml", "prescriptions/ 有 → 應 --apply 補登"))

    if unknowns:
        print("ℹ️  unknown（來源缺失，--check 不算 drift）：")
        for name, reason in unknowns:
            print("   · %s — %s" % (name, reason))
    if drifts:
        print("❌ targets.yml machine 欄 drift（檔內值 vs 證據推導值）：")
        for name, k, got, want in drifts:
            print("  · %s.%s: 檔內=%r  推導=%r" % (name, k, got, want))
        print("  → machine 欄由證據推導，人只維護 human 欄。跑 `derive-targets.sh --apply` 重建。")
        sys.exit(1)
    print("✅ targets.yml machine 欄與證據一致（%d target 核對；%d 個 unknown 略過）"
          % (len([t for t in targets if not t['derived'].get('unknown')]), len(unknowns)))
    sys.exit(0)

# ─── APPLY 模式：重寫 machine 欄，human 欄逐字保留 ──────────────────────
out_lines = list(HEADER)
out_lines.append("")
for idx, t in enumerate(targets):
    d = t["derived"]
    raw_path = t["raw_path"] if t["raw_path"] else "null"
    out_lines.append("- name: " + t["name"])
    out_lines.append("  path: " + raw_path)
    out_lines.extend(build_machine(d))
    if t["human"] is not None:            # 既有 human 欄 → 逐字保留
        out_lines.extend(t["human"])
    elif t["auto"]:                        # 補登 target → 佔位 human
        out_lines.extend(build_human_autoregister(t["name"]))
    else:                                  # 舊 schema 遷移 → 由 domain + notes 建 human
        out_lines.extend(build_human_from_old(t["domain"], t["notes_lines"]))
    out_lines.append("")

if footer:
    out_lines.extend(footer)
    if out_lines and out_lines[-1].strip() != "":
        out_lines.append("")

text_out = "\n".join(out_lines).rstrip("\n") + "\n"
open(TARGETS_PATH, "w", encoding="utf-8").write(text_out)

# 摘要
print("wrote %s" % TARGETS_PATH)
print("── 推導摘要（%d target）──" % len(targets))
for t in targets:
    d = t["derived"]
    tag = " [補登]" if t["auto"] else ""
    extra = ""
    if d.get("reason"):
        extra = "  ← " + d["reason"]
    print("  %-22s status=%-10s dormant=%-7s last_evidence=%-10s presc=%d%s%s" % (
        t["name"], str(d["status"]), y_bool(d["dormant"]),
        (d["last_evidence"] or "null"), len(d["prescriptions"]), tag, extra))
PY
rc=$?
exit $rc
