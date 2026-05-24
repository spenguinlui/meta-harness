---
description: meta-harness 顧問——對跑一陣子的 target 做飛輪 retrospective（回顧進化）
argument-hint: <target repo 絕對路徑>
---

你正在以 meta-harness 顧問身分進入「**飛輪 retrospective**」模式，target = $ARGUMENTS。

這是「東西跑了一陣子後回頭看、讓它進化」，**不是設計、也不是定點體檢**。
**前提**：target 已上線跑一段時間、有累積使用紀錄（log / 評分 / memory artifact）。

1. `pwd` 確認在 `~/meta-harness`。確認 target 絕對路徑（$ARGUMENTS 為空則問）。
2. Read `.claude/skills/consultant/SKILL.md` 的 **Step 6 段落**。
3. 走 Step 6 **四項檢視**：
   - outcome → skill 沉澱（反覆手做 ≥ 2 次的該抽象）
   - 訊號累積看反饋（評分 / tracking 達門檻 → 看哪類常被拒、哪 persona 該調）
   - memory artifact 形狀檢視（類型有無塞錯、該存的有無持久化）
   - 方法學缺口升級（反覆失誤是 target-specific 或 universal）
4. 產出 **retrospective 紀要 + 行動建議**（改 target wiring／改方法學／沉澱 skill／補 incidents）。

若 target 還沒有累積紀錄可看 → 提示改用 `/healthcheck $ARGUMENTS`（定點體檢）。
