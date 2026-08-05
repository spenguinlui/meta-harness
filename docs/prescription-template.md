# 設計方案的格式

這是顧問針對某個目標專案輸出的文件格式。

先講清楚它是什麼：設計方案是一份「請在你的專案裡裝這些東西」的清單，不是「我幫你做完了」的報告。

每一份方案都是某個時間點的快照。隨著目標專案演化、通用規則演化、教訓累積，會出 v1.5、v2 等等新版本。

---

## Header

```yaml
target_repo: <名稱 + 網址>
generated_at: <ISO 時間戳>
status: draft | active | superseded
template: full | lite    # 分級用；沒寫就當 full。判斷標準見下方「輕量版」那節
implementation_medium: claude-code-harness | web-app | api-service | saas | hybrid | other
  # claude-code-harness：主要產出是 hook、skill、settings.json、bash 腳本
  # web-app / api-service / saas：主要產出是路由、資料庫結構、元件、基礎設施設定
  # hybrid：AI harness 嵌在網頁或 SaaS 產品裡，像 OpenClaw、Hermes agent 那類
  # 這個值會決定 Part D 用什麼語言寫，不要預設是 bash 或 Claude Code
source_sessions:
  - <訪談那次 session 的連結>
  - <設計面向盤點那次 session 的連結>
  - <其他相關 session>
universal_care_rules_baseline: <universal-care-rules.md 的 commit hash>
prescription_version: <v1, v1.5, v2 ...>
```

---

## Part A：需求摘要

從訪談那次 session 抽出來的關鍵結論。後面所有內容都要能追溯回這裡。

- **要解決什麼問題**：一兩句話講完。
- **誰會用、怎麼互動**：一定要分清楚設計者和使用者。設計者是設計這個專案的工程師，使用者是每天跑指令看結果的人。可能是同一個人，也可能不是。
- **使用者懂不懂這個領域**：他在這個領域是內行還是外行？哪些子領域熟、哪些不熟？這決定人的介面（面向 12）那層翻譯要做多深。
- **成功的標準**：尤其是第二條，什麼情況算失敗。這決定哪個設計面向是非做不可的。
- **這個領域的形狀**：例如很多互相獨立的專案、有先後順序的流程、還是一條轉換的流水線。
- **不該做什麼**：明確列出來。

---

## Part B：12 條基本規則的對照表

逐條對照 [universal-care-rules.md](universal-care-rules.md)，看目前的狀態：

| 規則 | 狀態 | 備註 |
|---|---|---|
| R-1 CLAUDE.md 不超過 50 行 | ✅ / ⚠️ / ❌ / N/A | 是 ⚠️ 就列出缺什麼 |
| R-2 設定放進版控 | ... | ... |
| R-3 hook 不超過 100 行 | ... | ... |
| R-4 不編造 | ... | ... |
| R-5 提問要指向具體的東西 | ... | ... |
| R-6 不用沒解釋過的術語和縮寫 | ... | ... |
| R-7 不固化壞流程，先找根本原因 | ... | ... |
| R-8 不跨層越權 | ... | ... |
| R-9 框架和任務內容分開 | ... | ... |
| R-10 交付前先自己驗過 | ... | ... |
| R-11 給別人用的要附說明書 | ... | 走 `/document`；不會交接的自用腳本填 N/A |
| R-12 寫進專案的檔案要能獨立看懂 | ... | 實作完 grep 一次，確認沒有框架行話 |

狀態的意思：✅ 是符合；⚠️ 是部分符合，要列出具體差在哪；❌ 是還沒做，會進 Part D 的安裝清單；N/A 是不適用，要附理由，例如這個 repo 沒有對應的概念。

---

## Part C：13 個設計面向的對應，加上這個領域自己的新概念

對 [13 個設計面向](design-axes/) 逐條產出針對這個專案的內容。

**每一條都必須包含五個欄位。** 少了「做法」這一欄，就會走進一個典型的錯誤：有圖書館但沒人翻，有筆記本但沒人寫。只寫了格式（靜態設定）卻沒寫「什麼時候讀、什麼時候寫、東西的生命週期、怎麼驗證」，AI 就會自由發揮，可能完全不主動寫，或者被 Claude Code 內建的記憶功能取代掉。

