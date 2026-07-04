#!/bin/bash
# generate-coverage.sh v2 — 生成 coverage.json（軸 13 數據面板），分母機器推導
#
# 用法：
#   bash generate-coverage.sh            # 重算並寫 coverage.json（automated 欄重算、機器推導 inventory）
#   bash generate-coverage.sh --check    # 只比對「檔內 mechanisms_inventory vs 重新推導」，不一致 → exit 1
#
# v2 變更（redesign 軸 13 / D.5）：
#   1. mechanisms inventory = 機器掃描：.claude/settings.json 註冊的每支 hook
#      + .claude/commands/*.md + .claude/skills/*/SKILL.md + bin/*.sh
#      + docs 模板類（prescription-template.md、manual-template.md）+ eval 基建（run-self-verify.sh、generate-coverage.sh）。
#      人工不可直接改 total；只能在 coverage-exclusions.json 加「排除項 + 理由」。
#   2. covered = union(scorers[].covers)（每支 scorer 檔頭 `# covers:` 宣告涵蓋的 mechanism）∩ inventory；
#      uncovered = inventory − covered − excluded；total/uncovered 自動算。
#   3. coverage-exclusions.json 的排除項必附 reason，且掃描結果須仍實存該 mechanism（防殭屍排除）。
#   4. --check：純靜態（不跑任何 test），重新推導 inventory 與 stored 比對；人手改分母會被抓。
#   5. totals 增 format_checks / semantic_checks（semantic = Pattern C 檢查數，目前 0）。
# 設計依據：docs/design-axes/13-self-verify-coverage.md
set -u

MODE="generate"
[ "${1:-}" = "--check" ] && MODE="check"

