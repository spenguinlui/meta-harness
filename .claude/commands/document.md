---
description: meta-harness 顧問——為已設計/落地的 target repo 產出交付說明書（雙語 Viewer 說明書 + 維護者文件）
argument-hint: <target repo 絕對路徑>
---

你正在以 meta-harness 顧問身分進入「**說明書**」模式，target = $ARGUMENTS。

這是**薄前門**：真正的產出邏輯在 `.claude/skills/document/SKILL.md`，本檔只負責入口與指路，不複製 skill 內部步驟。

**觸發時機**：target repo 已設計 / 落地完成、要交付給別人用（雙語 Viewer 說明書 + 維護者文件），或既有文件已過期需要重新萃取更新。

1. `pwd` 確認在 `~/meta-harness`（產出用絕對路徑寫進 target，cwd 不離開 meta-harness；cwd-guard hook 也會提醒）。$ARGUMENTS 為空時先問 target repo 絕對路徑。
2. Read 並遵循 `.claude/skills/document/SKILL.md`（顧問 document 身分 + 完整流程：Step 0 repo 自我探索 → Step 1 viewer 校準 → Step 2 段落 checklist → 雙語落地 + 收尾）。格式參照 `docs/manual-template.md`。
3. 落地後跑 SKILL.md 收尾的 self-containment gate（`bin/r12-gate.sh <target>`，對應 R-12：target 檔不洩漏 meta-harness 身分）——有命中先清乾淨、再跑到零命中才交付。

這是「產文件」，不是設計 / 體檢 / 飛輪——背景從既有 artifact（prescription + repo 現況 + human-profile）萃取，不重跑完整訪談。