```
### 設計面向 N：<名稱>

**該長什麼樣**：這個專案在這條面向上該長什麼樣，依據是 Part A
**目前狀態**：已裝好 | 部分 | 還沒裝 | 已淘汰
**追溯**：對應訪談裡的哪一條需求、哪個使用者、哪條成功標準

**靜態設定（要裝什麼）**：指向 Part D 裡的具體檔案或結構

**做法（行為上的約定）**：
  - **什麼時候寫入**：列出具體的觸發條件，可能是事件、指令、hook，或使用者的意圖
  - **什麼時候讀取**：Claude 什麼時候該去查這份資料？session 開始就自動載入、用到才 grep、還是條件觸發？
  - **生命週期**：一個條目怎麼從建立、到生效、到被取代或封存？誰負責推動這些轉換？
  - **怎麼驗證**：對應 Part E 的哪一條測試，確認這個做法真的有在運作

**哪些可以自由發揮**：標明哪些是必須做到的行為，哪些是實作自由，bash、python、應用層都行。
```

### 為什麼「做法」這一欄不能少

只寫格式不寫做法，就是有圖書館但沒人翻、有筆記本但沒人寫。

AI 會在當下自己決定什麼時候讀寫，缺乏一致性。半年後新人或新 session 接手時，沒有共同的預期。

拿記憶層舉例。

只說「建一個 decisions/ 目錄，用這個格式寫決策紀錄」，結果 AI 可能完全不主動寫，或者用 Claude Code 內建的記憶取代，繞過你的設計。

加上做法就不一樣了：「做完有破壞性的操作之後，hook 提示寫決策紀錄；session 開始時注入 decisions/INDEX.md；架構類的 commit message 觸發寫紀錄的提示；紀錄互相衝突時，commit 前的 hook 偵測出誰取代了誰。」這樣行為就可預期、可驗證。

### 用不到的面向怎麼處理

某條面向對這個領域真的不需要時，五個欄位還是要填，「做法」那欄寫 `N/A — 理由`。

不允許整段省略。這是為了強迫 review 的人看見「有意識地決定不做」，而不是「忘了想」。

### 這個領域自己的新概念

專案負責人自己的核心概念，例如 Watcher、Recommendation、Pipeline、Workspace 這類，一併列在 Part C，格式跟上面一樣。

### 有幾個面向一定要回答的問題

有些面向不問就會踩到典型的錯誤，所以這裡強制要求方案裡必須回答。

**成效評估（面向 8）必答：** 做完任務的結果，能不能回連到當初的計畫和決策？怎麼連？

沒連的話，整個循環就斷了一截，系統只能靠人主觀回報，沒辦法客觀學習。常見的做法有：在 commit message 裡引用、幫雲端資源打標籤、交易紀錄、稽核軌跡編號、多重綁定。

答 N/A 一定要附理由，例如「這是純唯讀的專案，沒有會改動狀態的結果」。

**記憶（面向 3）必答：** 自動寫入個人記憶的紀律是什麼？什麼時候該把它升級進 git，變成通用規則、專案的 CLAUDE.md、或 docs/？

沒有紀律的話，Claude Code 預設就是「什麼都往那裡塞」。結果個人記憶變成垃圾場、規則永遠不升級進 git、團隊接手時斷層。

答 N/A 一定要附理由，例如「這是一個人的專案，沒有接手的考量」。

**人的介面（面向 12）必答：** 使用者是這個領域的內行嗎？如果是外行，翻譯層怎麼做？意見回流的管道怎麼設計？設計者還在嗎？

使用者是外行卻沒做翻譯層，就是架起一面術語牆，等於沒有輸出。沒有意見回流管道，訊號就流失了，系統沒辦法迭代。設計者已經不在的話，那是結構問題，做法救不了。

### 對應到軟體工程的既有做法

設定的設計可以、也應該用軟體工程的語言來精確描述。常見的對應：

