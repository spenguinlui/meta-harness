# Lessons

> 跑過 meta-harness 後沉澱的教訓。和 `universal-care-rules.md`（R-1~R-9）的差別：rules 是已落地為 enforcement 的規則，這裡是「設計決策背後的洞察」——為什麼這樣設計、當初踩了什麼。

---

## Phase 0 每一問都有它的替代成本

5 個訪談問題不是儀式，各自防一種具體失敗：

- **使命沒問清楚** → 設計圖對著想像中的問題，不對著實際痛點
- **Anti-scope 跳過** → 設計圖自然擴張，實作後砍比重寫難
- **壽命沒問** → 默認永久 → 少設計淘汰機制 → 一次性工具積累 memory / eval 全套，複雜度和用途不成比例
- **Human 熟悉度沒問** → 默認 peer user → 設計軸 12 翻譯層沒蓋 → jargon 牆對著非 peer 用戶開

第一次用的人最容易跳過的是 Anti-scope。顧問若沒逼，業主會說「都可以做」，然後三個月後設計圖膨脹到沒人認識它。

---

## Wiring 比 Prompt 持久

對話 context 會被清掉，prompt 裡的建議下次 session 不復存在；hook / settings.json / skill 在每次 session 開啟時都在。

一個 harness 設計的好壞很大程度取決於：**哪些約束靠 wiring 承載、哪些只靠 prompt**。靠 prompt 的規則等於沒有規則——不是設計者偷懶，是機制本身不保證。

典型失誤：把 R-6（不用未解釋縮寫）只寫進 SKILL.md，顧問自律失效就沒有第二道防線。補救：加 `pre-askquestion-reminder.sh` hook 提醒。

---

## 設計軸不是 checklist，是參數空間

第一直覺是「12 條軸逐一填完 = 設計完成」。實際上 12 條是參數空間，大多數 target 只需要設計其中 3–6 條；剩下的是 N/A 或一句帶過。

差別在哪裡：
- **全填** → 設計圖膨脹，業主 review 30 分鐘沒結論
- **先篩選** → 設計圖只剩 existential 軸，業主 15 分鐘拍板

篩選的動力來自 Phase 0 訪談（壽命 + 失敗 floor），所以訪談先做，設計圖後出——不能顛倒。

---

## Prescription（設計圖）的價值在「實作前強迫思考」

`prescriptions/` 是 gitignored 的過程文件。它的用處不是留存，是逼顧問在動 target repo 之前寫出「為什麼這樣改、改的根據是哪條設計軸」。

寫不出 prescription 就動手 = 在沒想清楚時實作。prescription 能快速寫完，代表設計已清晰；寫得磕磕絆絆，代表 Phase 1 還沒結束。

---

## Human Interface 是最常被默認跳過的設計軸

Builder 設計 target 時的預設假設：「每天用這工具的人跟我一樣懂這個領域。」大多數時候是錯的——尤其是：
- infra 工具給會計助理跑
- ML pipeline 給業務 PM 看輸出
- 任何工具被交接給下一個人

設計軸 12 的翻譯層不是錦上添花，是基礎設施。跳過它等於命令的 description、輸出的語言、error message 都只有 builder 自己看得懂。

從 ai-infra-management v1 學到：command description 用 peer-level jargon（"4-stage architect-debate pipeline"），業主猜錯用法，命令等於對他關閉。改掉後使用率直接回來。

---

## 跨層越權是無意識的（R-8 學到的）

meta-harness README 原本有一張表：「大腦 model = Opus 4.7 / 手腳 model = Sonnet（target 用）」。第一欄（大腦）是自家陳述，對；第二欄（手腳 = target 用 Sonnet）是替另一層業主做決定，錯。

寫的人沒意識到這是越權——覺得自己只是在「建議」。問題在於：建議寫進 README 就等於預設，預設等於把另一層業主的決策空間縮小了。

修正：第二欄改成「target repo 業主在 target session 內自決，meta-harness 不表態」。

檢查方法：看到「X 對 → 所以 Y 該…」這種對立句型，先停一下——Y 是不是另一層的決策範圍？

---

## Framework 和任務內容要分開動（R-9 學到的）

看到 target `CLAUDE.md` 行數違反 R-1（超過 50 行），顧問猶豫不敢動，怕踩 R-8（跨層越權）。

這是誤讀 R-8。R-8 防的是替別人做業務決策；wiring / 檔案結構 / 規則紀律類是 framework，framework 由顧問負責動。業主在自己 target session 裡做的 ADR 原文、runbook 內容、業務邏輯才是任務內容，那才是業主自決範圍。

分辨方法：`.claude/` 內、`docs/` 規則類、schema、命令定義 = framework，顧問動；業主拍板的決策內容、進行中工作、runtime 累積資料 = 任務內容，業主動。

---

## 飛輪需要主動觸發才會跑

Plan-as-memory + Outcome-as-skill 的雙向飛輪在設計圖裡看起來很美，但如果沒有「何時回來跑 retrospective」的明確觸發條件，它就不會跑。

設計軸 8（Eval）+ 設計軸 3（Memory）要一起設計，缺任何一條另一條退化：
- 沒 eval 的 memory = 垃圾累積（無法淘汰沒用的記憶）
- 沒 memory 的 eval = 每次評估從零開始（沒有歷史輸入）

prescription template 的 memory 段和 eval 段要互引必填欄位，否則設計師容易只設計其中一條。

---

## 診斷 vs 修補

meta-harness 的設計哲學：任何失敗先找 root cause，不疊症狀修補（R-7）。

實務上最常見的「疊修補」長相：
- 失敗一次 → 加一條反模式段
- 又失敗一次 → 再加一條
- 三個月後：一份文件有 12 條反模式，全部互不連貫，且源頭問題還在

正確方法：在疊新規則之前先 grep root cause，問「刪掉源頭能解嗎？」能 → 刪源頭，不要疊蓋。
