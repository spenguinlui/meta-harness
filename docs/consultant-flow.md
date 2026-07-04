---
layout: page
eyebrow: 顧問決策邏輯
---

# Consultant Flow：Phase 0 → Phase 1 重排機制

> 這份文件記錄顧問腦中的決策邏輯——訪談結論怎麼轉成設計圖，哪些軸要深設計、哪些略過。SKILL.md 說「做什麼步驟」，這裡說「怎麼判斷」。

---

## Phase 0：訪談（Step 1）

5 個問題不只是收集資訊，每個答案都直接驅動後續設計決策。

| 問題 | 關鍵判斷點 | 若答案模糊 |
|---|---|---|
| **使命**（痛點 + 3 件成功事） | target 是目的還是手段？哪條設計軸是 existential | 問「今天哪件事讓你想找這個工具」 |
| **形狀**（現有抽象 + 實作介質） | 既有模組合理嗎？要保留 / 重構 / 丟掉哪些；**target 的實作介質是什麼**（bash harness / web app / SaaS / hybrid）——決定 Part D artifact 語言，不問就預設 bash | 問「哪個概念你最不確定該不該存在」；介質不明確時問「這個 target 最終跑起來是什麼樣子——CLI / 網頁 / API / 還是嵌在某個產品裡？」 |
| **邊界（anti-scope）** | 什麼不做、不做的原因 | 逼挑 3 條；「都可以做」= scope 擴張警告 |
| **失敗 floor + 預期壽命** | 哪個設計軸要補強（existential）；淘汰機制該多強 | 壽命沒問 = 默認永久 = 少設計淘汰機制 |
| **Human 領域熟悉度** | 設計軸 12 翻譯層要不要蓋、要多深 | 「都是我自己用」→ 仍需問自己哪些子領域非 peer |

訪談輸出 = `sessions/<date>-<topic>.md` 含 5 段答案草稿 + 設計軸初篩表。

---

## 重排機制：5 問 → 設計軸篩選

訪談結束後顧問做的不是「逐一填軸」，而是：

### 1. 先定 Existential 軸（必補強的）

根據「失敗 floor」判斷哪條軸若缺設計就會讓整個 target 倒：

- **不可信賴的輸出** → 設計軸 6（Safety）/ 設計軸 8（Eval）existential
- **跑一次就完事** → 設計軸 3（Memory）/ 設計軸 11（Triggers）可 N/A
- **Human 是非 peer 用戶** → 設計軸 12（Human Interface）existential
- **長時間跑、要觀測** → 設計軸 9（Observability）existential
- **多個並行任務** → 設計軸 10（Multi-agent）要決策

Existential 軸用全力設計；non-existential 軸一句帶過（"本 target 不需要"）。

### 2. 用使命過濾抽象膨脹

設計軸 13 條全套是 infra-management 等複雜 target 才用的。輕量 target（一次性腳本、數日工具）通常只需要 3–5 條。

篩選原則：**「如果這條不設計，用戶的核心痛點會不會被阻塞？」**——否 → N/A，一句帶過。

### 3. 用壽命決定設計深度

| 預期壽命 | 設計深度暗示 |
|---|---|
| 一次性 | 幾乎只要設計軸 1（Tool）+ 6（Safety） |
| 數週 | 加入設計軸 3（Memory）草案即可 |
| 數月 | 3（Memory）+ 8（Eval）都要認真設計 |
| 數年 / 永久 | 所有 existential 軸全套 + 明確淘汰機制 |

### 4. 用 Anti-scope 決定「不設計什麼」

Anti-scope 不只是功能邊界，也是設計軸邊界——明確排除的能力對應的設計軸可以直接 N/A，不需要「保留空間」設計。

---

## 重排產物：設計軸篩選表

Phase 0 結束前顧問在紀要末尾附這張表，業主 review 確認後才進 Phase 1：

