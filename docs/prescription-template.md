# Prescription Package Template

`meta-harness` 顧問對特定 target repo 輸出的格式。Prescription package 是「**請在你的 target repo 安裝這些**」清單，不是「我幫你做完了」。

每份 prescription 是某時點的 snapshot——隨 target repo 演化、universal rules 演化、lessons 累積，會出 v1.5 / v2 / ...。

---

## Header

```yaml
target_repo: <name + URL>
generated_at: <ISO timestamp>
status: draft | active | superseded
template: full | lite    # 分級鍵；缺省 = full。判準與結構見下方「Prescription Lite（輕量分級）」節
implementation_medium: claude-code-harness | web-app | api-service | saas | hybrid | other
  # claude-code-harness：主要 artifact 是 hook / skill / settings.json / bash script
  # web-app / api-service / saas：主要 artifact 是 route / DB schema / component / infra config
  # hybrid：AI harness 嵌在 web/SaaS 產品內（如 OpenClaw、Hermes agent 類）
  # → Part D 的 artifact 語言跟著切換，不預設 bash/Claude Code
source_sessions:
  - <link to Phase 0 session>
  - <link to 13 design axes audit session>
  - <other relevant sessions>
universal_care_rules_baseline: <commit hash of universal-care-rules.md>
prescription_version: <v1, v1.5, v2 ...>
```

---

## Part A：需求摘要（Step 1 5 件事訪談結論）

從對應 Phase 0 session 抽到的關鍵結論。所有後續 prescription 都 trace 回這裡：

- **Mission statement**：一兩句話
- **Persona**：誰會用、互動模式（**必含 builder vs human 區分**——builder = 設計這 target 的工程師；human = 每天跑指令看結果的人；可能同人可能不同人）
- **Human 領域熟悉度**：human 在這 target 的領域是 peer 還是非專家？哪些子領域 peer / 哪些非 peer？決定設計軸 12 翻譯層深度
- **Key Success criteria**：尤其 SC2 failure floor（決定哪條設計軸是 existential）
- **Domain shape**：例如 `many_independent_projects` / `sequential_workflow` / `transform_pipeline`
- **Anti-scope**：明確列出「不做」清單

---

## Part B：衛生規則對照（R-1~R-12 Compliance）

對 [universal-care-rules.md](universal-care-rules.md) 每條規則的 compliance status：

| Rule | Status | Note |
|---|---|---|
| R-1 CLAUDE.md ≤ 50 行 | ✅ / ⚠️ / ❌ / N/A | 若 ⚠️ 列缺什麼 |
| R-2 settings 入版控 | ... | ... |
| R-3 hook ≤ 100 行 | ... | ... |
| R-4 不流暢編造 | ... | ... |
| R-5 提問錨具體 artifact | ... | ... |
| R-6 不用未解釋專有名詞 / 縮寫 | ... | ... |
| R-7 wiring 不固化壞流程 / fix 先 root cause | ... | ... |
| R-8 跨層越權禁止 | ... | ... |
| R-9 framework vs 任務內容分流 | ... | ... |
| R-10 可機驗 outcome 先自驗再交付 | ... | ... |
| R-11 可被他人使用必交付說明書 | ... | 走 Step 5.5 `/document`；不交接的自用腳本 N/A |
| R-12 target 落地檔 self-contained | ... | 落地後 grep target 無 meta-harness 行話 |

**狀態語意**：
- ✅ comply
- ⚠️ partial（列具體差異）
- ❌ not yet（會進 Part D 安裝清單）
- N/A（含理由——例如該 repo 沒有對應概念）

---

## Part C：13 設計軸對應 + domain 新抽象（mechanism wiring）

對 [13 設計軸](design-axes/) 每條，產出特化 prescription。**每條必含五個欄位**——少了 Mechanism 就走進「**有圖書館但沒人翻、有筆記本但沒人寫**」的反模式：只寫格式（static config）卻沒寫「何時讀／何時寫／lifecycle／validation」，AI 就自由發揮、可能完全不主動寫、或被 Claude Code 內建 memory 取代。

