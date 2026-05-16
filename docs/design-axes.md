# Harness 12 大設計軸（索引）

> 任何 agent harness 都應在這 12 條軸上做出明確設計決策。每條都不是 0/1 開關，而是有十幾種選項，且彼此耦合。
> Stakes 不同的 target 不一定要全跑——小工具可能只需要設計軸 1/3/5，infra 管理類可能要 1-12 全套（業主與顧問共同篩選）。

每條詳細設計決策、與其他設計軸耦合、反模式、案例評析在 `design-axes/` 子目錄：

- [1. Tool 執行](design-axes/1-tool-execution.md)
- [2. Context 管理](design-axes/2-context-management.md)
- [3. Memory 管理](design-axes/3-memory.md)
- [4. Planning loop](design-axes/4-planning-loop.md)
- [5. Execution loop](design-axes/5-execution-loop.md) — 單一 agent 的「模型↔工具」迴圈
- [6. 權限 / 安全](design-axes/6-safety.md)
- [7. Hooks（reactive）](design-axes/7-hooks.md) — **被動**攔截，外部事件發生時觸發
- [8. Evaluation loop](design-axes/8-evaluation-loop.md)
- [9. 觀測](design-axes/9-observability.md) — **system-facing IO 邊界**
- [10. Multi-agent / Sub-agent Orchestration](design-axes/10-multi-agent-orchestration.md) — **2026-05-09 新增**
- [11. Triggers / Schedule（active）](design-axes/11-triggers-schedule.md) — **主動**自我喚醒；**2026-05-09 新增**
- [12. Human Interface](design-axes/12-human-interface.md) — **human-facing IO 邊界**（給每天用工具的人看，不是 builder）；**2026-05-11 新增**

## 7 vs 11 邊界

- **設計軸 7 Hooks** 精神是「**有事我攔下**」（PreToolUse / PostToolUse / UserPromptSubmit）
- **設計軸 11 Triggers** 精神是「**沒事我自己跑**」（cron / `/loop` / `ScheduleWakeup`）
- 混在一條會讓設計者搞不清 reactive vs active 邊界

## 5 vs 10 邊界

- **設計軸 5 Execution loop** = 單一 agent 內部的迴圈
- **設計軸 10 Multi-agent** = 多個 agent 之間的 hand-off / context 邊界 / 結果整合

## 9 vs 12 邊界（兩個 IO 邊界對稱）

- **設計軸 9 觀測** = 給**工程師 / 系統**看的 IO（trace / log / metric / cost）
- **設計軸 12 Human Interface** = 給**每天用工具的人**看的 IO（翻譯層 / 業主能力模型 / 回饋通道）
- 沒分清 = 同一輸出對兩種對象說同樣的話，要嘛 builder 嫌囉嗦、要嘛 human 看不懂

以下為摘要：

## 1. Tool 執行

模型輸出 tool call，harness 解析並執行。

要決策：
- 顆粒度：一個 tool 做一件事 vs 大而全 composite
- 輸入 schema（必填、型別、範例）
- 輸出 schema（成功、失敗、部分成功）
- 副作用聲明（read-only / mutating / destructive）
- 冪等性
- 失敗處理（重試？回報？停止？）
- 同步 vs 背景

## 2. Context 管理

單 session 內 token 怎麼配。

要決策：
- 哪些檔案/狀態自動載入 vs 懶載
- 壓縮策略（長對話）
- Cache 邊界（什麼穩定、什麼會變）
- 用 sub-agent 隔離 vs 主 context

## 3. Memory 管理

跨 session 的持續知識。和 context 是兩件事。

層級：
- Session memory（短期，session 結束就丟）
- Project memory（CLAUDE.md，跟 repo 走）
- User memory（個人，跨專案）
- Shared/world memory（團隊 runbook、ADR、RAG 用）

要決策：
- 寫入時機（明確 vs 自動）
- 寫入分類（fact / preference / decision / failure-lesson / reference）
- 讀取策略（全載 vs 召回）
- TTL、衝突解決、驗證
- 與 eval loop 形成飛輪：失敗 → 寫 memory，eval 淘汰沒用的 memory

