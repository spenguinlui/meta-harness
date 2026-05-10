# 支柱 4：Planning loop

做之前想：拆解、排序、預測風險。和 execution / evaluation 對稱。

## 形態

### 1. One-shot plan
任務開始產一次計畫，後續純執行。簡單但脆弱——遇到意外就崩。

### 2. Plan-Execute-Replan
執行中遇到偏差就回到 planning。Claude Code 的 Plan agent / ExitPlanMode 是這型。最常用。

### 3. Hierarchical
高層計畫（里程碑）→ 每個里程碑展開低層計畫。
- 適合複雜遷移、長任務

### 4. Speculative
產多個候選計畫，評估後選一個。
- 高成本但對高風險決策值得
- 例：架構選型、不可逆遷移

### 5. ReAct（Reason + Act 交織）
不刻意分 plan / execute，每步前 reason 一下。
- 最自由
- 對複雜任務容易迷路

## 設計決策

### 1. 觸發條件
什麼時候強制 plan？
- 步數超過 N
- destructive 操作前
- 用戶模糊指令
- eval 失敗後 replan

純查詢不必 plan，動 prod 必須 plan。

### 2. 計畫格式
最少要包含：
- 步驟列表
- 步驟間依賴
- 每步預期輸出
- 風險與回滾點
- 哪些可並行
- 檢查點（停下確認）

格式不結構化 = plan 等於聊天，沒法 review、沒法 replay。

### 3. 審核流程
- 自動執行（信任模型）
- dry-run 預覽
- 人工 ack 才執行
- 部分自動 + 關鍵步驟手動

stakes 越高 ack 越嚴。

### 4. 重新規劃條件
- Tool 失敗 N 次
- Inner eval 失敗
- 發現假設錯誤
- 用戶補資訊
- 步數超預算

每個觸發點都要設計：是 fail-fast 還是繼續嘗試？

### 5. Plan-as-memory
完成的 plan 應該變 reusable artifact：
- 存成 template
- 下次類似任務先召回
- 跟 memory 系統打通

### 6. 階層深度
hierarchical planning 要決定深幾層：
- 太淺：計畫等於 todo list
- 太深：規劃比執行還久
- 通常 2-3 層就夠

### 7. 平行性
plan 該標出哪些步驟可並行：
- 沒標 = 全序列、慢
- 亂並行 = 衝突、難 debug
- 顯式標註依賴圖

## 跟其他支柱的耦合

| 支柱 | 耦合點 |
|---|---|
| Eval | plan 該預設驗收條件，這條件變 inner eval |
| Memory | plan 召回過往類似任務的紀錄 |
| Execution loop | plan 的步驟預算 = loop 的 step budget |
| Tool | tool 副作用聲明決定 plan 嚴格度 |
| Safety | destructive 步驟在 plan 階段就要標確認點 |

## 反模式

### 1. 沒 plan 直接做
- 「我來看看」式探索
- 對小任務 OK，對複雜任務必迷路
- 觸發條件要明確

### 2. Plan 完不執行 plan
- 寫了五步，做的時候自由發揮
- Plan 變裝飾
- Execution 該對著 plan 跑、偏離要 replan

### 3. Plan 太詳細（over-planning）
- 每個 tool call 都寫進 plan
- 跟執行差不多長
- Plan 是骨架，不是劇本

### 4. Plan 太抽象
- 「先了解狀況、再做改動、最後驗證」
- 沒可執行細節
- Plan 至少該到「跑哪個 tool / 改哪個檔」級

### 5. 沒回滾點
- 五步全做完才發現第二步錯
- 已經回不去
- 每個有副作用的步驟前該想「能否回滾」

### 6. Plan 不 review 直接跑
- destructive 操作沒 dry-run / ack
- 一錯就 prod 出事
- Stakes 高必須 plan + ack

### 7. Replan 過度
- 每個小阻礙都重新規劃
- 永遠在規劃從不執行
- 設 replan 觸發門檻

### 8. Plan 跟 memory 不接
- 同樣的 migration 每次重新想
- 過往 plan 沒 reuse
- Plan template 該存進 memory