```
### Design Axis N: <name>

**Required**: 該 repo 在這條設計軸該長什麼樣（基於 Part A）
**Status**: already-installed | partial | not-installed | deprecated
**Trace**: 對應 Phase 0 哪條 mission / persona / SC

**Static config (what to install)**: 指向 Part D 的具體檔案 / 結構

**Mechanism (behavioral contract)**:
  - **Write triggers**: 何時該寫入？列具體觸發條件（事件 / 命令 / hook / 使用者意圖）
  - **Read mechanism**: 何時 Claude 該查詢這份資料？（session-start auto-load / on-demand grep / 條件觸發）
  - **Lifecycle**: 條目怎麼從 created → active → superseded / archived？誰負責 transition？
  - **Validation**: 對應 Part E 的 V<n> test，驗證 mechanism 真的有 work

**Implementation freedom**: 標明哪些是 contract（必須做到的行為），哪些是實作自由（bash / python / 應用、皆可）。
```

### 為什麼 Mechanism 不可缺

只寫格式（Static config）不寫機制 = 「**有圖書館但沒人翻、有筆記本但沒人寫**」。  
AI 在當下會自己決定何時讀寫，缺乏一致性，半年後新人 / 新 session 接手沒共同預期。

例如「memory layer」：
- ❌ 只說「建 decisions/ 目錄、用此格式寫 ADR」 → AI 可能完全不主動寫，或用 Claude Code 內建 memory 取代，繞過你的設計
- ✅ 加 Mechanism：「destructive op 完成後 hook prompt 寫 ADR；session-start 注入 decisions/INDEX.md；架構類 commit message 觸發 ADR prompt；ADR 衝突時 pre-commit hook 偵測 supersede」 → 行為可預期、可驗

### N/A 處理

某條 design axis 對該 domain 真不需要時，五個欄位仍要填，Mechanism 寫 `N/A — <reason>`。**不允許整段省略**——強制 reviewer 看見「有意決定不做」vs「忘了想」。

### 新抽象（domain-specific extension）

domain 自己的新抽象（target 業主的核心概念，如 Watcher / Recommendation / Pipeline / Workspace 等）一併列在 Part C，遵守同一格式（Required / Status / Trace / Static config / Mechanism）。

### 必答題（特定設計軸）

某些設計軸不問會踩典型反模式，本 template 強制要求 prescription 答：

- **設計軸 8 Evaluation loop 必答**：「**做完任務的結果，能不能回連到當初的計畫 / 決策？怎麼連？**」
  - 沒連 = outer eval 飛輪斷一截，系統只能憑 human 主觀回報、無法客觀學習
  - 常見實作：commit message reference / cloud-state tag / transaction log / audit trail 編號 / 多重綁定
  - 答 N/A 必附理由（如「純 read-only target、沒 mutating outcome」）

- **設計軸 3 Memory 必答**：「**user-scope auto-memory 寫入紀律是什麼？什麼時候該升 git（universal rule / project CLAUDE.md / docs/）？**」
  - 沒紀律 = Claude Code 預設「都往那塞」→ user memory 變垃圾場、規則永遠不升 git、team 接手斷層
  - 對位設計軸 3 反模式 #10「Auto-memory 變終點」+ #9「過度依賴 user-scope auto-memory」
  - 答 N/A 必附理由（如「solo project 沒接手考量」）

- **設計軸 12 Human Interface 必答**：「**human 是不是這 target 領域 peer？非 peer 時翻譯層怎麼蓋？回饋通道怎麼設計？builder 還在嗎？**」
  - human 非 peer 沒蓋翻譯層 = jargon 牆 = 等於沒輸出
  - 沒回饋通道 = 訊號流失 = 系統無法迭代
  - builder 不存在 = 結構問題，mechanism 救不了

### 軟體工程紀律映射

Wiring 設計可（也應該）用軟體工程方法學的語言來精確描述。常見對應：

