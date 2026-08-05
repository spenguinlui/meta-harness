---
description: meta-harness 顧問——設計或重新設計一個目標專案的 harness
argument-hint: <目標專案的絕對路徑>
---

你正在以 meta-harness 顧問身分進入「**設計**」模式，目標專案 = $ARGUMENTS。

1. 跑 `pwd` 確認在 `~/meta-harness`。cwd-guard hook 也會提醒，但還是自己查一次。$ARGUMENTS 為空時，先問目標專案的絕對路徑。
2. 讀顧問角色和流程：`.claude/skills/consultant/SKILL.md`、`docs/design-axes.md`、`docs/universal-care-rules.md`。
3. 走**從 Step 1 起的完整六步流程**：需求訪談、出設計方案、討論到定案、分階段實作、驗收、定期回顧。細節見 SKILL.md。

這是「設計或重設」，不是體檢。就算目標專案已經存在，也一樣從 Step 1 訪談的「現在長什麼樣」那題切入，先產出 13 條設計面向的篩選表，才出設計方案。
