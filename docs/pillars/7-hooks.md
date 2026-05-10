# 支柱 7：Hooks/事件

在 tool call 前後、session 邊界、特定事件注入自訂行為。Hooks 是「harness 自律」與「平台強制」的差異點。

## Hook 類型（按時機）

### Tool 邊界
- `pre-tool`：tool 執行前。可阻擋、可改 args、可注入 context
- `post-tool`：tool 執行後。可驗證、可記錄、可回灌訊息

### Session 邊界
- `session-start`：載入專案規則、提醒事項
- `session-end`：清理、寫摘要進 memory
- `compact`：context 壓縮時

### User 互動
- `user-prompt-submit`：用戶輸入後、模型處理前
- `notification`：系統通知用戶時

### 文件 / Git
- `pre-commit`：commit 前 lint
- `pre-write`：寫檔前驗證

每家 harness 提供的 hook 點不同，Claude Code 有完整一套。

## 設計決策

### 1. 強制 vs 建議
- **強制**：失敗就阻擋（tool 無法執行）
- **建議**：失敗只警告，繼續執行
- 安全相關用強制；風格/品質用建議

### 2. 失敗處理
hook 自己失敗（script 寫錯、超時）怎麼辦？
- Fail-open：當作 hook 沒跑，繼續
- Fail-closed：擋住整個流程
- 高 stakes 用 fail-closed

### 3. 性能預算
hook 每次都跑，要快：
- 同步 hook 不該超過幾百 ms
- 慢的部分 fire-and-forget 背景化
- 否則用戶體驗崩

### 4. 副作用可見性
- Hook 改了什麼要讓人 / 模型知道
- 默默改 args 會 debug 困難
- 有變更該 log 出來

### 5. 順序與組合
多個 hook 同個事件，順序怎麼定？
- 顯式排序
- 任一失敗就中止？還是全跑完？
- 衝突解決規則

### 6. 配置層級
- 全域（user-level）
- 專案（repo-level）
- 個人 override
- 哪一層贏

### 7. 可觀測性
- Hook 是否被觸發
- Hook 跑了多久
- Hook 是否阻擋了什麼
- 沒觀測的 hook 會默默壞掉

## 對映其他支柱的實作

Hook 是其他支柱的**實作機制**：

| 該支柱要做的事 | 用 hook 怎麼實作 |
|---|---|
| Safety：destructive 強制 ack | pre-tool hook 攔截、要求 chat 確認 |
| Eval inner：post-action verify | post-tool hook 跑驗證腳本 |
| Memory：自動寫 ADR | post-operation hook 觸發寫入 |
| 觀測：trace 紀錄 | pre/post-tool hook 寫 log |
| Context：載入規則 | session-start hook 注入 |

沒 hook 機制，這些事只能靠 prompt 引導（弱保證）。有 hook = 平台強制（強保證）。

## 反模式

### 1. 全部用 prompt 不用 hook
- 「請每次 commit 前 lint」寫在 CLAUDE.md
- 模型偶爾跳過
- 該強制的就 hook，別當建議

### 2. Hook 寫太多
- 每個 tool 都掛 5 個 hook
- 累積延遲爆炸
- 只在關鍵點掛

### 3. 慢 hook 同步跑
- pre-tool 跑 30 秒 lint
- 用戶以為 harness 卡死
- 慢動作背景化

### 4. Fail-open 安全 hook
- 安全檢查 hook 自己壞了 = 通過
- 等於沒檢查
- 安全相關 fail-closed

### 5. Hook 改了 args 不 log
- 模型以為自己呼叫了 X，實際被改成 Y
- 行為跟認知分離
- debug 噩夢

### 6. Hook 不可觀測
- 沒人知道有沒有跑
- 沒人知道為何被擋
- 至少要 log

### 7. 業務邏輯塞 hook
- 把核心功能寫 hook
- hook 失敗 = 功能消失
- hook 是邊界、不是主體

### 8. 個人偏好寫專案 hook
- 強迫團隊接受個人風格
- 該寫 user-level 別寫 repo-level