| 概念 | harness 對應例 | 出處 |
|---|---|---|
| **Strategy Pattern** | engine pluggable（agent-engines.yml + dispatch；claude vs codex 是同介面兩實作）| Design Patterns |
| **Specification Pattern** | 規則資料化（如 atdd-task `tool-safety.yml` 的 destructive 清單）| Domain-Driven Design |
| **Middleware / Chain of Responsibility** | hook 鏈（PreToolUse → Tool → PostToolUse → SubagentStop）| Design Patterns |
| **Facade** | slash command（`/continue` 把底下 pipeline 包成單一入口）| Design Patterns |
| **Repository** | MCP（`atdd_task_*` 封裝 task 持久化、與 client 解耦）| DDD |
| **Bounded Context** | agent scope 紀律（risk-reviewer 不做 spec-gap，那是 gatekeeper 的）| DDD |
| **Ubiquitous Language** | 「信心度」「e2eDecision」「reviewFindings」這類 domain 詞彙必須跨 prescription/skill/agent 一致 | DDD |
| **Hexagonal / Ports-and-Adapters** | `ports/` 目錄結構（atdd-task `ports/mcp`/`ports/api`/`ports/worker`）| Clean Architecture |
| **ATDD（Acceptance Test-Driven Development）** | 本 template Part E 必須先寫、Part D wiring 後落、`run-self-verify` 綠才算完 | XP / ATDD |
| **SRP / DIP（SOLID）** | 單一責任：一個 hook 一個 gate；依賴反轉：agent prompt 不該依賴具體引擎（dispatch 層抽掉）| SOLID |

**為什麼明寫**：違反 SRP 的 God hook、洩漏實作的 prompt、跨 context 的 ubiquitous language drift——這些在自驗 / hook 接口層會自然暴露。**有名字之後，設計討論的精度與 review 效率會提升**；不是為套 pattern 而套。

**LLM-specific patterns**（傳統方法學未直接 cover、要在 harness domain 另建）：

- 4 種自驗 pattern（單一真實來源+drift 偵測 / 觸發+斷言 / Scorer+METRICS / 快照+Diff）—— 對應傳統 unit test pattern 的 LLM-aware 演化版
- prompt caching economy、agentic loop、eval-driven prompt iteration、model routing、context window 預算

Prescription Part D 設計 wiring 時，若觸及這些 LLM-specific 議題（如 dispatch、cost-correct 量測），需明確標示採用的 pattern，便於跨 prescription 比對與重用。

---

## Part D：實作清單（要寫進 target 的具體 artifact）

具體可執行的實作清單，按類別分組。**artifact 語言跟著 Header `implementation_medium` 切換**——不預設 bash / Claude Code 結構。

### D.0 實作介質宣告

在此明確本 prescription 的 artifact 類型，讓 Part D.1–D.5 的讀者知道用什麼語言看：

```
implementation_medium: <同 Header>
tech_stack: <主要語言 / 框架 / 平台，如 Next.js + PostgreSQL / FastAPI + Redis / bash + Claude Code>
artifact_language:
  - claude-code-harness  → D.1 = CLAUDE.md / docs；D.2 = hooks；D.3 = bin/ skills；D.4 = settings.json
  - web-app / api-service → D.1 = 路由 / 元件 / DB schema；D.2 = middleware / webhook；D.3 = service / module；D.4 = env / config
  - saas / hybrid        → 混合以上，每條 artifact 標明所在層（harness 層 / 應用層）
```

### D.1 核心檔案 / 結構
依介質而定：
- **claude-code-harness**：CLAUDE.md 段落、文件結構、docs/ 規則類文件
- **web-app / api-service**：路由定義、DB schema、元件骨架
- **saas / hybrid**：依所在層分開列（harness 層 / 應用層標清楚）

