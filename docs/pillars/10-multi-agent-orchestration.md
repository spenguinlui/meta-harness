# 支柱 10：Multi-agent / Sub-agent Orchestration

把任務拆給多個 agent 並行 / 串聯處理，主 agent 負責編排（orchestration = 編排）。

業界趨勢：從「一個 agent 自己跑長 chat loop」轉向「多個專職 agent 經由明確 hand-off（交棒）pattern 協作的 workflow graph」（參考 Externalization in LLM Agents 2026 / multi-agent flow engineering）。

---

## 為什麼獨立成支柱（不併入 Execution loop）

- Execution loop（支柱 5）= 單一 agent 的「模型↔工具」迴圈
- Multi-agent orchestration = 多個 agent 之間的 hand-off / context 邊界 / 結果整合
- 兩者的決策軸完全不同（並行失敗策略、context 隔離程度、子 agent 拆分顆粒）
- 業界 2026 後普遍把 multi-agent 視為獨立架構層

## 設計決策

### 1. 觸發條件（什麼時候開 sub-agent）
- **Context 將爆**：主對話 token 用量逼近上限 → 把 read-heavy 工作派給 sub-agent
- **任務並行可拆**：N 個獨立子任務（如「同時審 3 個專案」）→ fan-out
- **高風險隔離**：destructive op 預演 → sub-agent 跑 dry-run，主 agent 看結果決定
- **Cold-call 不污染主對話**：探索性 LLM 詢問（如「列出所有可能的 hypothesis」）放 sub-agent，避免噪音灌進主 context
- **權限分隔**：高權限子任務（碰 prod）vs 低權限主對話

### 2. 拆分顆粒
- **One-shot sub-agent**：派一個任務、回一份結果、結束（最常見）
- **Long-running worker**：跨多次 iteration、保留自己的 context（堡壘式）
- **Pipeline stage**：上游 agent 輸出 → 下游 agent 輸入（DAG 形態）

### 3. Context 邊界
- **完全隔離**：sub-agent 從零讀 brief，不看主對話 — 最乾淨、最浪費 token
- **父給子摘要**：主 agent 寫一段 brief 傳給子 — 中間路線
- **雙向 streaming**：子 agent 進度即時回主 — 彈性高、context 易爆

### 4. 結果整合
- **子回主 + 主決策**：sub-agent 報告，主 agent 整合 / 拍板
- **子直接寫檔**：sub-agent 改實際檔案，主 agent 只看 git diff
- **Vote / merge**：N 個 sub-agent 投票 / 共識
- **Chain-of-thought 合併**：把多個 sub-agent 的推理串成一份輸出

### 5. Hand-off pattern
- **父→子單向**：派任務、子完成、結束（最常見）
- **子→父單向**：子發現問題 → 中斷給父決定
- **雙向**：子父反覆對話（容易變成 unstructured chat loop，反模式）
- **DAG（有向無環圖）**：多個節點按依賴跑，不可循環

### 6. 失敗處理
- **子失敗 = 任務失敗**：fail-fast，主 agent 立刻 abort
- **子失敗 = 主重派**：主 agent 試另一個 sub-agent / 換 prompt
- **子部分成功 merge**：N 個 sub-agent 中 M 個成功也 OK，merge 成功部分
- **子失敗 = 寫 BACKLOG**：當下不解，存案 review

### 7. 並行失敗（fan-out 場景）
- **All-or-nothing**：N 個並行 sub-agent，任 1 失敗整批 abort
- **Best-effort**：失敗的 skip、成功的 merge
- **Quorum**：M / N 成功就算總成功

### 8. 觀察 / 留痕
- 每個 sub-agent 的 input / output / cost / duration 該寫進哪？
- 失敗 sub-agent 的 trace 該保留多久？

## 與其他支柱耦合

- **支柱 2 Context**：sub-agent 是 context 隔離的主要工具；context 邊界決定要不要開
- **支柱 5 Execution loop**：每個 sub-agent 自己有 execution loop
- **支柱 6 Safety**：destructive op 經 sub-agent dry-run 是常見模式
- **支柱 7 Hooks**：sub-agent 完成可觸發 PostToolUse hook
- **支柱 8 Eval**：multi-agent vote 是一種 inner eval
- **支柱 9 觀測**：每個 sub-agent 是 trace 的一個 span
- **支柱 11 Triggers**：`/loop` 觸發批量 sub-agent fan-out 是常見組合

## Claude Code 對應機制

- Claude Code 內建 `Agent` tool（subagent_type 參數）— 可指定 general-purpose / Explore / Plan 等專職 sub-agent
- 在 `.claude/agents/<name>.md` 定義自訂 sub-agent
- `run_in_background: true` 讓 sub-agent 背景跑、主對話不阻塞
- 並行：單一回應內多個 Agent tool calls = 自動並行

## 反模式

- **「多 agent 不解決問題只增加 latency」**：問題本來序列就能跑完，硬拆 sub-agent 反而慢（context 傳遞成本 > 並行省的時間）
- **無 hand-off contract 的 chat loop**：父子來回 free-form 對話，無明確終止 / 結果格式 — 容易死循環
- **子 agent 又 spawn 子 agent 失控樹**：嵌套無上限 → token 失控
- **Sub-agent 沒被分配 read-only / mutating 邊界**：高權限子 agent 不該被父 agent 用來做低風險探索
- **共用 memory / state 卻無鎖**：N 個 sub-agent 並行寫同一 state → race condition

具體案例見 `cases/<target>-pillar-cases.md`。
