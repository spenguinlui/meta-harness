# 設計軸 1：Tool 執行

模型輸出 tool call，harness 解析並執行，回傳結果。看似最簡單，設計決策最瑣碎。

## 設計決策

### 1. 顆粒度
- **細**（Unix 哲學）：一個 tool 做一件事。模型自己組合。靈活、可組合、但模型要多 round 才能完成複雜任務。
- **粗**（composite）：一個 tool 做整個工作流。快、便宜、但失去細部控制。
- **平衡**：常用組合包成 composite，邊界 case 用細顆粒。

判準：**這個動作是否總是一起做、且失敗能整體回滾？** 是 → 包；否 → 拆。

### 2. 副作用聲明
每個 tool 該標註：
- `read-only`：純查詢
- `mutating`：改狀態、可逆
- `destructive`：改狀態、不可逆

harness 根據聲明套不同安全策略（destructive 強制確認）。

### 3. 冪等性
重跑同一個 tool 結果是否相同？
- 冪等：失敗可放心 retry
- 非冪等：retry 前要先檢查是否已執行（idempotency key）

非冪等 tool 必須明確標記，否則自動重試會出事。

### 4. 輸入 schema
- 必填 / 選填
- 型別、範圍
- 範例值（給模型參考）
- **預設值的設計**：危險操作預設保守值（dry_run=true）

### 5. 輸出 schema
- 成功時的結構
- 失敗時的結構（錯誤碼、訊息、可重試性）
- **部分成功**：批次操作裡 3/5 成功怎麼回報

輸出 schema 不穩，eval 寫不出來、cache 命中率低。

### 6. 同步 vs 背景
- 短任務同步
- 長任務背景化 + 後續查狀態
- 決策點：超過幾秒該背景化？harness 要不要主動 poll？

### 7. 失敗時 harness 的責任
- 直接把錯誤回灌給模型？
- 自動 retry N 次？
- 升級成「停下問人」？

這條跟 execution loop 耦合最深。

## 跟其他設計軸的耦合

| 設計軸 | 耦合點 |
|---|---|
| Context | tool 輸出進 context，schema 不穩 cache 失效 |
| Memory | destructive tool 該觸發 memory 寫入（決策紀錄）|
| Planning | tool 副作用聲明決定 planning 嚴格度 |
| Execution loop | 失敗策略決定迴圈如何前進 |
| Safety | destructive 標記是 safety 的依據 |
| Eval | 輸出 schema 是 inner eval 的基礎 |

## 反模式

### 1. Tool 既能 read 又能 write
- 一個 tool 同時負責「查 + 改」，副作用聲明就模糊
- 例：`update_user(id, fetch=True)` 這種 flag——拆成兩個

### 2. 字串地獄（stringly typed）
- 所有參數都是 string、輸出都是 free text
- 模型每次重新解析，eval 寫不出
- 應強制 JSON / 結構化輸出

### 3. Sentinel value 偷懶
- 用 `-1` 表示「沒有」、空字串表示「預設」
- 模型誤用機率高
- 用 `null` / 明確 enum

### 4. Tool 名稱與行為不符
- `get_user_info` 結果還會更新 last_login
- 隱藏副作用 = harness 安全策略失效

### 5. 一個 tool 做 20 件事
- 透過參數切換完全不同行為
- 模型選錯參數 = 跑錯動作
- 拆開比較安全

### 6. 沒範例值
- schema 只說「string，使用者 ID」
- 模型瞎猜格式
- 範例值是最便宜的 prompt 工程

### 7. 用 parser round-trip 編輯人寫的結構化檔
- `json.load → json.dump` 把 inline arrays 展成 multi-line，產生千行噪音 diff
- 同類：`jq` 重排 key、`yq` 改縮排
- 對人寫的 JSON/YAML 做最小修改用 line-based edit（sed/Edit），parser 不保證保留 formatting
- 出處：sessions/2026-05-03-stage1-implementation-notes.md S1-5-schema

