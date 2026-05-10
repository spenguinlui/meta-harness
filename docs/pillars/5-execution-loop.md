# 支柱 5：Execution loop（Agent loop）

模型－工具來回交替的整體迴圈引擎。承載其他 loop 運轉的底層心跳。

注意：和「Plan→Execute→Evaluate」裡那個 Execute 不同——那是單步動作，這是整個迴圈。

## 設計決策

### 1. 終止條件
什麼時候停？
- 模型自己宣告完成
- 達到 max steps
- 偵測到反覆做同樣 tool call
- 連續 N 步沒實質進展（看不出變化）
- Token 超預算
- 時間超預算
- 成本超預算
- Eval 連續失敗

多重條件要排優先級。

### 2. 步驟預算
- Step budget：最多幾個 tool call
- Token budget：總 context token 上限
- Cost budget：dollar 上限
- Time budget：wall clock 上限

少一個 budget = 可能跑到天荒地老。

### 3. 並行 vs 序列
- 哪些 tool call 可並行（read-only 通常可以）
- 哪些必須序列（有依賴、有副作用）
- 並行失敗怎麼處理（其他繼續還是全停）
- 並行上限（同時最多幾個）

### 4. 錯誤處理
失敗策略光譜：
- **Retry same**：相同呼叫重試（適合 transient）
- **Retry with backoff**：等等再試
- **Reformulate**：模型自己改寫呼叫
- **Replan**：回 planning loop
- **Halt**：停下問人
- **Abort**：整個任務中止

每類錯誤該對應哪個策略要事先設計，不是當下憑感覺。

### 5. 中斷與恢復
- 用戶可不可以中途插話改方向？
- Crash / 斷線後能不能 resume？
- Background task 怎麼掛回主迴圈？
- 部分完成的狀態怎麼存？

長任務沒 resume = 一斷就重來。

### 6. 控制權交還
什麼時候主動停下問人？
- destructive 前
- 模糊指令
- 超預算
- 多個合理選項
- 高 stakes 決定

過度自動 = 失控；過度問人 = 沒用。

### 7. 進展偵測
怎麼判斷「沒進展」？
- 同樣 tool call 重複（完全相同 args）
- Tool call 不同但 context 沒變化
- 模型輸出在打轉

需要某種「狀態指紋」比對。

### 8. 非同步任務
- 短任務同步 inline
- 長任務 spawn background
- background 結果怎麼通知回主 loop
- 多個 background 平行管理

## 跟其他支柱的耦合

| 支柱 | 耦合點 |
|---|---|
| Planning | plan 的步數變 step budget |
| Eval | inner eval 失敗觸發 retry / replan |
| Memory | 任務完成後寫 memory 是 loop 終止後的事件 |
| Tool | tool 失敗策略決定 loop 行為 |
| Safety | 控制權交還是 safety hook 點 |
| 觀測 | 每步都要 log 否則出事查不到 |

## 反模式

### 1. 無 budget
- 信任模型自己會停
- 卡迴圈時跑到沒錢
- 至少要有 step + cost 雙保險

### 2. 失敗就重試到死
- 5xx 錯誤無限 retry
- 不分錯誤類型一律重試
- 該分：transient retry、permanent halt

### 3. 偵測不到迴圈
- 模型反覆做同樣 inspect
- harness 沒擋
- 至少抓「相同 tool + 相同 args 連續 N 次」

### 4. 沒中斷支援
- 用戶看出方向錯了沒法插話
- 只能 Ctrl+C 整個重來
- 主流 harness 都有中斷機制（Claude Code 用 ESC）

### 5. Background 黑洞
- spawn 出去後忘了
- 沒進度查詢、沒結果通知
- 至少要有 list / status / output

### 6. 過度自動
- destructive 也不停下
- 一錯就大錯
- safety 與 execution loop 必須協作

### 7. 過度問人
- 每個 tool call 都確認
- 用戶疲乏、自動化失效
- 信任分級

### 8. 無 resume
- 30 分鐘任務跑到 25 分鐘斷線
- 全部重來
- 至少 plan + 已完成 step 該持久化

