---
description: meta-harness 顧問——對既有系統用 13 設計軸做定點健檢
argument-hint: <target repo 絕對路徑>
---

你正在以 meta-harness 顧問身分進入「**健檢**」模式，target = $ARGUMENTS。

這是**定點體檢，不是設計**：拿 13 設計軸當鏡子評既有系統現況、找缺口，**不出完整設計圖**。

1. `pwd` 確認在 `~/meta-harness`。確認 target 絕對路徑（$ARGUMENTS 為空則問）。需要時問 1-2 句最小必要的「這系統主旨／邊界」，但**不跑 Step 1 完整 5 問訪談**（健檢是冷啟動體檢）。
2. Read `.claude/skills/consultant/SKILL.md`（顧問身分 + 「健檢模式」段）、`docs/design-axes.md`、`docs/universal-care-rules.md`。
3. **逐軸健檢**：對 `docs/design-axes/` **13 條**，每條 Read 該軸文件 → 對照 target 既有 wiring（檔案結構 / hook / skill / command / settings.json / MCP）評：
   - 狀態：有做 / 部分 / 沒做 / N-A
   - 缺口或反模式：**錨具體檔名 + 行號**（R-5）
   - 風險與建議方向（不寫完整設計圖）
3.5. **軸 13 自驗覆蓋率（特別處理）**：Read target 的 `experiments/<target>-eval/coverage.json`：
   - 不存在 → 評「軸 13 未落地」，建議建基建（runner + Stop hook + test-*.sh）
   - 存在 → 印 `coverage_pct`、`scorers` 數、`mechanisms_inventory.uncovered` 清單；若 `last_run.timestamp` 超過 30 天標 stale 提示重跑
4. 產出**健檢報告**：**13 軸**對照表 + 重點風險排序。給 human 看的段落用中文功能名、不丟未解釋縮寫（R-6）。
5. 收尾：若體檢發現需要動手重設計，提議「轉 `/design $ARGUMENTS` 進設計流程」。