# 先解析腳本自身位置——必須在 cd 之前：裸檔名呼叫時 dirname 是相對路徑，cd 後就解析錯
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
HUB="${CLAUDE_PROJECT_DIR:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
cd "$HUB" || exit 1
# 自動從腳本位置推 EVAL_DIR（portable，meta-harness 與各 target 共用同一份程式）
EVAL_DIR=${SCRIPT_DIR#${HUB}/}
COV="${EVAL_DIR}/coverage.json"
EXCL="${EVAL_DIR}/coverage-exclusions.json"
TARGET_NAME=$(basename "${HUB}")

# ─── --check 模式：純靜態推導 + 比對，不跑 test ────────────────────────
if [ "$MODE" = "check" ]; then
  python3 - "$HUB" "$EVAL_DIR" "$COV" "$EXCL" <<'PY'
import sys, os, json, re, glob
hub, eval_dir, cov_path, excl_path = sys.argv[1:5]

def derive_inventory():
    inv = []
    sj = os.path.join(hub, ".claude/settings.json")
    if os.path.isfile(sj):
        try:
            data = json.load(open(sj))
        except Exception as e:
            print(f"ERROR\t無法解析 settings.json：{e}"); sys.exit(2)
        for event, arr in (data.get("hooks") or {}).items():
            for group in (arr or []):
                for h in (group.get("hooks") or []):
                    m = re.search(r"([A-Za-z0-9_.-]+\.sh)", h.get("command", ""))
                    if m:
                        inv.append("hook:" + m.group(1))
    for f in sorted(glob.glob(os.path.join(hub, ".claude/commands/*.md"))):
        inv.append("command:" + os.path.basename(f))
    for f in sorted(glob.glob(os.path.join(hub, ".claude/skills/*/SKILL.md"))):
        inv.append("skill:" + os.path.basename(os.path.dirname(f)))
    for f in sorted(glob.glob(os.path.join(hub, "bin/*.sh"))):
        inv.append("bin:" + os.path.basename(f))
    for tpl in ("prescription-template.md", "manual-template.md"):
        if os.path.isfile(os.path.join(hub, "docs", tpl)):
            inv.append("docs:" + tpl)
    for e in ("run-self-verify.sh", "generate-coverage.sh", "derive-targets.sh"):
        if os.path.isfile(os.path.join(hub, eval_dir, e)):
            inv.append("eval:" + e)
    seen, out = set(), []
    for x in inv:
        if x not in seen:
            seen.add(x); out.append(x)
    return sorted(out)

def read_covers():
    covered = set()
    for f in sorted(glob.glob(os.path.join(hub, eval_dir, "test-*.sh"))):
        for line in open(f, encoding="utf-8"):
            m = re.match(r"^# covers:\s*(.*)$", line)
            if m:
                for tok in re.split(r"[,\s]+", m.group(1).strip()):
                    if ":" in tok:
                        covered.add(tok.strip())
                break
    return covered

def read_exclusions(inventory):
    excl = []
    if os.path.isfile(excl_path):
        try:
            data = json.load(open(excl_path))
        except Exception as e:
            print(f"ERROR\t無法解析 {excl_path}：{e}"); sys.exit(2)
        for item in (data or []):
            mech = (item or {}).get("mechanism"); reason = (item or {}).get("reason")
            if not mech or not reason:
                print(f"ERROR\t排除項缺 mechanism/reason：{item}"); sys.exit(2)
            if mech not in inventory:
                print(f"ERROR\t殭屍排除：'{mech}' 已不在掃描結果中（不實存的 mechanism 不能排除）"); sys.exit(2)
            excl.append({"mechanism": mech, "reason": reason})
    return excl

def derive_block():
    inventory = derive_inventory()
    excl = read_exclusions(inventory)
    covered_set = read_covers() & set(inventory)
    excl_set = {e["mechanism"] for e in excl}
    uncovered = sorted(m for m in inventory if m not in covered_set and m not in excl_set)
    in_scope = len(inventory) - len(excl_set)
    pct = round(len(covered_set) / in_scope * 100) if in_scope else 0
    return {
        "total": len(inventory),
        "covered": len(covered_set),
        "coverage_pct": pct,
        "uncovered": uncovered,
        "excluded": sorted(excl, key=lambda e: e["mechanism"]),
        "inventory": inventory,
    }

def normalize(block):
    return {
        "total": block.get("total"),
        "covered": block.get("covered"),
        "coverage_pct": block.get("coverage_pct"),
        "uncovered": sorted(block.get("uncovered") or []),
        "excluded": sorted(block.get("excluded") or [], key=lambda e: e.get("mechanism", "")),
        "inventory": sorted(block.get("inventory") or []),
    }

derived = derive_block()
if not os.path.isfile(cov_path):
    print(f"ERROR\t{cov_path} 不存在（先跑一次 generate-coverage.sh）"); sys.exit(1)
try:
    stored = (json.load(open(cov_path)) or {}).get("mechanisms_inventory") or {}
except Exception as e:
    print(f"ERROR\t無法解析 {cov_path}：{e}"); sys.exit(1)

d, s = normalize(derived), normalize(stored)
diffs = []
for k in d:
    if d[k] != s.get(k):
        diffs.append((k, s.get(k), d[k]))
if diffs:
    print("❌ coverage.json 分母 drift：檔內 mechanisms_inventory 與重新推導不一致")
    for k, stored_v, derived_v in diffs:
        if k in ("uncovered", "inventory"):
            sset, dset = set(stored_v or []), set(derived_v or [])
            print(f"  · {k}: 檔內多 {sorted(sset-dset)}；推導多 {sorted(dset-sset)}")
        else:
            print(f"  · {k}: 檔內={stored_v} 推導={derived_v}")
    print("  → 分母/涵蓋由機器推導，人工只能改 coverage-exclusions.json（附理由）。跑 `generate-coverage.sh` 重生。")
    sys.exit(1)
print(f"✅ coverage.json inventory 與掃描結果一致（total={d['total']}, covered={d['covered']}, uncovered={len(d['uncovered'])}, excluded={len(d['excluded'])}）")
sys.exit(0)
PY
  exit $?
fi

# ─── generate 模式：跑每支 test 抓 rc/checks/pattern/covers ──────────────
SCORERS_JSON=""; TOTAL_SCORERS=0; TOTAL_CHECKS=0; PASSED_CHECKS=0; ANY_FAIL=0
for f in "$EVAL_DIR"/test-*.sh; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  pattern=$(grep -m1 "^# pattern:" "$f" | sed -E 's/^# pattern:[[:space:]]*([A-D]).*/\1/')
  pattern="${pattern:-?}"
  covers_raw=$(grep -m1 "^# covers:" "$f" | sed -E 's/^# covers:[[:space:]]*//')
  # covers_raw → JSON array（只收含 : 的 token）
  covers_json=$(printf '%s' "$covers_raw" | tr ', ' '\n\n' | grep ':' | sed -E 's/^[[:space:]]*//; s/[[:space:]]*$//' \
                | awk 'NF{printf "%s\"%s\"", (NR>1&&seen?",":""), $0; seen=1} END{}' )
  covers_json="[${covers_json}]"
  out=$(bash "$f" 2>&1); rc=$?
  checks=$(printf '%s\n' "$out" | grep -oE "([0-9]+)[[:space:]]*(項|處|/)" | grep -oE "^[0-9]+" | sort -rn | head -1)
  checks="${checks:-0}"
  pass_str=$([ "$rc" -eq 0 ] && echo true || echo false)
  [ "$rc" -ne 0 ] && ANY_FAIL=1
  [ -n "$SCORERS_JSON" ] && SCORERS_JSON="$SCORERS_JSON,"
  SCORERS_JSON="$SCORERS_JSON{\"name\":\"$name\",\"pattern\":\"$pattern\",\"checks\":$checks,\"last_pass\":$pass_str,\"covers\":$covers_json}"
  TOTAL_SCORERS=$((TOTAL_SCORERS+1))
  TOTAL_CHECKS=$((TOTAL_CHECKS+checks))
  [ "$rc" -eq 0 ] && PASSED_CHECKS=$((PASSED_CHECKS+checks))
done

NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LAST_RC=$([ "$ANY_FAIL" -eq 0 ] && echo 0 || echo 1)

python3 - "$COV" "$EXCL" "$HUB" "$EVAL_DIR" "$TARGET_NAME" "$NOW" \
              "$EVAL_DIR/run-self-verify.sh" "$TOTAL_SCORERS" "$TOTAL_CHECKS" \
              "$PASSED_CHECKS" "$LAST_RC" "$SCORERS_JSON" <<'PY'
import json, sys, os, re, glob
(cov_path, excl_path, hub, eval_dir, target, now, runner,
 ns, nc, np_, rc, scorers_raw) = sys.argv[1:13]

def derive_inventory():
    inv = []
    sj = os.path.join(hub, ".claude/settings.json")
    if os.path.isfile(sj):
        data = json.load(open(sj))
        for event, arr in (data.get("hooks") or {}).items():
            for group in (arr or []):
                for h in (group.get("hooks") or []):
                    m = re.search(r"([A-Za-z0-9_.-]+\.sh)", h.get("command", ""))
                    if m:
                        inv.append("hook:" + m.group(1))
    for f in sorted(glob.glob(os.path.join(hub, ".claude/commands/*.md"))):
        inv.append("command:" + os.path.basename(f))
    for f in sorted(glob.glob(os.path.join(hub, ".claude/skills/*/SKILL.md"))):
        inv.append("skill:" + os.path.basename(os.path.dirname(f)))
    for f in sorted(glob.glob(os.path.join(hub, "bin/*.sh"))):
        inv.append("bin:" + os.path.basename(f))
    for tpl in ("prescription-template.md", "manual-template.md"):
        if os.path.isfile(os.path.join(hub, "docs", tpl)):
            inv.append("docs:" + tpl)
    for e in ("run-self-verify.sh", "generate-coverage.sh", "derive-targets.sh"):
        if os.path.isfile(os.path.join(hub, eval_dir, e)):
            inv.append("eval:" + e)
    seen, out = set(), []
    for x in inv:
        if x not in seen:
            seen.add(x); out.append(x)
    return sorted(out)

scorers = json.loads("[" + scorers_raw + "]")
inventory = derive_inventory()

# covered = union(scorers[].covers) ∩ inventory
covered_set = set()
for s in scorers:
    for c in (s.get("covers") or []):
        covered_set.add(c)
covered_set &= set(inventory)

# exclusions（附 reason，防殭屍）
excl = []
if os.path.isfile(excl_path):
    data = json.load(open(excl_path))
    for item in (data or []):
        mech = (item or {}).get("mechanism"); reason = (item or {}).get("reason")
        if not mech or not reason:
            print(f"ERROR：排除項缺 mechanism/reason：{item}", file=sys.stderr); sys.exit(2)
        if mech not in inventory:
            print(f"ERROR：殭屍排除 '{mech}' 不在掃描結果中", file=sys.stderr); sys.exit(2)
        excl.append({"mechanism": mech, "reason": reason})
excl_set = {e["mechanism"] for e in excl}

uncovered = sorted(m for m in inventory if m not in covered_set and m not in excl_set)
in_scope = len(inventory) - len(excl_set)
pct = round(len(covered_set) / in_scope * 100) if in_scope else 0

format_checks = sum(int(s.get("checks", 0)) for s in scorers if s.get("pattern") in ("A", "B"))
semantic_checks = sum(int(s.get("checks", 0)) for s in scorers if s.get("pattern") == "C")

out = {
    "target": target,
    "generated_at": now,
    "runner": runner,
    "scorers": scorers,
    "totals": {
        "scorers": int(ns), "checks_total": int(nc), "checks_passed": int(np_),
        "format_checks": format_checks, "semantic_checks": semantic_checks,
    },
    "mechanisms_inventory": {
        "total": len(inventory),
        "covered": len(covered_set),
        "coverage_pct": pct,
        "uncovered": uncovered,
        "excluded": sorted(excl, key=lambda e: e["mechanism"]),
        "inventory": inventory,
        "_note": "machine-derived by generate-coverage.sh（掃 settings.json hooks × commands × skills × bin × docs 模板 × eval 基建）。人工不可直接改 total / inventory；只能在 coverage-exclusions.json 加排除項（附 reason）。手改本區塊 → `generate-coverage.sh --check` 會抓。",
    },
    "last_run": {"timestamp": now, "rc": int(rc)},
}
json.dump(out, open(cov_path, "w"), ensure_ascii=False, indent=2)
print(f"wrote {cov_path}")
PY

echo
echo "── coverage 摘要 ──"
python3 -c "
import json
c = json.load(open('$COV'))
t = c['totals']; inv = c['mechanisms_inventory']; lr = c['last_run']
print(f\"  scorers        : {t['scorers']}\")
print(f\"  checks_total   : {t['checks_total']}（passed: {t['checks_passed']}）\")
print(f\"  format/semantic: {t['format_checks']} / {t['semantic_checks']}\")
print(f\"  last_run       : rc={lr['rc']} @ {lr['timestamp']}\")
print(f\"  coverage       : {inv['coverage_pct']}%（covered {inv['covered']} / total {inv['total']}；uncovered {len(inv['uncovered'])}，excluded {len(inv['excluded'])}）\")
if inv['uncovered']:
    print('  uncovered      : ' + ', '.join(inv['uncovered']))
"
