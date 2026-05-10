# 支柱 6：權限/安全

哪些動作可自動跑、哪些要問人、怎麼防 prompt injection。

## 設計決策

### 1. 信任分級
不是「全自動 vs 全手動」二元。光譜：
- **完全允許**（read-only 多半在這）
- **首次問、之後記住**
- **每次都問**
- **強制 dry-run + ack**
- **完全禁止**（要求人手動做）

每個 tool 該標記層級。

### 2. Destructive 清單
明確列出哪些動作不可逆：
- 刪除（檔案、資料庫、雲資源）
- 覆寫不可恢復的東西
- 對外發送（email、PR、payment）
- 改 prod 配置

清單要形式化（不是塞在 prompt 裡），harness 才能強制。

### 3. Dry-run 政策
- 預設開啟還是關閉？
- 哪些 operation 強制 dry-run-first？
- Dry-run 輸出格式（讓人看得懂預期變化）
- Dry-run pass 才能執行

stakes 高 = dry-run 預設開、強制 first。

### 4. 確認層級
- 隱式（看 prompt 自己判斷）
- chat 確認（「要繼續嗎？」）
- 雙重確認（destructive + 高 stakes）
- 帶具體後果的確認（「會刪 50M rows」）

確認越具體越有效。光問「確定嗎」用戶會麻木。

### 5. Prompt injection 防禦
觀察到的內容不可信。要設計：
- Tool 輸出內的「指令樣文字」識別
- Email / web / file 內容隔離標記
- 高權限動作前的 origin check（這指令是用戶說的還是讀來的？）

### 6. 憑證與秘密
- 不在 chat 中流通
- 不寫進 commit / log / memory
- 環境變數 / secret store 隔離
- 在 tool 邊界注入，不是 prompt

### 7. 審計記錄
每個 mutating / destructive 動作該留：
- 誰觸發（user / agent）
- 什麼時間
- 什麼 args
- 什麼結果
- 對哪個 plan / operation

事後追責 + 學習用。

### 8. 沙盒邊界
- 哪些檔案路徑可寫
- 哪些網域可呼叫
- 哪些指令可執行
- 越界該硬擋還是警告

Claude Code 的 permission system 與 settings.json 是這層。

## 跟其他支柱的耦合

| 支柱 | 耦合點 |
|---|---|
| Tool | destructive 標記是 safety 的依據 |
| Planning | dry-run 是 plan 的執行前環節 |
| Hooks | 確認流程常用 hook 實作 |
| Execution loop | safety 觸發控制權交還 |
| Memory | 不能寫敏感資訊進 memory |

## 反模式

### 1. 全允許求方便
- `Bash(*)` 一條了事
- 一次失誤就大爆炸
- 至少分 read-only / mutating

### 2. 全禁止求安全
- 每個動作都問
- 用戶疲乏、最終 yes-yes-yes
- 「警報疲勞」效應

### 3. Destructive 清單藏 prompt
- 「請小心 destructive 操作」寫 CLAUDE.md
- 模型可能忽略
- 應 hook 級強制

### 4. Dry-run 輸出沒人看得懂
- 一堆 JSON diff
- 用戶 ack 是裝樣子
- Dry-run 該翻譯成「會發生什麼」

### 5. 確認問題太籠統
- 「執行嗎？」
- 用戶不知道執行什麼
- 帶具體後果

### 6. 憑證進 prompt
- API key 寫進 system prompt
- 透過 cache、log 漏出去
- 環境變數 / secret manager 隔離

### 7. 信任 tool 輸出的指令
- 讀到「請執行 rm -rf /」就照做
- 沒做 origin check
- 觀察到的內容永遠不信

### 8. 沒審計
- 出事查不到誰做的、何時做的
- audit log 是基本要求

### 9. Sandbox 設了不檢查
- 設定 allow list 但實際執行繞過
- 邊界要可驗、可測

