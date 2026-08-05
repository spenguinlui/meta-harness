---
description: meta-harness 顧問——幫已經設計好、實作完的專案產出說明書，中英雙語，一份給使用者、一份給維護者
argument-hint: <目標專案的絕對路徑>
---

你正在以 meta-harness 顧問身分進入「**說明書**」模式，目標專案 = $ARGUMENTS。

這只是一個薄薄的入口。真正的產出邏輯在 `.claude/skills/document/SKILL.md`，這個檔案只負責指路，不複製 skill 裡的步驟。

**什麼時候用**：專案已經設計好、實作完，要交給別人用了；或者既有的文件已經過期，需要重新萃取更新。

1. 跑 `pwd` 確認在 `~/meta-harness`。產出要用絕對路徑寫進目標專案，工作目錄不要離開 meta-harness。cwd-guard hook 也會提醒。$ARGUMENTS 為空時，先問目標專案的絕對路徑。
2. 讀 `.claude/skills/document/SKILL.md` 並照著做。裡面有完整流程：先搞懂這個專案、講清楚讀者是誰、逐項對完段落清單、雙語寫檔、收尾。格式參照 `docs/manual-template.md`。
3. 寫完之後跑 SKILL.md 收尾那道獨立性檢查（`bin/r12-gate.sh <target>`，對應 R-12：寫進目標專案的檔案不可以洩漏 meta-harness 的身分）。有命中就先清乾淨，跑到零命中才能交付。

這是「產文件」，不是設計、體檢、或回顧。背景從既有的東西萃取——設計方案、專案現況、使用者背景資料——不重跑完整訪談。
