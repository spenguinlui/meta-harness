# 設計軸 11：Triggers / Schedule

主動觸發 agent 工作的機制 — 跟設計軸 7 Hooks（被動 reactive）相對。

- **設計軸 7 Hooks**：reactive，外部事件（user 動作 / tool 呼叫）發生時觸發
- **設計軸 11 Triggers**：active，agent 自我 schedule（時間到 / cron / loop / 條件達成）觸發

業界 2026 主流架構（如 Zylon 五層）explicitly 把 triggers 列獨立層，跟 hooks 拆開。

---

## 為什麼獨立成設計軸（不併入 Hooks）

- Hooks 精神是「**有事我攔下**」（PreToolUse / PostToolUse / UserPromptSubmit）— 沒事不出現
- Triggers 精神是「**沒事我自己跑**」（cron / loop / scheduled wake-up）— agent 主動行動
- 兩者觸發語意完全不同；混在一條設計軸會讓設計者搞不清「reactive vs active」邊界

## 設計決策

### 1. 觸發類型
- **時間觸發**：cron 每日 / 每週 / 每月 / 一次性 schedule
- **間隔觸發**：每 N 分鐘 / N 秒 poll 狀態
- **動態自我節奏**：agent 自己決定下次什麼時候醒（如 `ScheduleWakeup`）
- **條件觸發**：某狀態達成才跑（檔案出現 / 外部 API 變更 / inbox 收信）
- **手動觸發**：user 打 slash command / 按鈕（這條跟 hooks 像，但意圖是「啟動」非「攔截」）

### 2. 觸發頻率上限
- Anthropic prompt cache TTL 5 分鐘 — schedule < 5 min 維持 cache 熱
- > 5 min 會付 cache miss cost
- 「醒來」一次 = 一次 LLM call 成本，要排除「無謂重複」

### 3. 觸發失敗 / 漂移
- Schedule 過期沒跑（系統休眠 / 程序死掉）→ 補跑 vs skip？
- 重複觸發（cron 沒做去重）→ 防重機制
- Trigger fire 但 agent context 還沒準備好 → 排隊？丟棄？

### 4. 觸發停止條件
- 達到目標 → 停 loop
- N 次無進展 → 停 loop
- 成本 / token 超預算 → 停
- User 介入 → 停

### 5. 觸發 visibility
- 排程哪些 / 下次什麼時候醒 / 上次跑結果 → 在哪可看
- 失敗 trigger 是否 alert
- Schedule 改動有無 audit log

### 6. 觸發 → 派工
- Trigger fire 後，agent 自己跑？還是 fan-out 給 sub-agent？（耦合設計軸 10）
- Trigger 帶什麼 context（純時間 / 帶 last result / 帶外部事件 payload）

## 與其他設計軸耦合

- **設計軸 10 Multi-agent**：trigger fire → 常見組合是 spawn sub-agent 跑批
- **設計軸 5 Execution loop**：trigger 是 execution loop 的「啟動 source」之一
- **設計軸 7 Hooks**：trigger fire 後仍受 hooks 攔截（如 PreToolUse 還是會跑）
- **設計軸 8 Eval**：scheduled eval（每週跑 outer eval benchmark）是典型用例
- **設計軸 9 觀測**：trigger 自身要被 trace（不然「為什麼這時候跑」debug 不出來）

## Claude Code 對應機制

- **`/loop` slash command**：固定間隔 / 動態節奏跑同一 prompt 或 slash command
- **`ScheduleWakeup` tool**：dynamic mode（agent 自選下次喚醒時間）
- **`CronCreate` / `CronDelete` / `CronList`**：cron 排程遠端 agent
- **`Monitor` tool**：背景跑 + 每行 stdout 通知（非嚴格 schedule，是事件流）
- **無內建 file watcher**：條件觸發要自己用 hook 模擬

## 反模式

- **無上限 polling**：每 5 秒打外部 API 查狀態 → 浪費 + rate limit
- **Cache miss 浪費**：選 300 秒 schedule（剛過 5 min cache TTL，最差選擇 — 詳 ScheduleWakeup tool 描述）
- **Trigger 沒去重**：cron 重複跑、agent 處理一半被新 trigger 中斷
- **無停止條件的 loop**：跑到地老天荒 → token / cost 失控
- **Schedule 不可見**：user 不知道排了什麼、下次什麼時候會冒出 alert
- **Trigger 帶不夠 context**：醒來不知道為什麼醒、要查上一次結果才能繼續

具體案例見 `cases/<target>-axis-cases.md`。