### D.2 事件攔截 / Middleware
依介質而定：
- **claude-code-harness**：`.claude/hooks/` 下的 script + `.claude/settings.json` 註冊

  **每個 hook 必含 Matcher Precision 三項**（防 hook matcher 過寬 → false positive）：

  ```
  - Hook ID: <name>
  - Trigger event: PreToolUse | PostToolUse | UserPromptSubmit | SessionStart | Stop ...
  - Tool matcher: <Bash | Edit | Write | * 等>
  - Matcher precision (必填三項):
    1. Harness prefix anchor:
       <命令必含 target 自家 CLI prefix；不允許高頻字面（如 'inventory' / 'force'）為觸發>
    2. Exclusion list:
       <已知該排除的 path / command / context 清單>
    3. False-positive scan checklist:
       - <5 個「應該不觸發」的命令 / message 範例>
       - <3 個「應該觸發」的命令 / message 範例>
  - Spec: <script 邏輯>
  - Validates: V<n>
  ```

  **反模式**：❌ matcher 只用裸字面/全域 regex；❌ 沒 exclusion list；❌ 安裝後才發現誤擋

- **web-app / api-service**：middleware、webhook handler、event listener
- **saas / hybrid**：標明 harness 層 hook vs 應用層 middleware

### D.3 指令 / 服務模組
依介質而定：
- **claude-code-harness**：新 `bin/` 子命令、新 skill 目錄
- **web-app / api-service**：新 service、新 API module、新 worker
- **saas / hybrid**：標明所在層

### D.4 設定 / 環境
依介質而定：
- **claude-code-harness**：permissions、env vars、`.claude/settings.json` 條目
- **web-app / api-service**：`.env`、feature flags、infra config、CI/CD 設定

### D.5 目錄結構
top-level 新目錄（含入版控的空檔確保結構存在）。

每項格式：

```
- Status: ✅ installed (commit hash) / 📋 to install / ❌ deprecated (reason)
- Spec: <足夠 worker 安裝不需再諮詢的細節>
- Runtime verified: <ISO timestamp> via <test method>   ← ✅ installed 必填
- Validates: <Part E 哪條測試確認生效>
```

**Runtime verified 規則**：

- 任何 spec 含 **protocol / schema / API contract 範例**（hook output 格式、JSON schema、deny/allow wrapper、stdout/stderr 約定等），標 `✅ installed` 前**必經 explicit runtime test**——code review 看不出 schema 是否與當前 Claude Code spec 對齊
- `Runtime verified` 欄位三選一不可省略：
  - `<ISO timestamp> via <Part E V<n>>` — 走 Part E 對應 live test
  - `<ISO timestamp> via <ad-hoc test description>` — 例：「手動 trigger Bash 命令觀察 hook 行為，stderr 出現 deny reason」
  - `🚧 not yet runtime-verified` — **則 Status 不可標 ✅ installed**，須留 `📋 to install` 或新增 `⚠️ code-installed but not runtime-verified` 中間狀態
- 「stdout 是 valid JSON、exit 0、看起來對」**不算** runtime verified——Claude Code 對 schema mismatch 是**靜默忽略**：hook 邏輯對、stdout 是 valid JSON、exit 0，但若 schema 用舊版 flat 格式（e.g. `{"permissionDecision":"deny"}` 而非 nested `{"hookSpecificOutput": {"hookEventName":"PreToolUse", ...}}`），Claude Code 不擋且不報錯，從 outside 看完全像有 work
- 第三方權威來源（如 `claude-code-guide` agent / 官方文件版本）查證優於「LLM 腦補 schema」

---

## Part E：驗收測試（業主跑哪些命令、該看到什麼）

在 target repo 開 Claude session，跑這些命令 / 表達意圖，看行為是否如預期。

每條測試：

```
### V<n>: <test name>
- **Intent / command**: 使用者輸入什麼
- **Expected behavior**: Claude 該做什麼
- **Failure mode**: 怎樣算不對
- **Verify level**: script | trace-observation | human-only   ← 必填，決定誰跑
- **Status**: ✅ passing / ❌ failing / 🚧 not testable yet
- **Live-fired at**: <ISO timestamp>   ← ✅ passing 必填
- **Self-verify runs**: N/A | <count>×pass / <count>×total   ← Verify level=script 必填
- **Trace**: 對應 Part D 哪些安裝項目
```