```
設計軸篩選表（<target> / <date>）

Existential（全力設計）：
  - 設計軸 6 Safety：[一句理由]
  - 設計軸 12 Human Interface：[一句理由]
  ...

需設計但非 existential：
  - 設計軸 1 Tool 執行：[方向]
  - 設計軸 3 Memory：[草案]
  ...

N/A（一句帶過，不寫進 prescription）：
  - 設計軸 10 Multi-agent：本 target 單線跑，不需要
  - 設計軸 11 Triggers：手動觸發，不需要排程
  ...
```

---

## Phase 0 → Phase 1 轉場儀式

轉場必做三件事，缺一會讓業主失去 context：

1. **把訪談摘要直接貼對話**（不只給 sessions/ 檔名——業主沒打開檔不知內容）
2. **貼設計軸篩選表**，問業主：「這張篩選表有沒有需要調整？」
3. 確認無誤後明示：「我接下來進 Phase 1，獨自寫 `prescriptions/<date>-<target>.md`，X 分鐘後給你 review。」

業主沒確認就不進 Phase 1——設計軸選錯比設計圖寫慢更難修。

---

## Phase 1：建築師獨自出設計圖（Step 2）

建築師此時已知「哪些軸 existential、哪些 N/A」，設計圖只需要：

- **Existential 軸**：完整的機制說明 + 關鍵檔案骨架（檔名 / 職責 / 性能要點）
- **非 existential 但需設計的軸**：決策說明，不需骨架
- **N/A 軸**：不出現在設計圖，或一行「排除原因」

不問業主拍板題。建築師在這步是獨立工作者，不是徵詢機器。

**用軟工 pattern 語言精確化設計**（不為套 pattern 而套）：寫設計圖時若認得 wiring 對應的軟工常見 pattern（Strategy / Specification / Middleware / Facade / Repository / Bounded Context / Ubiquitous Language / Hexagonal / ATDD / SRP+DIP），**明寫**——詳對照表見 `prescription-template.md`「軟體工程紀律映射」段。有名字後設計討論的精度與 review 效率會提升；違反 SRP 的 God hook、跨 context 的 ubiquitous language drift 等也更容易在設計階段暴露，不必等自驗才現形。

LLM-specific pattern（傳統軟工方法學未直接 cover，harness domain 內另建）：4 種自驗 pattern（單一真實來源 + drift 偵測 / 觸發 + 斷言 / Scorer + METRICS / 快照 + Diff）/ prompt caching economy / agentic loop / eval-driven prompt iteration / model routing / context window 預算。觸及這些議題時設計圖明寫採用哪種，便於跨 prescription 比對與重用。

Phase 1 結束後同樣要轉場（見 SKILL.md Step 2 → Step 3 段落）。

---

## 常見失敗模式

| 失敗 | 根本原因 | 修正 |
|---|---|---|
| 設計圖 13 條全套但目標是個數日小工具 | 跳過篩選，預設全設計 | Phase 0 補篩選表 |
| 業主說「繼續」但設計方向轉了 | 沒有在轉場時讓業主確認篩選表 | 轉場強制貼篩選表 |
| Human Interface 層薄或沒設計 | 沒問第 5 題（Human 領域熟悉度） | Phase 0 補問 |
| 壽命假設錯誤導致沒有 Memory 設計 | 沒問壽命，默認一次性 | Phase 0 強制問壽命 |
| Prescription 只有文字，沒有骨架 | 顧問跳過「關鍵檔案骨架」 | Existential 軸每條附骨架 |

---

## 建議路徑（為弱模型鋪的路，可偏離）

> 本章是**操作建議**，合約在 `.claude/skills/consultant/SKILL.md`。強模型可用自己的方式達成合約（產出物 / 證據 / 閘門）；弱模型照抄本章最穩。以下內容原本住在 SKILL.md，Stage 5 鬆綁時搬來——SKILL 只留合約，做法搬到這裡，方便強模型偏離、弱模型照抄。

### 開場：先開放問，再選擇題

跑 AskUserQuestion 5 問之前，顧問先 inline 問一句開放題：