| 概念 | 在 harness 裡的對應 | 出處 |
|---|---|---|
| Strategy | 引擎可抽換（agent-engines.yml 加上分派；claude 和 codex 是同一個介面的兩種實作） | Design Patterns |
| Specification | 把規則變成資料（例如 atdd-task 的 `tool-safety.yml` 裡那份破壞性操作清單） | 領域驅動設計 |
| Middleware / Chain of Responsibility | hook 串成一串（工具執行前 → 工具 → 工具執行後 → 子 agent 結束） | Design Patterns |
| Facade | 指令（`/continue` 把底下一整條流程包成單一入口） | Design Patterns |
| Repository | MCP（`atdd_task_*` 把任務的持久化封起來，跟客戶端解耦） | 領域驅動設計 |
| Bounded Context | agent 的職責邊界（風險審查那個不做規格缺口，那是把關者的事） | 領域驅動設計 |
| Ubiquitous Language | 「信心度」「e2eDecision」「reviewFindings」這類領域詞彙，必須跨方案、skill、agent 都一致 | 領域驅動設計 |
| Hexagonal / Ports and Adapters | `ports/` 的目錄結構（atdd-task 的 `ports/mcp`、`ports/api`、`ports/worker`） | Clean Architecture |
| ATDD（先寫驗收測試） | 本格式的 Part E 必須先寫，Part D 的設定後做，`run-self-verify` 全過才算完成 | XP / ATDD |
| 單一職責、依賴反轉 | 一個 hook 只擋一件事；agent 的 prompt 不該依賴具體的引擎，那要抽到分派層 | SOLID |

**為什麼要明寫。** 違反單一職責的肥大 hook、洩漏實作細節的 prompt、跨情境的共通語言逐漸走鐘，這些問題在自我驗證和 hook 的接口層會自然暴露。但有名字之後，設計討論的精度和 review 的效率都會提升。這不是為了套名詞而套。

**LLM 領域特有的做法**（傳統方法沒有直接涵蓋，要在 harness 這個領域另外建立的）：

- 四種自我驗證的驗法（比對設定是否一致、觸發後看有沒有反應、跑分評輸出品質、比對前後差異）。這是傳統單元測試做法的 LLM 版演化。
- prompt 快取的成本考量、agent 迴圈、用評估結果驅動 prompt 迭代、model 路由、上下文視窗預算。

設計 Part D 的時候，如果碰到這些議題（例如分派、成本正確的量測），要明確標示採用哪一種做法，方便跨方案比對和重用。

---

## Part D：實作清單

具體可執行的實作清單，按類別分組。

**寫法要跟著 Header 的 `implementation_medium` 切換**，不要預設是 bash 或 Claude Code 的結構。

### D.0 先宣告實作介質

在這裡明確講清楚這份方案的產出是什麼類型，讓讀 D.1 到 D.5 的人知道要用什麼語言去看：

```
implementation_medium: <同 Header>
tech_stack: <主要語言、框架、平台。例如 Next.js + PostgreSQL、FastAPI + Redis、bash + Claude Code>
artifact_language:
  - claude-code-harness  → D.1 是 CLAUDE.md 和 docs；D.2 是 hooks；D.3 是 bin/ 和 skills；D.4 是 settings.json
  - web-app / api-service → D.1 是路由、元件、資料庫結構；D.2 是 middleware 和 webhook；D.3 是 service 和 module；D.4 是環境變數和設定
  - saas / hybrid        → 上面兩種混合，每一項都要標明在哪一層（harness 層還是應用層）
```

### D.1 核心檔案和結構

- **claude-code-harness**：CLAUDE.md 的段落、文件結構、docs/ 底下的規則類文件。
- **web-app / api-service**：路由定義、資料庫結構、元件骨架。
- **saas / hybrid**：依所在的層分開列，harness 層和應用層要標清楚。

### D.2 事件攔截

