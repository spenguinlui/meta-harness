# Prescription Package Template

`meta-harness` 顧問對特定 target repo 輸出的格式。Prescription package 是「**請在你的 target repo 安裝這些**」清單，不是「我幫你做完了」。

每份 prescription 是某時點的 snapshot——隨 target repo 演化、universal rules 演化、lessons 累積，會出 v1.5 / v2 / ...。

---

## Header

```yaml
target_repo: <name + URL>
generated_at: <ISO timestamp>
status: draft | active | superseded
source_sessions:
  - <link to Phase 0 session>
  - <link to 9 design axes audit session>
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

## Part B：衛生規則對照（R-1~R-9 Compliance）

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

**狀態語意**：
- ✅ comply
- ⚠️ partial（列具體差異）
- ❌ not yet（會進 Part D 安裝清單）
- N/A（含理由——例如該 repo 沒有對應概念）

---

## Part C：12 設計軸對應 + domain 新抽象（mechanism wiring）

對 [12 設計軸](design-axes/) 每條，產出特化 prescription。**每條必含五個欄位**——少了 Mechanism 就走進「**有圖書館但沒人翻、有筆記本但沒人寫**」的反模式：只寫格式（static config）卻沒寫「何時讀／何時寫／lifecycle／validation」，AI 就自由發揮、可能完全不主動寫、或被 Claude Code 內建 memory 取代。

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

---

## Part D：安裝清單（要寫進 target 的具體檔案）

具體可執行的安裝清單，按類別分組：

### D.1 File-level
新建檔案、CLAUDE.md 加段落、文件結構。

### D.2 Hook installations
`.claude/hooks/` 下的 script + `.claude/settings.json` 註冊。

**每個 hook 必含 Matcher Precision 三項**（防 hook matcher 過寬 → false positive，例如裸字面 `"inventory"` 會擋自家 commit message 含此字眼的正常工作）：

```
- Hook ID: <name>
- Trigger event: PreToolUse | PostToolUse | UserPromptSubmit | SessionStart | Stop ...
- Tool matcher: <Bash | Edit | Write | * 等>

- Matcher precision (必填三項):
  1. Harness prefix anchor:
     <命令必含 target 自家 CLI prefix（如 `<target>/bin/...`）；不允許高頻字面（如 'inventory' / 'force'）為觸發>
     <若該 hook 用語意/regex 觸發，明示 anchor pattern + 預期不會誤匹配的字串範例>
  2. Exclusion list:
     <已知該排除的 path / command / context 清單（meta 場景如 hook 自己 commit / lesson 撰寫 / audit log 必排除）>
  3. False-positive scan checklist:
     <安裝前用以下輸入跑一次 trace mode，確認不誤觸：>
     - <寫 5 個「應該不觸發」的命令 / message 範例>
     - <寫 3 個「應該觸發」的命令 / message 範例（正向 ground truth）>
     - <若涉及 commit message 攔截：跑 `git log --oneline -50` 反推哪些舊 commit 會被擋，標出 false-positive>

- Spec: <script 邏輯>
- Validates: V<n>
```

**反模式**（明令禁止）：

- ❌ matcher 只用裸字面/全域 regex（如 `inventory`、`force` 等高頻詞）做攔截
- ❌ 沒 exclusion list（特別是 hook 自己 commit / lesson 撰寫 / audit log 等 meta 場景）
- ❌ 安裝後才發現誤擋——必先做 false-positive scan

### D.3 Skill additions
新 `bin/` 子命令、新 skill 目錄。

### D.4 Settings adjustments
permissions、env vars、其他 `.claude/settings.json` 條目。

### D.5 Directory structure
top-level 新目錄（含 `.gitkeep` 確保入版控）。

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
- **Status**: ✅ passing / ❌ failing / 🚧 not testable yet
- **Live-fired at**: <ISO timestamp>   ← ✅ passing 必填
- **Trace**: 對應 Part D 哪些安裝項目
```

**Live-fire 規則**：

- 任何 V<n> 對應的 Part D 項目含 **protocol / schema / API contract 範例**（hook 輸出、JSON wrapper 等），**Status `✅ passing` 必需 live-fire 證據**：在 target repo 真的 trigger 該情境，觀察行為符合 expected
- `Live-fired at` 三選一：
  - `<ISO timestamp>` — 已實彈跑過，Status 可標 ✅ passing
  - `🚧 not testable yet — <reason>` — 例：「需等 destructive op 實際出現才能驗」，Status 必為 🚧 not testable yet
  - **不允許** Status ✅ 但 Live-fired at 空白——看似 ✅ 實則從沒被 trigger 過是最常見的 prescription 級假象
- Live-fire 不等於 dry-run / unit test。必須以**真實 user intent / 命令**進入 Claude Code session 觸發

**通過**：prescription 真的落地到行為層（避免「文件講了沒落地」與「schema 靜默落空」兩種假象）。
**失敗**：安裝不完整或規則沒被遵守，要修。

---

## Part F：落差與跟進（已知 gap、deprecated、unknown unknowns）

- **Pending**（含具體觸發條件，禁止模糊 TODO——例如 "等下 stage 補"、"後續優化" 都不夠；要寫「合 PR 時順手補」「實際 destructive op 出現時補」這種觸發條件）
- **Deprecated** items kept as cautionary examples（含失效原因 + 為什麼保留）
- **Unknown unknowns** 顯式承認

---

## 模板使用守則

1. 一份 prescription = 對一個 target repo + 一個時間點。其他 target repo 開新檔。
2. 升版（v1 → v1.5）開新檔，舊檔狀態改 `superseded` 保留作歷史 reference。
3. Part B 對 universal rules 的 compliance check 必跑，這是「衛生 floor」；Part C 才是 domain 客製。
4. Part E 是 prescription 的「合約」——若 Part E 全 pass，使用者該感受到 Part A 的 mission 真的被滿足。