**Verify level 三類**（消化 2026-05-17 self-profile audit 教訓 + R-10 落地）：

- **script**：可用 `claude -p` headless / bash 腳本 / `jq` structural check 機驗。**顧問必須自己跑**（R-10 / Step 4.5），跑 ≥ 3 次穩定通過才能標 ✅ passing。`experiments/<target>-<topic>/` 結構承載。
- **trace-observation**：要在 target session 內 trigger 後**觀察 trace / log / hook 觸發**才能判定。顧問可代跑（如自己起 session 試），但體感判定仍可能涉及業主。
- **human-only**：需要業主主觀判定品質 / 風格 / 是否切痛點。顧問不該獨自結案。例：「Claude 給的建議讀起來像不像資深架構師」。

**Live-fire 規則**：

- 任何 V<n> 對應的 Part D 項目含 **protocol / schema / API contract 範例**（hook 輸出、JSON wrapper 等），**Status `✅ passing` 必需 live-fire 證據**：在 target repo 真的 trigger 該情境，觀察行為符合 expected
- `Live-fired at` 三選一：
  - `<ISO timestamp>` — 已實彈跑過，Status 可標 ✅ passing
  - `🚧 not testable yet — <reason>` — 例：「需等 destructive op 實際出現才能驗」，Status 必為 🚧 not testable yet
  - **不允許** Status ✅ 但 Live-fired at 空白——看似 ✅ 實則從沒被 trigger 過是最常見的 prescription 級假象
- Live-fire 不等於 dry-run / unit test。必須以**真實 user intent / 命令**進入 Claude Code session 觸發
- **Self-verify gate**：Verify level=script 的 V<n>，prescription 交付前顧問必須跑 Step 4.5 自驗 loop。`Self-verify runs` 欄記錄 pass/total。`Self-verify runs` 空白 + Verify level=script + Status=✅ → 一律視為**假象**（同 Live-fired at 空白）

**通過**：prescription 真的落地到行為層（避免「文件講了沒落地」與「schema 靜默落空」兩種假象）。
**失敗**：安裝不完整或規則沒被遵守，要修。

### Self-verify 基建（target 級硬規則，與 R-10 配對）

`Verify level=script` 的 V<n> **必須**對應一支 `experiments/<target>-eval/test-<feature>.sh`（target 內收，可機跑、無需 live session）。寫 scorer 走四種 pattern 之一（揀適合的、別硬發明）：

| Pattern | 適用情境 | 招式 |
|---|---|---|
| **單一真實來源 + drift 偵測** | 配置 / wiring 跨檔一致性 | 在 script 內 hardcode 真實來源，parse N 個檔比對 |
| **觸發 + 斷言** | hook / 中介機制是否被吃到 | 構造 stdin / 環境，呼叫 hook，斷言 stdout/exit code |
| **Scorer + METRICS 行** | 行為品質（agent 輸出對不對）| 受控實例 + ground truth + 統一 `METRICS\|` 行供彙整 |
| **快照 + Diff** | 副作用是否正確 | 跑前 snapshot state，跑後比 |

**串成硬規則**（target 端施作）：

- `experiments/<target>-eval/run-self-verify.sh` 為**單一 entry point**：跑所有 `test-*.sh`，回 0 / 1。`/done`、Stop hook、CI 都叫同一個。
- `.claude/hooks/self-verify-on-stop.sh` 註冊到 `settings.json` 的 `Stop`：drift → exit 2 擋住 Claude 結束本輪。
- target 端先做這兩條基建（一次性），之後每加一個 V<n>=script，只多寫一支 `test-*.sh`。