- **claude-code-harness**：`.claude/hooks/` 底下的腳本，加上 `.claude/settings.json` 的註冊。

  **每個 hook 都必須寫清楚三件事，防止匹配條件太寬造成誤觸發：**

  ```
  - Hook ID: <名稱>
  - 觸發事件: PreToolUse | PostToolUse | UserPromptSubmit | SessionStart | Stop ...
  - 匹配哪個工具: <Bash | Edit | Write | * 等>
  - 匹配精準度（三項都要填）:
    1. 指令前綴的錨點:
       <指令必須含目標專案自己的 CLI 前綴。不允許拿高頻的普通字當觸發條件，
        像是 'inventory'、'force' 這種>
    2. 排除清單:
       <已知該排除的路徑、指令、情境>
    3. 誤觸發的檢查清單:
       - <5 個「不該觸發」的指令或訊息範例>
       - <3 個「該觸發」的指令或訊息範例>
  - 邏輯: <腳本要做什麼>
  - 對應的驗收測試: V<n>
  ```

  **常見的錯誤做法：** 匹配條件只用裸字串或全域 regex；沒有排除清單；裝上去之後才發現誤擋。

- **web-app / api-service**：middleware、webhook handler、事件監聽。
- **saas / hybrid**：標明是 harness 層的 hook 還是應用層的 middleware。

### D.3 指令和服務模組

- **claude-code-harness**：新的 `bin/` 子指令、新的 skill 目錄。
- **web-app / api-service**：新的 service、API module、worker。
- **saas / hybrid**：標明在哪一層。

### D.4 設定和環境

- **claude-code-harness**：權限、環境變數、`.claude/settings.json` 的條目。
- **web-app / api-service**：`.env`、功能開關、基礎設施設定、CI/CD 設定。

### D.5 目錄結構

新增的頂層目錄。記得放一個進版控的空檔，確保結構真的存在。

每一項的格式：

```
- 狀態: ✅ 已安裝 (commit hash) / 📋 待安裝 / ❌ 已淘汰 (理由)
- 規格: <細節要夠清楚，讓執行的人不必再回來問>
- Runtime verified: <ISO 時間戳> via <驗證方式>   ← 標「已安裝」時必填
- 對應的驗收測試: <Part E 的哪一條確認它生效>
```

**關於「Runtime verified」這個欄位。**

任何規格裡含有通訊協定、資料格式、API 約定範例的東西——hook 的輸出格式、JSON 結構、允許或拒絕的包裝格式、標準輸出和錯誤輸出的約定——標「已安裝」之前，一定要經過實際執行的測試。光看程式碼是看不出來格式跟當前 Claude Code 的規格對不對得上的。

這個欄位三選一，不可省略：

- `<ISO 時間戳> via <Part E 的 V<n>>`，走 Part E 對應的實測。
- `<ISO 時間戳> via <臨時測試的描述>`，例如「手動觸發一個 Bash 指令，觀察 hook 行為，錯誤輸出出現了拒絕的理由」。
- `🚧 尚未實際驗證`。這種情況下狀態不可以標「已安裝」，要留在「待安裝」，或新增一個「程式碼裝好了但沒實際驗過」的中間狀態。

**「標準輸出是合法的 JSON、exit 0、看起來對」不算驗證過。** Claude Code 對於格式不符是靜默忽略的：hook 邏輯對、輸出是合法 JSON、exit 0，但如果格式用的是舊版的扁平結構（例如 `{"permissionDecision":"deny"}` 而不是巢狀的 `{"hookSpecificOutput": {"hookEventName":"PreToolUse", ...}}`），Claude Code 不會擋、也不會報錯，從外面看完全像是有在運作。

查證的時候，第三方權威來源（例如 `claude-code-guide` agent、官方文件的版本）優於「讓 LLM 憑印象生一個格式出來」。

---

## Part E：驗收測試

在目標專案裡開一個 Claude session，跑這些指令或表達這些意圖，看行為是不是符合預期。

每一條測試：

```
### V<n>: <測試名稱>
- **意圖或指令**：使用者輸入什麼
- **預期行為**：Claude 該做什麼
- **怎樣算失敗**：什麼情況算不對
- **Verify level**: script | trace-observation | human-only   ← 必填，決定由誰來跑
- **Status**: ✅ passing / ❌ failing / 🚧 not testable yet
- **Live-fired at**: <ISO 時間戳>   ← 標 ✅ passing 時必填
- **Self-verify runs**: N/A | <次數>×pass / <次數>×total   ← Verify level 是 script 時必填
- **追溯**：對應 Part D 的哪些安裝項目
```

