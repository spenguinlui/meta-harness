---
description: meta-harness 顧問——維生模式：跑保鮮三件套 + backlog 齡檢，產健康摘要並自動 patch 登記簿
argument-hint: （無參數；對 meta-harness 本體跑）
---

你正在以 meta-harness 顧問身分進入「**維生**」模式（對應設計軸 11：空窗期自維——人不在場數週後，系統自己說出哪裡 stale）。

這是**薄前門**：真正的保鮮邏輯在 `experiments/meta-harness-eval/` 各腳本，本檔只負責入口、序列與摘要格式，**不複製腳本內部邏輯**。

**觸發時機**：人不在場一段時間（建議每週一次）後，要讓系統自己盤點：哪裡 stale、哪些登記簿失修、哪些 BACKLOG 超期。

1. `pwd` 確認在 `~/meta-harness`（cwd-guard hook 也會提醒）。
2. **依序跑維生序列**（每步貼關鍵輸出；遇非零退出碼標記為「待處理」，不要吞）：
   - (a) `bash experiments/meta-harness-eval/run-self-verify.sh` — 全 repo 自驗，確認機制與設計圖一致（幾支全過 / 哪幾支 fail）。
   - (b) `bash experiments/meta-harness-eval/derive-targets.sh --apply` — 由證據重推 `targets.yml` 機器欄並自動 patch（人工意圖欄一字不動）；apply 後再跑 `bash experiments/meta-harness-eval/derive-targets.sh --check` 確認收斂到零 drift。
   - (c) `bash experiments/meta-harness-eval/generate-coverage.sh` — 重算 `coverage.json`（含 `last_run.timestamp`，順帶把 staleness-nudge 的計時歸零）；再跑 `bash experiments/meta-harness-eval/generate-coverage.sh --check` 確認分母與掃描一致。
   - (d) `bash experiments/meta-harness-eval/test-backlog-aging.sh` — 取 `BACKLOG.md` 超期（> 90 天）WARN 清單。
   - (f) **可選**（較貴、需 claude CLI 與網路，不進 Stop hook）：`bash experiments/meta-harness-eval/run-deep-verify.sh` — LLM-judge 深驗 prescription 實質性（Pattern C）；exit 2 = 環境不可用，照實記「深驗未跑」不假裝。
3. **彙整健康摘要**並 append 一筆到 `experiments/meta-harness-eval/upkeep-log.md`（單檔滾動，**只保留最近 12 筆**——追加後若超過 12 筆就把最舊的刪掉；本機 runtime，不上 git）。每筆含：日期、各項結果、發現的 stale / 失修 / 超期項。
4. **把摘要貼給使用者**，附「建議動作」條列（哪個 scorer fail 要修、哪個 target 狀態需人工判斷、哪條 BACKLOG 超期該消化或收掉）。摘要給人看，用中文功能名、不丟未解釋縮寫。

**摘要格式**（append 到 upkeep-log.md 的一筆）：

```
## <YYYY-MM-DD> upkeep
- run-self-verify : <N 支全過 / 或 fail 清單>
- registry(--check): <收斂 / drift 清單>
- coverage        : <pct>%（uncovered: <清單 / 無>）
- backlog 超期    : <清單 / 無>
- stale / 待處理  : <逐條 / 無>
```

**排程**：建議**每週一次**。**排程掛載由使用者用 Claude Code 排程機制自行決定，本前門不負責排程**（repo 只提供 command 前門，不自建 daemon——守 anti-scope）。
