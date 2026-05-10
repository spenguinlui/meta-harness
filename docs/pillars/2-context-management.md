# 支柱 2：Context 管理

單 session 內 token 怎麼配。Context 是模型「當下能看到的一切」，不是無限的。

## 設計決策

### 1. 自動載入策略
什麼進系統 prompt？
- 專案規則（CLAUDE.md / AGENTS.md）
- 重要狀態檔（manifest、registry）
- 工具能力描述

判準：**每次任務都會用到、且夠穩定不爆 token**。否則改懶載。

### 2. 懶載策略
模型主動讀的部分：
- 大檔案（程式碼、log、資料）
- 罕用工具的詳細 schema
- 歷史紀錄

**Tool search / progressive disclosure** 是這層的設計——不要把 100 個 tool 全塞 system prompt，搜出相關的再給。

### 3. 壓縮策略
長對話超過上限怎麼辦：
- **截斷**：丟最舊的（粗暴但簡單）
- **摘要**：模型自己壓縮歷史（Claude Code 的 auto-compact）
- **滾動視窗**：保留最近 N + 最關鍵 M
- **分支**：開 sub-agent 隔離

### 4. Cache 策略
Anthropic prompt cache 5 分鐘 TTL。要決定：
- 哪些段落穩定到值得 cache（system prompt、規則、tool 定義）
- 哪些變動快、不該被 cache 干擾（最新狀態）
- Cache breakpoint 放哪

Cache 命中率 = 成本 + 速度的最大槓桿。

### 5. Sub-agent 隔離
複雜任務用 sub-agent 跑，主 context 只看摘要：
- 探索性任務（grep、search）外包
- 主對話保持乾淨
- 但 sub-agent 結果會比較淺，不適合需要全局判斷的工作

### 6. 順序穩定性
Cache 對順序敏感：穩定段在前、變動段在後。亂序 = cache miss。

### 7. 訊息密度
Context 不只是 token 量，還有「資訊密度」：
- 同樣 1000 token，純 log vs 結構化摘要差很多
- 給模型「對它有用」的部分，不是「全部資訊」

## 跟其他支柱的耦合

| 支柱 | 耦合點 |
|---|---|
| Tool | tool 輸出進 context，輸出大小決定 context 壓力 |
| Memory | memory 召回後塞 context，召回策略影響 context budget |
| Execution loop | step 越多 context 越長，loop 終止條件要看 token 用量 |
| Planning | plan 該定義「這個任務需要哪些 context」 |
| Eval | eval 跑時要 reset context，否則 cross-contamination |

## 反模式

### 1. 全部塞 system prompt
- 所有可能用到的東西都塞進去
- Cache 看似命中、實則每次都讀整本書
- 應改 progressive disclosure

### 2. 變動段在前
- 把「當前時間」放系統 prompt 開頭
- Cache 永遠 miss
- 變動段一律放後面

### 3. 輸出冗長 log 整段塞回
- 跑 build 100 行 log 全進 context
- 應該截尾、抓 error、摘要

### 4. Sub-agent 濫用
- 凡事都 spawn sub-agent
- 主對話失去細節判斷
- Sub-agent 適合明確邊界的子任務

### 5. 不分層
- Memory / context / tool args 全混
- 模型分不清哪些是「規則」、哪些是「現況」、哪些是「這次任務參數」
- 應分明確區塊（用 XML tag 或 markdown header）

### 6. Cache 破壞者
- 動態時間戳、隨機 ID 出現在穩定區
- 全部 cache 失效
- 動態值集中放尾段