**驗證層級分三類。**

- **script**：可以用 `claude -p` 非互動模式、bash 腳本、或 `jq` 做結構檢查，讓機器驗。顧問必須自己跑，跑至少三次穩定通過才能標 ✅ passing。用 `experiments/<目標專案>-<主題>/` 這個結構承載。
- **trace-observation**：要在目標專案的 session 裡觸發之後，觀察追蹤紀錄、log、或 hook 有沒有被叫起來，才能判定。顧問可以代跑，例如自己開一個 session 試，但主觀的體感判定可能還是要對方來。
- **human-only**：需要對方主觀判定品質、風格、有沒有切中痛點。顧問不該自己結案。例如「Claude 給的建議讀起來像不像一個資深架構師」。

**關於實彈測試。**

任何 V 條目對應的 Part D 項目如果含有通訊協定、資料格式、API 約定的範例（hook 輸出、JSON 包裝等），狀態要標 ✅ passing 就必須有實彈證據：在目標專案裡真的觸發那個情境，觀察行為符合預期。

`Live-fired at` 三選一：

- `<ISO 時間戳>`：已經實際跑過，狀態可以標 ✅ passing。
- `🚧 not testable yet — <理由>`：例如「要等真的出現破壞性操作才能驗」。這種情況狀態必須是 🚧 not testable yet。
- 不允許狀態是 ✅ 但 `Live-fired at` 空白。看起來是 ✅、實際上從來沒被觸發過，這是設計方案層級最常見的假象。

實彈測試不等於空跑或單元測試。必須用真實的使用者意圖或指令，進到 Claude Code session 裡去觸發。

**自驗這一關。** Verify level 是 script 的條目，方案交付前顧問必須跑完整的自驗流程。`Self-verify runs` 欄位記錄通過次數和總次數。如果這欄空白、Verify level 是 script、狀態卻是 ✅，一律視為假象，跟 `Live-fired at` 空白一樣。

**什麼叫通過。** 方案真的落實到行為層了。這是要避開兩種假象：文件講了但沒實作，以及格式不符被靜默忽略。

**什麼叫失敗。** 安裝不完整，或規則沒有被遵守。要修。

### 自我驗證的基礎建設

這是目標專案層級的硬規定，跟 R-10 是一組的。

Verify level 是 script 的每一條，都必須對應一支 `experiments/<目標專案>-eval/test-<功能>.sh`。這支腳本收在目標專案裡，機器就能跑，不需要開互動 session。

寫的時候挑一種驗法，挑合適的，不要硬發明新的：

| 驗法 | 適合什麼情況 | 怎麼做 |
|---|---|---|
| 比對設定是否一致 | 同一份設定散在多個檔案時 | 在腳本裡寫死正確的來源，解析各個檔案來比對 |
| 觸發後看有沒有反應 | hook 或中介機制有沒有被叫到 | 構造標準輸入和環境，呼叫 hook，檢查輸出和退出碼 |
| 跑分評輸出品質 | agent 產出的內容對不對 | 受控的實例加上標準答案，統一輸出 `METRICS|` 那一行方便彙整 |
| 比對前後差異 | 副作用對不對 | 跑之前拍一張快照，跑完再比 |

**串起來的硬規定，在目標專案端施作：**

- `experiments/<目標專案>-eval/run-self-verify.sh` 是唯一的入口，跑完所有 `test-*.sh`，回傳 0 或 1。`/done`、Stop hook、CI 都叫同一個。
- `.claude/hooks/self-verify-on-stop.sh` 註冊到 `settings.json` 的 `Stop`。發現對不上就 exit 2，擋住 Claude 結束這一輪。

  **觸發條件**是架構檔（設定、文件、驗證腳本）的指紋變了才跑整套。純諮詢、純閱讀的 session 靜默放行。這道關卡管的是「改了東西沒驗」，不是「每次收工都罰跑一次」。指紋只在通過之後才寫入，所以改壞了不修，下一輪還是會被抓。
- 目標專案端先把上面這兩塊做好，這是一次性的。之後每加一條 script 層級的驗收測試，只要多寫一支 `test-*.sh`。

