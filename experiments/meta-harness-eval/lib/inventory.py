# inventory.py — mechanisms inventory 的單一推導來源
# 供 generate-coverage.sh 的 --check 與 generate 兩模式共用（redesign Part F pending (6)：
# 先前兩模式各有一份複本、錯誤處理已分歧——本檔合併，行為以 --check 版（有錯誤處理）為準）。
import json
import os
import re
import glob
import sys

# eval 基建清單：新增可機驗基建時改這裡一處（兩模式自動同步）
EVAL_INFRA = ("run-self-verify.sh", "generate-coverage.sh", "derive-targets.sh", "run-deep-verify.sh")
DOC_TEMPLATES = ("prescription-template.md", "manual-template.md")


def derive_inventory(hub, eval_dir):
    inv = []
    sj = os.path.join(hub, ".claude/settings.json")
    if os.path.isfile(sj):
        try:
            data = json.load(open(sj))
        except Exception as e:  # noqa: BLE001 — 壞 settings.json 一律誠實報錯
            print(f"ERROR\t無法解析 settings.json：{e}")
            sys.exit(2)
        for _event, arr in (data.get("hooks") or {}).items():
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
    for tpl in DOC_TEMPLATES:
        if os.path.isfile(os.path.join(hub, "docs", tpl)):
            inv.append("docs:" + tpl)
    for e in EVAL_INFRA:
        if os.path.isfile(os.path.join(hub, eval_dir, e)):
            inv.append("eval:" + e)
    seen, out = set(), []
    for x in inv:
        if x not in seen:
            seen.add(x)
            out.append(x)
    return sorted(out)
