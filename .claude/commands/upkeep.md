---
description: meta-harness 顧問——保鮮模式：跑一輪自驗、重算清單和覆蓋率、檢查待辦有沒有放太久，給一份健康摘要
argument-hint: （不用參數；這是對 meta-harness 自己跑的）
---

你正在以 meta-harness 顧問身分進入「**保鮮**」模式。這對應設計面向 11：人不在的時候系統自己維護——隔了幾週沒人來之後，讓系統自己說出哪裡過期了。

這只是一個薄薄的入口。真正的邏輯在 `experiments/meta-harness-eval/` 那些腳本裡，這個檔案只負責入口、執行順序、和摘要格式，**不複製腳本裡的邏輯**。

**什麼時候用**：隔了一段時間沒人來（建議每週一次），要讓系統自己盤點哪裡過期、哪些清單失修、哪些待辦放太久。

1. 跑 `pwd` 確認在 `~/meta-harness`。cwd-guard hook 也會提醒。
2. **依序跑這幾步**，每一步都把關鍵輸出貼出來。遇到非零的退出碼就標記成「待處理」，不要吞掉：
   - (a) `bash experiments/meta-harness-eval/run-self-verify.sh`——整個 repo 的自驗，確認實際的機制跟設計方案還對得上。報幾支全過，或哪幾支失敗。
   - (b) `bash experiments/meta-harness-eval/derive-targets.sh --apply`——從實際證據重新推導 `targets.yml` 裡機器維護的欄位並自動更新，人工填的欄位一個字都不動。跑完再跑一次 `--check` 確認已經收斂到零差異。
   - (c) `bash experiments/meta-harness-eval/generate-coverage.sh`——重算 `coverage.json`，包含上次執行時間，順便把過期提示的計時歸零。再跑一次 `--check` 確認分母跟掃描結果一致。
   - (d) `bash experiments/meta-harness-eval/test-backlog-aging.sh`——列出 `BACKLOG.md` 裡放超過 90 天的項目。
   - (e) **選用**，這步比較貴，需要 claude CLI 和網路，所以不放進 Stop hook：`bash experiments/meta-harness-eval/run-deep-verify.sh`——讓 LLM 當評審，深入驗設計方案的內容有沒有被掏空。退出碼 2 表示環境不可用，就照實記「深驗沒跑」，不要假裝跑過。
3. **彙整成一份健康摘要**，附加一筆到 `experiments/meta-harness-eval/upkeep-log.md`。這是單一檔案滾動保存，**只保留最近 12 筆**——附加之後如果超過 12 筆，就把最舊的刪掉。這是本機執行時產生的東西，不上 git。每一筆包含日期、各項結果、以及發現的過期、失修、超期項目。
4. **把摘要貼給使用者**，附上一份「建議動作」清單：哪支驗證腳本失敗要修、哪個專案的狀態需要人工判斷、哪條待辦放太久該處理掉或收起來。摘要是給人看的，用中文功能名，不要丟沒解釋過的縮寫。

**摘要格式**（附加到 upkeep-log.md 的一筆）：

```
## <YYYY-MM-DD> 保鮮紀錄
- 自驗       : <N 支全過 / 或失敗清單>
- 專案清單   : <已收斂 / 或差異清單>
- 覆蓋率     : <百分比>（還沒覆蓋的：<清單 / 無>）
- 待辦超期   : <清單 / 無>
- 過期或待處理: <逐條列 / 無>
```

**多久跑一次**：建議每週一次。**要怎麼掛排程由使用者自己用 Claude Code 的排程機制決定，這個入口不負責排程**。這個 repo 只提供指令入口，不自己建常駐程式，這是刻意劃出來的邊界。