> 「請先介紹一下這個專案——它現在在做什麼、你怎麼用它？」

等業主自由回覆後，帶著這份背景去設計選擇題選項，才能讓選項貼近業主語境。若業主第一句已含足夠背景（如「我想設計一個做 X / Y / Z 的工具」），可直接進 5 問，不必重複要求介紹。

### Step 1 五問表格（進場必弄清楚的 5 件事）

顧問用 AskUserQuestion 釐清這 5 件事。每題附「為什麼問」與「答太虛時的失敗回應」：

| 問題 | 為什麼問 | 失敗回應 |
|---|---|---|
| **使命**：親身痛點是什麼？一年後做到哪三件事會說「值了」？這 repo 是目的還是手段？ | 設計圖必須對著痛點、不對著想像 | 答太虛 → 重問「**今天哪件事讓你想找這個工具**」 |
| **形狀**：現有的核心概念 / 模組 / 抽象對位嗎？哪些是 intentional 設計、哪些是被現實逼出來的？ | 顧問不能默認既有抽象正確 | 「就照現在的架構」→ 重問「**哪個概念你最不確定該不該存在**」 |
| **邊界（anti-scope）**：這 repo **不該**做什麼？（必逼，最易被忽略） | 不問 anti-scope = scope 自然擴張 = 設計圖過度膨脹 | 「都可以做」→ 警告寬 scope 反模式，逼挑 3 條 |
| **失敗 floor + 預期壽命**：什麼狀況下你會放棄這個 repo？這東西預期跑多久？（一次性 / 數週 / 數月 / 數年 / 永久）| floor 決定哪條設計軸 existential（必補強）；壽命決定淘汰機制強度 | 沒問壽命 = 默認永久 = 多數情況都會少設計淘汰機制 |
| **Human 領域熟悉度**：每天用這 target 的人（human，**未必是你 builder**）在這個領域是 peer 還是非專家？哪些子領域熟、哪些不熟？ | 決定設計軸 12（Human Interface）翻譯層該不該蓋、要多深；漏問 = 預設 human 是 peer = jargon 牆 | 「都是我自己用」→ 仍要釐清你在哪些子領域是 peer / 哪些不是（infra peer 但會計非 peer / ML peer 但 ops 非 peer） |

### AskUserQuestion 使用細則

**選擇題預設用 AskUserQuestion 工具**（不 inline markdown N 選 1）：

- **為什麼**：業主要一直複製貼上 / 自己打字 (a)/(b)/(c) 答覆很煩；AskUserQuestion 是 UI 按鈕點選 + Other 自填，效率高很多。
- **適用**：Phase 0 各層、設計軸拍板、anti-scope、SC2 失敗條件等「N 選 1 / N 選 M」場合，預設改用工具。
- **工具限制**：每題 **≤ 4 options**、**≤ 4 questions per call**。超過 4 options 就拆「主要 4 + 其餘寫在 Other」或拆兩題。
- **例外**：純開放題（「半年後你怎麼判斷變好了」這種要 user 自由回的）仍 inline；給 representative 選項 + Other 也 OK。
- **混合用**：inline markdown 描述問題本身（背景 / 推薦 / tradeoff）仍可，但**選項本身用工具**。

### Step 2 操作：篩軸與 cases 參考時機

建築師獨自出設計圖時的操作順序：

1. Read `docs/design-axes/<篩選 relevant 的幾條>.md`（**不全 read**）+ `docs/prescription-template.md`。
2. 需要先例對照時**才**查 `cases/`（業主可指定哪份；不預設 Read）——讀了哪份要照污染警示在紀要註明。
3. Read target repo 現況（檔案結構、現有 wiring）。
4. 寫 `prescriptions/<date>-<target>.md`：**文字描述 + 關鍵檔案骨架**（檔名 / 職責 / 性能要點，不寫完整內容）。

篩軸的判斷邏輯（哪些 existential、哪些 N/A）見本文件上方「重排機制」段。

### Step 4.5 操作：自驗 loop 五步驟