## 4. Planning loop

做之前想：拆解、排序、預測風險。和 execution / evaluation 對稱。

形態：
- One-shot plan
- Plan-Execute-Replan
- Hierarchical（高層里程碑 → 低層步驟）
- Speculative（多候選計畫）

要決策：
- 觸發條件（步數門檻？destructive 前？）
- 計畫格式（步驟、依賴、檢查點、回滾點）
- 審核流程（dry-run？人工確認？）
- 重新規劃條件
- Plan-as-memory：完成的計畫存進 memory

## 5. Execution loop（Agent loop）

模型－工具來回交替的整體迴圈引擎。承載其他 loop 運轉的底層心跳。

注意：和「Plan→Execute→Evaluate」裡那個 Execute 不同——那是單步動作，這是整個迴圈。

要決策：
- 終止條件（完成 / max steps / 偵測迴圈 / 無進展）
- 步驟/Token/時間/成本預算
- 並行 vs 序列、並行失敗處理
- 錯誤重試策略
- 中斷與恢復
- 控制權交還時機（destructive 前、模糊指令、超預算）

## 6. 權限/安全

- Destructive 操作清單 → 強制人工確認
- Dry-run 是否預設
- Prompt injection 防禦
- 哪些指令可自動跑、哪些要問

## 7. Hooks/事件

- 強制 hooks（pre-commit、post-action verify）
- 可選 hooks
- 失敗是阻擋還是警告

## 8. Evaluation loop

兩層：
- **Inner eval**：每步完成後的驗證 hook（test、type check、post-action verify）
- **Outer eval**：跨任務的 benchmark（金標準集、自動評分、版本比較）

要決策：
- 金標準幾個
- 評分方式（pass/fail / diff / LLM-as-judge）
- 失敗分類法（model 錯 / harness 錯 / 環境錯 / 規格不清）
- 失敗案例自動歸檔回 eval set

## 9. 觀測

- Trace 格式
- Token / cost 紀錄
- 失敗自動歸檔
- 跟 eval 是兄弟：eval 給分數，觀測給原因

## 10. Multi-agent / Sub-agent Orchestration

把任務拆給多個 agent 並行 / 串聯，主 agent 編排。

要決策：
- 觸發條件（context 將爆 / 並行可拆 / 隔離 cold-call / 權限分隔）
- 拆分顆粒（one-shot / long-running / pipeline）
- Context 邊界（完全隔離 / 父給摘要 / 雙向 streaming）
- 結果整合（子回主拍板 / 子直接寫檔 / vote）
- Hand-off pattern（單向 / 雙向 / DAG）
- 並行失敗（all-or-nothing / best-effort / quorum）

Claude Code 對應：`Agent` tool（subagent_type）/ `.claude/agents/` 自訂 / `run_in_background`

## 11. Triggers / Schedule

主動觸發 agent 工作（vs 設計軸 7 被動 hooks）。

要決策：
- 觸發類型（cron / 間隔 poll / 動態自我節奏 / 條件觸發 / 手動）
- 頻率上限（cache TTL 5 分鐘是天然分界）
- 失敗 / 漂移處理（過期補跑 vs skip / 重複去重）
- 停止條件（達標 / 無進展 / 超預算）
- Visibility（user 看不看得到排程）

Claude Code 對應：`/loop` / `ScheduleWakeup` / `CronCreate` / `Monitor`

## 飛輪

四個核心 loop 串成一個迴圈：

```
Memory（過往經驗）
   ↓ 餵給
Planning（這次怎麼做）
   ↓ 指導
Execution（實際做）
   ↓ 結果交給
Evaluation（做得對不對）
   ↓ 學到的東西回寫
Memory
```

少任何一環，agent 就會在某個面向反覆失敗。其他設計軸（tool、context、safety、hooks、觀測）是支援這四個運作的基礎設施。