**參考實作**在第一個落實的目標專案 `atdd-task`：入口是 `experiments/atdd-eval/run-self-verify.sh`，Stop hook 是 `.claude/hooks/self-verify-on-stop.sh`，已有的驗證腳本包含 `test-model-routing.sh`（比對設定）、`test-confidence-gate.sh`（觸發後看反應）、`eval-coder.sh` 和 `eval-reviewer.sh`（跑分評品質）。

---

## Part F：還沒補的洞

- **待辦**：每一條都要寫具體的觸發條件。禁止模糊的 TODO——「等下個階段補」「後續優化」都不夠。要寫成「合 PR 的時候順手補」「實際出現破壞性操作時補」這種有觸發條件的。
- **已淘汰但留著當前車之鑑的項目**：附上失效的原因，以及為什麼要保留。
- **還不知道自己不知道什麼**：明確承認。

---

## 輕量版

上面的 Part A 到 F 是完整版，複雜的專案（有 agent 迴圈、涉及多個設計面向）該用。

但不是每個任務都值得一份完整版。小改動硬套完整格式，誘因就是把 Part A 到 F 的標題留著、內容掏空。2026 年 6 月那次掏空事故的根本原因，就是當時沒有一個合法的輕量出口。輕量版就是那個出口。

**什麼情況適用**（在開頭標 `template: lite`）：

- 沒有 agent 迴圈，只是調整設定、修文件、增修單一 hook 或指令，或者
- 涉及的設計面向不超過 4 條。

有 agent 迴圈，或涉及超過 4 條面向，就回去用完整版。拿不準的話用完整版，保守一點。

**輕量版的結構就是一頁的約定。** 表格的重量可以縮，但證據的紀律不能縮。

1. **這次要改什麼**：一兩句話講清楚，對著哪個痛點。
2. **涉及的三到六條面向**：每條寫一句「該長什麼樣」加上目前狀態。其他面向一行帶過（`面向 N 用不到 — 理由`），不用逐條展開五個欄位。
3. **`### V<n>` 驗收表**：證據欄位跟完整版完全同規格，一格都不能減——`Verify level`、`Status`、`Live-fired at`、`Self-verify runs`。欄位的意思見 Part E。這是不變的。
4. **不動清單**：明列這次不該動的檔案、介面、行為。

```
### V1: <測試名稱>
- **Verify level**: script | trace-observation | human-only
- **Status**: ✅ passing / ❌ failing / 🚧 not testable yet
- **Live-fired at**: <ISO 時間戳>   ← 標 ✅ passing 時必填
- **Self-verify runs**: N/A | <次數>×pass / <次數>×total   ← Verify level 是 script 時必填
```

再強調一次：表格的重量隨任務縮放，證據的紀律不縮放。

完整版用五個欄位的面向區塊逼你想清楚每一條。輕量版省掉那層重量，但驗收表和那四個證據欄位一格都不能少。沒有這些欄位，「輕量」就退化成「掏空」。

**機器擋關。** 輕量版由 `test-prescription-contract.sh` 的輕量分支來驗，依開頭的 `template: lite` 分流。它檢查三件事：至少有一個 `### V` 區塊；有一段含「不動」字樣的清單；證據紀律跟完整版同規格（標 ✅ passing 的條目要有真的 `Live-fired at` 時間戳；`Verify level: script` 加上 ✅ 的要有非空的 `Self-verify runs`）。缺驗收表或缺「不動」那段就算失敗。

---

## 模板使用守則

1. 一份設計方案對應一個目標專案、一個時間點。換一個專案就開新檔。
2. 升版（v1 到 v1.5）開新檔。舊檔狀態改成 `superseded` 保留，當歷史參考。
3. Part B 對通用規則的檢查一定要跑，那是最低標準。Part C 才是針對這個領域的客製。
4. Part E 是這份方案的約定。如果 Part E 全部通過，使用者應該要能感受到 Part A 講的那個問題真的被解決了。
5. 每一份新方案都要明確標 `template: full | lite`。沒寫會被當成完整版，但不要靠預設值——明確標出來，review 和機器擋關才能一眼分流。判斷標準見「輕量版」那節。
