# 設計軸 9：觀測

Eval 給分數（做得對嗎），觀測給原因（為何這樣做、花多少、哪裡卡住）。兩者是兄弟。

## 該觀測什麼

### Trace（執行軌跡）
- 每個 tool call：何時、什麼 args、回什麼、花多久
- 每個 hook 觸發
- Plan / replan 事件
- Eval 觸發與結果

### 成本指標
- Token 用量（input / output / cached）
- Cache 命中率
- Dollar cost per task
- Cost per skill / per operation

### 性能指標
- Wall clock per task
- Tool latency 分布
- 卡哪一步最久
- 並行度實際達成

### 失敗指標
- 失敗率（按類別：tool fail / eval fail / user abort）
- 哪個 tool 最常 fail
- 哪類任務最常需要 replan
- 用戶中斷比例

### 行為指標
- 平均 step 數
- 重複呼叫比例（迴圈跡象）
- Plan 採用率（plan 完真的照做嗎）
- Memory 寫入頻率與召回率

## 設計決策

### 1. 粒度
- 太細：log 爆炸、處理慢
- 太粗：出事查不到
- 通常：tool call 級必記、模型 token 級可選

### 2. 取樣
全量 vs 抽樣：
- Production 級流量大要抽樣
- Domain harness 通常規模小，可全量
- 失敗 case 一律全留

### 3. 儲存
- Local file：簡單但難跨 session 分析
- 結構化（JSONL）：可 query
- Trace platform（Langfuse、Helicone）：可視化、比較
- DB：自管

### 4. 隱私
- Trace 包含對話內容、tool args
- 可能含密碼、PII
- 該過濾再儲存

### 5. 即時 vs 事後
- 即時 dashboard：開發中看
- 事後分析：跑完 batch 後 review
- 兩者需求不同，工具不同

### 6. 跟 eval / memory 的接口
- 失敗 trace 自動進 eval set 候選
- 高頻成功 pattern 自動進 memory
- 沒接口 = trace 變垃圾

### 7. 觀測自身的成本
- Log 寫入有開銷
- 同步 log 拖慢執行
- 重的觀測該背景化

### 8. 可比性
- 不同版本 harness 的 trace 要可比
- Schema 穩定、欄位一致
- 否則「v2 比 v1 好」說不清

## 跟其他設計軸的耦合

| 設計軸 | 耦合點 |
|---|---|
| Eval | 觀測供原因，eval 供分數，必須一起看 |
| Memory | 失敗 trace → memory；trace 統計驗 memory 有效性 |
| Hooks | 觀測常用 hook 實作（pre/post-tool log）|
| Execution loop | budget 監控靠觀測 |
| Tool | tool 該標 cost / latency 屬性 |
| Safety | audit log 是 safety 與觀測重疊處 |

## 反模式

### 1. 只 log 不分析
- log 量很大但沒人看
- 出事還是查不到
- 至少要有 query / 摘要

### 2. 沒 cost trace
- 跑了一個月才發現帳單爆
- 至少 token + dollar 級
- 分到 task / user / skill 級更好

### 3. 失敗沒分類
- 「failed」一坨
- 不分 tool fail / eval fail / user abort
- 改進無從下手

### 4. Trace schema 不穩
- 每版加欄位、改型別
- 跨版本比較失效
- 加欄位 OK，改既有欄位要 migrate

### 5. 觀測拖慢執行
- 每步 sync 寫 trace 到遠端
- 用戶體驗崩
- 背景化

### 6. 隱私洩漏
- API key 進 trace、進 log 平台
- 過濾該在寫入端做，不是事後刪

### 7. 觀測沒接 eval / memory
- trace 自成孤島
- 失敗 case 沒回流 eval set
- 成功 pattern 沒進 memory

### 8. 沒 baseline
- 「這次 30 秒」是快是慢？
- 沒歷史數據對比
- 至少 P50 / P95 留著

### 9. Dashboard 沒人看
- 建得很漂亮，沒進 ops 流程
- 該定期 review、該觸發告警

### 10. 主入口 `exec` 與 observability 互斥
- harness 入口若以 `exec "$action_script" "$@"` 收尾（process tree 乾淨、exit code 自動傳遞），所有 post-hook（audit / metrics / anomaly detection）**不可能跑**——`exec` 已替換進程
- 要支援 observability 必須改 `fork + wait + 回填 exit code`
- 這是 trustworthiness 的隱性 process-model 成本，規劃 audit/觀測時要明示這條取捨
- 出處：sessions/2026-05-03-stage1-implementation-notes.md S1-3