**參考實作**（首落地 target）：`atdd-task` repo
- runner：`experiments/atdd-eval/run-self-verify.sh`
- Stop hook：`.claude/hooks/self-verify-on-stop.sh`
- 已有的 scorer：`test-model-routing.sh`（Pattern 1）、`test-confidence-gate.sh`（Pattern 2）、`eval-coder.sh` / `eval-reviewer.sh` etc.（Pattern 3）

---

## Part F：落差與跟進（已知 gap、deprecated、unknown unknowns）

- **Pending**（含具體觸發條件，禁止模糊 TODO——例如 "等下 stage 補"、"後續優化" 都不夠；要寫「合 PR 時順手補」「實際 destructive op 出現時補」這種觸發條件）
- **Deprecated** items kept as cautionary examples（含失效原因 + 為什麼保留）
- **Unknown unknowns** 顯式承認

---

## Prescription Lite（輕量分級）

上面 Part A–F 是 **full 版**——複雜 target（有 agent loop、涉及多條設計軸）該用。但不是每個任務都值得一份 full prescription：小改動硬套 full 格式，誘因是把 Part A–F 標題留著、語義掏空（2026-06 掏空事故的根因 = **沒有合法的輕量出口**）。Lite 是那個合法出口。

**適用判準**（frontmatter 標 `template: lite`）：

- **無 agent loop**（純 wiring 調整、文件修正、單一 hook / command 增修），**或**
- **涉及設計軸 ≤ 4 條**。

有 agent loop 或涉及軸 > 4 → 回 full。拿不準 → 用 full（保守）。

**Lite 結構 = 一頁合約**（表格重量縮放，證據紀律不縮放）：

1. **形狀摘要**：一兩句話講這次要改什麼、對著哪個痛點。
2. **涉及軸 3–6 條**：每條一句 Required + Status；其餘軸**一行帶過**（`軸 N N/A — <理由>`），不逐條展開五欄位。
3. **`### V<n>` 驗收表**：**證據欄位與 full 完全同規格，一格不減**——`Verify level` / `Status` / `Live-fired at` / `Self-verify runs`（欄位語意見 Part E）。這是不變量。
4. **不動清單**：明列這次**不該動**的檔案 / 介面 / 行為（保留邊界宣告）。

```
### V1: <test name>
- **Verify level**: script | trace-observation | human-only
- **Status**: ✅ passing / ❌ failing / 🚧 not testable yet
- **Live-fired at**: <ISO timestamp>   ← ✅ passing 必填
- **Self-verify runs**: N/A | <count>×pass / <count>×total   ← Verify level=script 必填
```

**表格重量隨任務縮放、證據紀律不縮放**：full 用五欄位 Design Axis 塊逼你想清楚每條軸；lite 省掉那層重量，但 V 表與四個證據欄位（Verify level / Status / Live-fired at / Self-verify runs）**一格都不能少**——沒有這些欄位，「輕量」就退化成「掏空」。

**機器閘門**：lite 版由 `test-prescription-contract.sh` 的 **lite 分支**驗（依 frontmatter `template: lite` 分流）——檢查 (1) 至少一個 `### V` 區塊存在、(2) 含「不動」字樣的清單段存在、(3) 證據紀律 (b)(c)（✅ passing 的 V 條目有真 `Live-fired at` 時間戳；`Verify level: script` + ✅ 有非空 `Self-verify runs`）與 full 同規格適用。缺 V 表或缺「不動」段 → fail。

---

## 模板使用守則

1. 一份 prescription = 對一個 target repo + 一個時間點。其他 target repo 開新檔。
2. 升版（v1 → v1.5）開新檔，舊檔狀態改 `superseded` 保留作歷史 reference。
3. Part B 對 universal rules 的 compliance check 必跑，這是「衛生 floor」；Part C 才是 domain 客製。
4. Part E 是 prescription 的「合約」——若 Part E 全 pass，使用者該感受到 Part A 的 mission 真的被滿足。
5. **每份新 prescription 一律顯式標 `template: full | lite` 鍵**（缺省視為 full，但不要靠缺省——顯式標讓 review 與機器閘門一眼分流）。判準見「Prescription Lite」節。
