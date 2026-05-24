# Lessons

> 跑過 meta-harness 後沉澱的教訓。和 `universal-care-rules.md`（R-1~R-11）的差別：rules 是已落地為 enforcement 的規則，這裡是「設計決策背後的洞察」——為什麼這樣設計、當初踩了什麼。

---

## Prescription 預設偏向 bash / Claude Code artifact

meta-harness 的 12 設計軸本身是介質中性的——Tool 執行、Memory、Planning loop、Eval 對任何 AI agent harness 都成立，不論它是 bash script、web app、SaaS 還是 hybrid 產品（如 OpenClaw、Hermes agent 這類本體是 SaaS 的 AI harness）。

偏差不在設計軸，在 prescription Part D——安裝清單預設寫的是 `.claude/hooks/`、`bin/`、`settings.json`，顧問看到這個格式自然往 bash 套，對著一個需要 API route / DB schema / frontend component 的 target 寫出錯的 artifact。

修正方式：
- Phase 0「形狀」問題必問實作介質：「這個 target 最終跑起來是什麼樣子——CLI / 網頁 / API / 嵌在某個產品裡？」
- Prescription Header 宣告 `implementation_medium`，Part D artifact 語言跟著切換

**meta-harness 的適用邊界**：target 有 AI agent 在裡面就適用，不論實作介質。純軟體（完全沒有 AI）才超出範圍。

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

## 「驗證越牆丟給業主」是預設失敗模式（R-10 學到的）

顧問流程原本是：訪談 → 設計圖 → 落地 → **業主驗收**。實際發生：業主自己跑 3 次發現「同 prompt 三次答案完全不同」「pipeline 在某情境會 fabrication」。這些問題本來顧問交付前自己跑 ≥ 3 次就會看到。

根因不是顧問懶——是流程沒強制自驗。當「驗證」是預設交給業主時，沒有任何機制阻止顧問把未驗成品標 ✅ passing 交出。

2026-05-18 ai-infra-management /advise Stage 0 改造的自驗 loop 跑出 4 個發現：
1. eval false positive #1：「合併」字 hit 但語境是 ElastiCache 節點，非專案合併
2. eval false positive #2：「請業主選視角」被當成「真分析」短回應通過
3. Stage 0 規則 (d) 沒觸發：main agent 把「用戶取消」當業主明示停止
4. /advise 自身有 tracking replay 反模式：看到 24hr 內同類紀錄就 replay 舊結論冒充新 advise

每一個都會以「✅ passing」姿態交付給業主，由業主跑 3 次手動發現。

修正：R-10 強制 outcome 可機驗的必先自驗、Step 4.5 自驗 loop 插在落地與驗收之間、prescription Part E 加 `Verify level` 欄位 + `Self-verify runs` 欄位、`experiments/<target>-<topic>/` 結構承載。

副作用收穫：自驗 loop 本身也會踩到 R-10 自己的 edge case（撞 API limit 怎麼辦），這些 edge case 寫進規則本身 → 規則就是 dogfood 的。

---

## 診斷 vs 修補

meta-harness 的設計哲學：任何失敗先找 root cause，不疊症狀修補（R-7）。

實務上最常見的「疊修補」長相：
- 失敗一次 → 加一條反模式段
- 又失敗一次 → 再加一條
- 三個月後：一份文件有 12 條反模式，全部互不連貫，且源頭問題還在

正確方法：在疊新規則之前先 grep root cause，問「刪掉源頭能解嗎？」能 → 刪源頭，不要疊蓋。

---

## 截圖回歸的門檻別用「整頁百分比」（figma2code 學到的，設計軸 8）

pixel-diff 視覺回歸最直覺的通過線是「差異像素 / 總像素 < X%」。這個門檻對 **localized 小元件位移**（最常見的跑版）失靈：改動只佔整頁極小面積，被頁面總尺寸稀釋到門檻以下。

figma2code 實例：Pagination 按鈕間距放大 3.2 倍（gap 20px→64px），在 1440×2134 的全頁截圖只動 **130 個像素 = 0.004%**，輕鬆溜過 0.1% 門檻 → 回歸報「全綠」假通過。

關鍵洞察：**停掉所有 animation/transition 後，同頁重截的雜訊地板是 0 px**（同機同瀏覽器渲染確定性）。既然無改動 = 0px，門檻就該用**絕對像素數**（如 >10px fail），不是百分比——絕對門檻抓得到 localized 改動、又不會被整頁尺寸稀釋。

連帶教訓：
- **截圖前必停動畫**（注入 `animation/transition-duration: 0`），否則跑馬燈 / 輪播令 diff 永遠不穩，根本量不出雜訊地板。
- **百分比門檻是「跨機器容忍反鋸齒」的思維殘留**；但若 anti-scope 已排除跨瀏覽器 / CI（只本機跑），就沒有反鋸齒漂移，不需要用百分比換容忍度，反而賠掉靈敏度。

這條是 R-10 自驗的直接產物：開全新 agent 給自然語言意圖跑整套 wiring，agent 跑出「全綠」但不信、深挖才現形。**若按「丟業主驗」，業主會在改了元件、回歸報綠、誤以為安全時才踩到。**

---

## 顧問會把自己的身分洩漏進 target（R-12 學到的）

落地 / 寫 target 文件時，顧問很自然會用**自己的話**寫設計依據——「因為 R-10」「對應設計軸 5」「完整設計圖在 prescription」。但 target 是獨立專案，它的讀者沒有 meta-harness：這些變成死連結 + 看不懂的框架行話。

根因是**視角沒切換**：顧問腦中 R-N / 設計軸 / prescription 是真實存在的東西，寫的時候忘了「對 target 讀者，這些不存在」。figma2code dogfood 後業主一眼抓到 5 檔 7 處洩漏。

修正：設計依據要**翻成 target 語境的白話**（不是「因為 R-10」，是「可機驗的改動先自己跑過再交付」）；prescription / R-N / 設計軸留 meta-harness 本機；落地後 grep target 自檢。這跟 R-6（不用未解釋 jargon）同源——只是這次 jargon 是 meta-harness 自己的內部語言，最容易盲。

**第二層教訓（同日，更貴）**：立了 R-12 grep 自檢後，顧問**把它跑成「印出來看看」而非「擋 commit 的 gate」**——grep 明明命中了 docs 網站的洩漏，卻用 `||` 接著無條件 commit + push，洩漏就上了 remote，得 fix-forward 再補一個 commit。教訓：**自檢只有當成 blocking gate 才有用**（有命中 → 先清 → 再 grep 零命中 → 才 commit）。指令層面別把 check 跟 commit 用 `&&` 串成一氣——check 要先獨立跑、看結果、才決定 commit。這條已寫進 R-12 落地。
