# 設計軸 10：Multi-agent / Sub-agent Orchestration

把任務拆給多個 agent 並行 / 串聯處理，主 agent 負責編排（orchestration = 編排）。

業界趨勢：從「一個 agent 自己跑長 chat loop」轉向「多個專職 agent 經由明確 hand-off（交棒）pattern 協作的 workflow graph」（參考 Externalization in LLM Agents 2026 / multi-agent flow engineering）。2026-07 這層被圈子命名為 **graph engineering**（loop engineering 的下一層：loop 讓單一 agent 行為可程式化，graph 讓 agent 組織可程式化）——本軸的決策 5 / 9 / 10 對應這波論述的核心詞彙（validator node、diamond、org graph / work graph、控制流落點）。

---

## 為什麼獨立成設計軸（不併入 Execution loop）

- Execution loop（設計軸 5）= 單一 agent 的「模型↔工具」迴圈
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
- **DAG（有向無環圖）**：多個節點按依賴跑，不循環——適合路徑可預定的 pipeline
- **結構化循環（bounded back-edge）**：圖上允許明確標註的回邊——validator 打回 rework、retry 邊、human-in-the-loop 暫停點。生產環境的 agent graph 通常**不是** DAG。和反模式 chat loop 的差別在兩件事：(a) 回邊有 **contract**（打回時附結構化理由與修正指示，不是 free-form 對話）；(b) 有 **loop budget**（最多打回 N 次，超過就 escalate 給父或人）。缺任一件就退化成 chat loop

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

### 9. 控制流落點（routing 邏輯放 code 還是放 model）

編排這件事本身由誰決定？這是一個光譜，不是 0/1：

- **全腳本編排**：圖的拓撲寫死在 code（哪些節點、什麼順序、怎麼 fan-out/reduce），模型只填節點內容——確定性最高、可 replay、適合路徑可預定的任務
- **腳本骨架 + 模型路由**：骨架（phase 順序、並行度、失敗策略）在 code，但條件路由（這個結果走哪條邊、要不要多開一輪 finder）由模型在節點內判斷
- **模型全權編排**：主 agent 當場決定開幾個 sub-agent、派什麼任務——彈性最高，適合開放式研究，但不可 replay、每次拓撲都不同

選邊準則：**路徑可預先決定 → 往 code 端推；開放式探索 → 往 model 端推**。同一個 harness 裡兩者常共存（腳本編排的某個節點內部又是一個模型自主的 agent）。
沒做這個決策的症狀：明明是固定 pipeline 卻讓模型每次即興編排（浪費 token、結果不穩定），或明明是開放式研究卻硬寫死流程（圖變成緊身衣）。

### 10. 圖的兩層：Org Graph vs Work Graph（與執行期變形）

Graph engineering 論述把「圖」拆成兩層，各自有獨立決策：

- **Org Graph（編制圖）**：穩定、長壽的 agent 角色編制（researcher / validator / synthesizer…），跨任務存在、context 與職責定義持久化。要決策：編制存在哪（`.claude/agents/` / workflow 定義 / prescription）？角色的 memory 跨任務保不保留？誰有權改編制（builder，不是任務中的 agent）？
- **Work Graph（任務圖）**：單次任務的動態結構，隨證據到來 spawn / merge / reorder。要決策：**圖跑到一半能不能改結構**？
  - 不能改：拓撲開跑前定死，中途只能 abort 重來——簡單、可預測
  - 有限變形：預先定義的變形點（loop-until-dry 多開一輪、quorum 不足加派 verifier）——變形本身也是腳本的一部分
  - 自由變形：模型可當場增刪節點、重排依賴——最彈性，但要配 budget 上限與變形留痕（軸 9），否則圖的實際形狀事後無法重建

兩層沒分開的症狀：把任務級的臨時 fan-out 當成編制固定下來（org graph 膨脹）、或每次任務都重新發明同一套角色分工（沒有 org graph 可召回，對位軸 4 plan-as-memory）。

## 與其他設計軸耦合

- **設計軸 2 Context**：sub-agent 是 context 隔離的主要工具；context 邊界決定要不要開
- **設計軸 5 Execution loop**：每個 sub-agent 自己有 execution loop
- **設計軸 6 Safety**：destructive op 經 sub-agent dry-run 是常見模式
- **設計軸 7 Hooks**：sub-agent 完成可觸發 PostToolUse hook
- **設計軸 8 Eval**：multi-agent vote 是一種 inner eval
- **設計軸 9 觀測**：每個 sub-agent 是 trace 的一個 span
- **設計軸 11 Triggers**：`/loop` 觸發批量 sub-agent fan-out 是常見組合

## Claude Code 對應機制

- Claude Code 內建 `Agent` tool（subagent_type 參數）— 可指定 general-purpose / Explore / Plan 等專職 sub-agent — **控制流在 model 端**（決策 9 的模型全權編排）
- `Workflow` tool — 用 JS 腳本寫死編排拓撲（`pipeline()` / `parallel()` / `phase()`，模型只填節點）— **控制流在 code 端**；loop-until-dry / budget 迴圈是「有限變形」（決策 10）的實作
- 在 `.claude/agents/<name>.md` 定義自訂 sub-agent — 這就是 org graph 的持久化形式（決策 10）
- `run_in_background: true` 讓 sub-agent 背景跑、主對話不阻塞
- 並行：單一回應內多個 Agent tool calls = 自動並行

## 反模式

- **「多 agent 不解決問題只增加 latency」**：問題本來序列就能跑完，硬拆 sub-agent 反而慢（context 傳遞成本 > 並行省的時間）
- **無 hand-off contract 的 chat loop**：父子來回 free-form 對話，無明確終止 / 結果格式 — 容易死循環
- **無 budget 的回邊**：validator 打回 rework 是合法圖形（決策 5 結構化循環），但沒設打回上限 = validator 和 worker 對耗到 token 燒完 — 回邊必配 loop budget + escalation 出口
- **控制流落點錯配**：固定 pipeline 讓模型每次即興編排（不可 replay、白燒 token），或開放式研究硬寫死拓撲（圖變緊身衣）— 見決策 9 選邊準則
- **子 agent 又 spawn 子 agent 失控樹**：嵌套無上限 → token 失控
- **Sub-agent 沒被分配 read-only / mutating 邊界**：高權限子 agent 不該被父 agent 用來做低風險探索
- **共用 memory / state 卻無鎖**：N 個 sub-agent 並行寫同一 state → race condition

具體案例見 `cases/<target>-design axis-cases.md`。