落地完任一可機驗 outcome，交付前跑這五步（合約只要求「gold + ≥3 次 + 機評紀錄」，這裡是最穩的做法）：

1. **寫 gold scenario**：在 `experiments/<target>-<topic>/gold.md` 寫期待輸出的關鍵特徵（關鍵字 / 結構 / 通過門檻）；prescription Part E 已有就引用，不重寫。
2. **headless 跑 ≥ 3 次**：`claude -p "<test prompt>" --output-format json --permission-mode bypassPermissions`（在 target cwd 內跑）。穩定度本身就是訊號——三次答案漂得很開 = 紀律未生效。
3. **機器評分**：關鍵字覆蓋 / structural check（`jq` 拆 JSON）/ LLM-judge；**禁止顧問肉眼瞄一次說 ok**。
4. **不通過 → 迭代**：改 prompt / wiring / persona brief / skill 說明，再跑。直到通過 **或** 顯式 commit 一條「未驗 known limitation」進 prescription。
5. **撞 API limit / 工具不可用** → 不假裝驗過。標 ⚠️ + 補跑機制（ScheduleWakeup / cron / 下次 session 開頭）。

reference 實作：`experiments/consolidation-loop/`（`run.sh` / `eval.sh` / `prompts/v*.md` / `gold.md` / `runs/*.json`）。新 target 仿這結構建 `experiments/<target>-<topic>/`。

### Step 6 操作：retro 四項檢視的具體判準

合約只定四個維度與觸發條件（SKILL Step 6），這裡是各維度的可操作門檻：

- **outcome → skill 沉澱**：builder 落地後反覆手做同類動作 **≥ 2 次**（例：advise 完手寫 ad-hoc bash 跑 baseline）→ 抽象成 `skills/<name>/<action>.sh` / sub-command / hook，不當一次性 outcome（對位設計軸 4）。
- **訊號累積看反饋**：tracking jsonl / human 評分達門檻——參考值 **累積 10 筆評分、或 < 4 分超過 3 次** → 跑 retrospective 看哪類常被拒、哪 persona prompt 該調（對位設計軸 8 outer eval + 設計軸 12 回饋通道）。
- **memory artifact 形狀檢視**：auto-memory 有沒有塞錯類型（**procedural / episodic 該往 git 移**）、debate 全文有沒有持久化、是否還落 `/tmp/`（對位設計軸 3）。
- **方法學缺口升級**：本次 target 暴露的反覆失誤——**universal 的升 `docs/design-axes/` / `docs/universal-care-rules.md`；target-specific 的留 target 自己 doc**。

### 反模式（抽象，不引具體案例）

| 反模式 | 抽象描述 |
|---|---|
| **教科書模式** | 把每設計軸當章節跟業主重新設計 target 內部資料 schema / 算法門檻 |
| **Checklist 對照員** | 把跑壞的對話固化成 SOP 形 slash command / 流程 wiring |
| **抽象問題** | 拋業主答不出 / 不熟術語的問題（違反 R-5）|
| **未解釋 jargon** | 動名詞 / 縮寫不解釋直接用（違反 R-6）|
| **Pattern lib 不查就動手** | 設計前不 Read 對應 design axis 文件，重新發明輪子 |
| **規則無分層** | 跨流程通則 / 設計流程 / 設計圖格式 / 反模式 全塞同一檔 = 等於沒分層 |
| **疊規則不刪源頭** | 看到失敗加新規則 / 反模式段，不 grep 找 root cause（違反 R-7）|
| **跨層越權** | 自家 X 生硬對比「所以對方 Y 該」二分 table，越權替別 session / 別 repo / 別業主表態（違反 R-8）|
| **Auto-memory 變終點** | 寫進 user-scope auto-memory 就放著，不 review 升 universal rule / `~/.claude/CLAUDE.md` / git docs；該當「孵化中介層」而非「永久終點」 |
| **方法學只進 docs** | 反覆失誤的紀律該升級成 hook / skill / slash command，不只加文字規則 |
