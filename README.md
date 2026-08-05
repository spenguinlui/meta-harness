> 🌐 **繁體中文** | [English](README.en.md)

# meta-harness

> **設計 AI agent harness 的方法論 + 顧問 wiring。**
> Prompt engineering 改字；harness engineering 改「模型周圍的整套系統」。
> 適用任何實作介質——bash 腳本、Web app、SaaS、hybrid 產品，只要裡面有 AI agent 就適用。

---

## 1. 是什麼 / 能做什麼

`meta-harness` 是一位住在 Claude Code 裡的「**AI agent 系統設計顧問（建築師）+ 實作器**」。

你不會「執行」這個專案——你**進到它的目錄、開一個 Claude Code session**，它就變成一位懂工法、懂最佳實踐的建築師，陪你把某個 AI agent 工具（下稱 **target repo** = 你正在設計的目標專案）設計好、蓋出來。

```
你提需求  →  顧問出設計圖  →  你 review  →  顧問把檔案實作進你的 target repo  →  驗收
```

它**不是** framework / CLI 工具 / 腳手架產生器。它是一套**對話流程 + 內建 13 大設計軸的 pattern library 顧問身分**。

### 能幫你做四類事

| 你想做的事 | 用哪個模式 | 產出 |
|---|---|---|
| **新建或重新設計**一個 AI agent 工具的骨架（要不要 hook？sub-agent 還是 skill？memory 怎麼存？）| `/design` | 一份設計圖（prescription）+ 直接寫進你 target repo 的 wiring 檔 |
| **健檢**既有系統，用 13 設計軸當鏡子找缺口、找反模式 | `/healthcheck` | 13 軸對照健檢報告 |
| **回顧**跑了一陣子的系統，看怎麼進化 | `/retro` | retrospective 紀要 + 行動建議 |
| **產 target 對外文件**（README + CONTRIBUTING，中英雙語）| `/document` | viewer 說明書（給每天用的人）+ 維護者文件（給接手改的人）|

### 為什麼是「顧問」而不是「腳手架」

13 設計軸每一條都是**設計參數**而非開關，且彼此耦合，沒有對誰都剛好的標準搭配。所以是**對話 + pattern library + 設計圖為主體**，腳手架降級為顧問結論的編譯產物。

---

## 2. 快速開始

### 前置

- **Claude Code CLI** 已安裝（`claude --version` 跑得起來）。唯一硬需求。
- 心裡有一個想設計的 target repo（**不需要已存在**——能講出「想做什麼」就行）。

> **沒有 `.env`、不需要 API key 檔。** 這個專案本身不連任何外部服務、不存任何密鑰——執行環境就是 Claude Code 本身。

### 取得 + 進場

```bash
git clone <this-repo> ~/meta-harness
cd ~/meta-harness
claude
```

開 session 後**先 `/model` 切到最強的 model**——設計、推理、方法學任務的思考品質不能弱（弱 model 容易堆砌術語牆、給出反模式、留邏輯漏洞）。AI 不能切自己的 model，這是設計者要主動做的一步。

進去後用 **slash command 當前門**，或直接講白話（顧問身分會自動載入）：

```
/design ~/my-project              # 新建或重設一個 harness
/healthcheck ~/my-project         # 既有系統定點體檢
/retro ~/my-project               # 跑一陣子後回顧
/document ~/my-project            # 產對外說明書
（不打 command，直接講）          # 接續上次 session
```

第一次跑通常 10–20 分鐘做完訪談 + 看到第一份 prescription。完整新手導引：[`docs/getting-started.md`](docs/getting-started.md)。

---

## 3. 存取與參數

| 檔案 | 必要 | 說明 |
|---|---|---|
| `targets.yml` | 選用 | 你本機的 target repo 清單。`cp targets.yml.example targets.yml` 後自行編輯。已 gitignore。 |
| `.env` | **不需要** | 本專案不用，不需任何 API key 檔。 |

`targets.yml` 讓你記錄本機 target 清單（路徑、狀態 concept/pending-audit/audited、可選 `eval_dir` 蓋過軸 13 預設路徑）。開 session 時可從這份挑一個，也可完全略過、對話裡直接給 target 絕對路徑。

---

## 4. 怎麼用 / 常見任務

進去後，你會走五種模式之一。每個模式都是「**對話前門**」——不是填表、不是腳手架，進去後一律和顧問對話。

| 模式 | Command | 白話講法 | 何時用 |
|---|---|---|---|
| **設計** | `/design <target>` | 「我想設計／重新設計 ~/X」 | 新建或重設一個 harness |
| **健檢** | `/healthcheck <target>` | 「健檢 ~/X」 | 既有系統定點體檢、找缺口（冷啟動可做）|
| **回顧** | `/retro <target>` | 「回顧 ~/X」 | target 跑一陣子後回看進化 |
| **說明書** | `/document <target>` | 「寫說明書／產 README」 | 文件過期、要交給別人用 |
| **接續** | （不打 command）| 「繼續上次 X 的設計」 | 接上次未完的 session |

### 設計流程 6 步（`/design` 走完整流程）

```
Step 1   需求訪談（10–20 分鐘，按鈕選擇題 + 開放題）
Step 2   建築師獨自出 prescription（你不用做事）
Step 3   你 review、來回收斂（白話文字回饋，非選擇題）
Step 4   分期落地（拆 Stage 1/2/3，寫進你 target repo）
Step 4.5 自驗 loop（強制）——可機驗的產物 headless 跑 ≥ 3 次 + 機器評分通過才交給你
Step 5   驗收（顧問跑可自動驗的、你跨 session 試用）
Step 6   飛輪 retrospective（數週後回看進化）
```

第一次用通常跑到 Step 3 或 4，Step 5–6 視需要。`/healthcheck` 和 `/retro` 是獨立短模式、不走完整 6 步。

### Builder vs Human（設計時的硬區分）

meta-harness 設計出來的 target repo 服務兩種人：

- **Builder**：用 meta-harness 顧問身分**設計**這個 target repo 的工程師（就是看這份 README 的你）。
- **Human**：每天跑 target repo 指令、看結果做決定的人——**未必是該領域的專家**（例：會計系統的 human 可能是會計助理而非工程師）。

設計軸 12「Human Interface」就是專門為 human 設計的介面層（翻譯／粒度／回饋通道），對稱於設計軸 9「Observability」（給工程師／系統看）。

---

## 5. 工作流程迴圈（人 vs AI 分工）

```
┌────────────────────────────────────────────────────┐
│                  你（Builder）                      │
│   提需求 / review prescription / 跨 session 試用    │
└──────────────────┬─────────────────────────────────┘
                   │ /design ~/my-target
                   ▼
┌────────────────────────────────────────────────────┐
│       meta-harness 顧問（Claude Code session）      │
├────────────────────────────────────────────────────┤
│  Step 1  訪談 5 件事（AskUserQuestion 按鈕選 UI）   │
│  Step 2  獨自出 prescription（你不用動）            │
│  Step 3  你回饋 → 改設計圖 → 再給你看（往返收斂）   │◀───┐
│  Step 4  分期落地：寫檔進 target（用絕對路徑）       │    │
│  Step 4.5 自驗 loop（headless ≥ 3 次 + 機器評分）   │    │ 對話收斂
│  Step 5  驗收（可機驗的代跑 + 你跨 session 試用）   │ ───┘
│  Step 6  飛輪 retrospective（數週後）               │
└──────────────────┬─────────────────────────────────┘
                   │
                   ▼
┌────────────────────────────────────────────────────┐
│         你的 Target repo（落地後的 AI 工具）         │
│  Stop hook + run-self-verify.sh                    │ ◀── 軸 13 物理紀律
│  drift（wiring 與設計圖不一致）→ exit 2 擋住結束    │
│  coverage.json 持續追蹤覆蓋率                       │
└────────────────────────────────────────────────────┘
```

**你交棒給 AI 的時機**：Step 2（顧問獨自出 prescription）、Step 4（分期落地寫檔）、Step 4.5（自驗 loop）、Step 5 的「可機驗部分」。

**你拿回控制驗收的時機**：Step 1（你提需求）、Step 3（review 設計圖）、Step 5 的「跨 session 試用」、Step 6（飛輪回顧）。

**自動關卡**：Step 4.5（headless 自驗 ≥ 3 次通過才往下）+ 軸 13 Stop hook（**動過架構檔**才跑自驗；drift 就擋 session 結束）。這兩個是**物理閘門**——R-10「可機驗 outcome 必先自驗再交付」的執行層，不能繞過。純諮詢／純閱讀的 session 不會被罰跑套件（指紋比對；`META_HARNESS_VERIFY=always` 可強制全驗）。

---

## 6. 可用指令 / skill 清單

### Slash commands（前門，4 個）

| Command | 用途 |
|---|---|
| `/design <target>` | 新建或重設 harness，走完整 6 步流程 |
| `/healthcheck <target>` | 用 13 設計軸做定點體檢，產報告 |
| `/retro <target>` | 跑一陣子後的飛輪回顧 |
| `/document <target>` | 產雙語 README + CONTRIBUTING |

### Skills（顧問身分核心，2 個）

| Skill | 用途 |
|---|---|
| `consultant` | 顧問身分定義 + 完整 6 步流程（任何 command 進去都會載入） |
| `document` | 從 prescription + repo 現況萃取，產 viewer 說明書 + 維護者文件 |

### 核心文件導覽（builder 想深讀時）

| 文件 | 用途 |
|---|---|
| [`docs/getting-started.md`](docs/getting-started.md) | **新手入口**——30 分鐘跑完第一次訪談 |
| [`.claude/skills/consultant/SKILL.md`](.claude/skills/consultant/SKILL.md) | 顧問身分定義 + 6 步流程細節 |
| [`docs/design-axes.md`](docs/design-axes.md) | **13 大設計軸索引**（設計參數總覽）|
| [`docs/design-axes/<n>-<name>.md`](docs/design-axes/) | 每軸深度選項 + 反模式 + 案例 |
| [`docs/universal-care-rules.md`](docs/universal-care-rules.md) | R-1~R-12（顧問內建強制衛生規則）|
| [`docs/prescription-template.md`](docs/prescription-template.md) | 設計圖格式（review 時對照）|
| [`docs/manual-template.md`](docs/manual-template.md) | 說明書格式 |
| [`docs/consultant-flow.md`](docs/consultant-flow.md) | 顧問決策邏輯 |
| [`docs/lessons.md`](docs/lessons.md) | 實戰教訓 |

### 13 大設計軸（一句話版）

Tool / Context / Memory / Planning / Execution / Safety / Hooks / Eval / Observability / Multi-agent / Triggers / Human Interface / **Self-Verify Coverage**

每一條都是**設計參數**而非開關，彼此耦合——這正是為什麼用顧問模式而非固定模板。

---

## 7. 產出什麼 + 怎麼確認做對了

### Session 期間產出（meta-harness 本機留痕，**全部 gitignored**）

| 路徑 | 內容 |
|---|---|
| `sessions/<date>-<topic>.md` | 訪談紀要（5 段答案 + 設計軸篩選表）|
| `prescriptions/<date>-<target>.md` | 顧問動手前的設計圖 / audit trail |
| `cases/` | 特定 target 蒸餾的案例（fork 不該看到別人任務內容）|
| `experiments/<target>-<topic>/runs/` | Step 4.5 自驗 loop 跑出的 raw 證據（含 target 真實 ID）|
| `BACKLOG.md` | 你自己「踩到的規則／方法學缺口」清單 |

每個 gitignored 目錄都保留入版控的 `README.md` 或結構檔，讓 fork 知道該目錄怎麼用，但看不到別人的私密內容。

### 寫進你 target repo 的檔案（Step 4 落地）

顧問用**絕對路徑**直接把 wiring 檔寫進你的 target repo（cwd 不離開 meta-harness）。寫什麼由設計圖決定，常見的有：`.claude/hooks/*.sh`、`.claude/skills/<name>/SKILL.md`、`.claude/commands/*.md`、`.claude/settings.json`、`experiments/<target>-eval/test-*.sh` 等。

### 怎麼確認做對了（軸 13：自驗覆蓋率 / R-10 物理化）

每個 target repo（包含 meta-harness 自身）落地後會有三件套：

- `experiments/<target>-eval/run-self-verify.sh` — 單一 entry point，跑所有 `test-*.sh`
- `experiments/<target>-eval/test-*.sh` — 各 wiring 對應 scorer（依四 Pattern 寫）
- `experiments/<target>-eval/coverage.json` — 數據面板（scorers／check 總數／mechanism 覆蓋率）
- `.claude/hooks/self-verify-on-stop.sh` + settings.json Stop 註冊 — 動過架構才驗，drift 物理擋 session 結束

**四 Pattern 分類**（每支 `test-*.sh` 必歸屬其一）：

- **A. 單一真實來源 + drift 偵測**（配置／wiring 跨檔一致性）
- **B. 觸發 + 斷言**（hook／中介機制是否被正確 trigger）
- **C. Scorer + METRICS 行**（行為品質／agent 輸出）
- **D. 快照 + Diff**（副作用是否正確）

落地現況（**即時數字**——scorer 數、check 數、覆蓋率百分比——一律見 [`experiments/meta-harness-eval/coverage.json`](experiments/meta-harness-eval/coverage.json)，由 `generate-coverage.sh` 維護；此處不手抄，手抄會漂）：

- **meta-harness 自身**：以自己的軸 13 自驗自身——runner 跑一整組 `test-*.sh` scorer，覆蓋率分母由掃描 hooks / commands / skills / bin / 模板**機器推導**，人工只能附理由排除，未覆蓋的 mechanism 逐條列在 `coverage.json`。
- **atdd-task**：首個外部 target 落地軸 13，自帶一組 scorer 與自己的 `coverage.json`。

> **覆蓋率口徑（誠實說明）**：報的是**結構 / 行為層**覆蓋（四 Pattern 的 A/B），分母機器推導、防人工灌水。**語義覆蓋率（Pattern C，LLM-judge 式的內容品質判斷）尚未完全落地、列為 roadmap 待做項**——目前 consultant skill 的輸出品質是用結構近似（`test-consultant-skill-structure.sh`）暫代，不是真正的語義驗證。

詳見 [`docs/design-axes/13-self-verify-coverage.md`](docs/design-axes/13-self-verify-coverage.md)。

---

## 8. 邊界：不做什麼 + 已知限制

### 不做什麼

- **不是腳手架產生器**：不會跑 `meta-harness new <type>` 給你一套標準目錄。理由見 §1「為什麼是顧問」。
- **不替你寫 target 業務邏輯**：顧問動 framework（hook／skill／command／settings／自驗 wiring），不動 target 的任務內容（業務規則、agent prompt 內的領域知識等）。對應規則 R-9。
- **不跨層越權**：framework 不替任務內容表態（同 R-9）；method-level 規則不寫進 target-specific 文件（R-8）。
- **不繞自驗紀律**：可機驗的 outcome 必先 headless 跑 ≥ 3 次（Step 4.5、R-10）。Stop hook 物理擋住「沒自驗就 commit」（軸 13）。
- **不連外部服務**：no API key, no telemetry, no remote sync。執行環境就是 Claude Code 本身。

### 已知限制

- **依賴 Claude Code 環境**：不在 ChatGPT / Cursor / 其他 IDE 跑（顧問身分用 Claude Code skill 與 slash command 機制）。
- **業主在的時候才好用**：設計流程靠對話，沒有 builder 在場無法獨立跑（飛輪 retrospective 部分例外）。
- **LLM 行為品質的自驗仍偏結構**：Pattern A/B/D 已落地；Pattern C（LLM-judge agent 輸出品質）的標準基建還在演化。
- **Session 額度**：跑大量 `claude -p` 子程序（如 agent×model eval matrix）會撞 Claude Code 訂閱的 session 上限；要避開設 `ANTHROPIC_API_KEY` 改走 API 帳單。

---

## 9. 出錯怎麼辦

### 常見情況

| 症狀 | 處理 |
|---|---|
| Stop hook 一直擋 session 結束 / 印「⛔ 自驗失敗」| `bash experiments/meta-harness-eval/run-self-verify.sh` 直接看哪支 drift。R-10 不是處罰、是提醒：drift 真實存在，先修。|
| 顧問亂跑 / 開始講概念不出設計圖 | 把它打回建築師身分：「你是建築師，不是教科書朗讀者；直接給 mechanism。」consultant skill 有「身分漂移」防線，但 builder 自查也是一層。|
| 不確定該不該升設計軸 / R-N | 看 `docs/consultant-flow.md` 決策邏輯，或在 session 內問顧問「這該升 universal 嗎？跨 target 還成立嗎？」|
| 落地後發現 wiring 跟 prescription 對不上 | 跑 `experiments/meta-harness-eval/test-cross-references.sh` — 自動抓 R-N／軸 N drift。也可手動 grep。 |
| Claude session 撞額度上限 | 看訊息提示重置時間；長期解法是設 `ANTHROPIC_API_KEY` 改走 API 帳單（另一池額度）。|

### 踩過的坑（持續更新）

`docs/lessons.md` 累積實戰教訓（每條含「為什麼踩、之後怎麼防」）。

### 找不到答案？

去 [Issues](https://github.com/spenguinlui/meta-harness/issues) 或直接開 PR；也歡迎在 session 裡跟顧問講「我覺得方法學有個缺口」，它會幫你判斷該升 R-N 還是放 `docs/lessons.md`。

---

## 10. 誰維護 / 怎麼回報

- **維護者**：[@spenguinlui](https://github.com/spenguinlui)（這套方法學的主要 builder）。
- **回報問題 / 建議**：開 [GitHub Issue](https://github.com/spenguinlui/meta-harness/issues)；附上**踩到的具體情境**（哪個 session、哪份 prescription、哪條軸／規則卡住）比抽象建議有用。
- **想擴充方法學本身**（加軸 / 加規則 / 加 skill）：先讀 [`CONTRIBUTING.md`](CONTRIBUTING.md)，那裡講「擴 meta-harness 自己」的紀律。
- **想分享你的 prescription / 設計圖**：歡迎開 PR 加進 `cases/`（但記得 prescriptions/ 本身 gitignored、含 target 私密內容；要分享得另寫精簡版）。

---

## 11. 詞彙表

meta-harness 內部自創詞，第一次接觸時容易混。peer 也建議查一下：

| 詞 | 白話 |
|---|---|
| **target repo（target）** | 你正在設計的 AI agent 工具的 repo——不是 meta-harness 本身。 |
| **builder** | 用 meta-harness 顧問身分**設計** target 的工程師。看這份 README 的就是你。 |
| **human** | 每天**用** target 的人。可能跟 builder 同人，也可能不同（如會計助理 vs 系統工程師）。 |
| **viewer** | manual-template 用語，幾乎等同 human——說明書服務的對象。 |
| **顧問身分** | meta-harness 內的 Claude Code session 載入 `consultant` skill 後扮演的角色。建築師人格、不可漂移。 |
| **prescription（設計圖）** | 顧問動手前寫的設計圖文檔（落在 `prescriptions/<date>-<target>.md`）。給建築師看的。 |
| **manual（說明書）** | `/document` 產給 target 對外的 README + CONTRIBUTING。給 viewer / 維護者看的。 |
| **設計軸 / 軸 N** | 13 條設計參數（Tool / Context / Memory / ...）。每條是參數空間、不是開關。 |
| **R-N（universal-care-rules）** | 12 條跨 target 的衛生規則（R-1 CLAUDE.md ≤ 50 行、R-10 自驗紀律、R-12 self-containment 等）。 |
| **wiring** | 把 hook／skill／command／settings 等元件「串成行為」的整體連線。 |
| **mechanism** | 顧問語境下 = 一條 wiring 的具體做法（不是檔案，是行為）。 |
| **anti-scope** | 明確「不該做」的清單。Step 1 訪談必問。 |
| **飛輪（retrospective）** | target 跑一陣子後回看進化——4 項檢視：outcome→skill 沉澱、訊號累積看反饋、memory 形狀、方法學缺口。 |
| **dog food** | 自己用自己的方法（如 meta-harness 用自己的軸 13 自驗自身）。 |
| **headless（自驗）** | `claude -p` 非互動模式跑 ≥ 3 次 + 機器評分，Step 4.5 要求。 |
| **drift** | wiring 與設計圖／真實來源不一致。軸 13 自驗的偵測對象。 |

業界術語（hook / skill / slash command / CLI / DDD / TDD / Pattern 等）不在此處列——peer 受眾預設懂。

---

## Repo 結構

```
.claude/
  hooks/                    顧問自身的 hook（cwd 守衛、CLAUDE.md 行數檢查、提問自查為 advisory 提醒；self-verify-on-stop 為唯一 blocking）
  skills/consultant/        顧問身分 skill（核心，所有 command 進去都載入）
  skills/document/          /document skill
  commands/                 design / healthcheck / retro / document 四個前門（document 是薄前門，主邏輯在 skill）
  settings.json             hook 註冊（含軸 13 Stop hook）
docs/
  getting-started.md        新手入口
  consultant-flow.md        顧問決策邏輯
  design-axes.md            13 設計軸索引
  design-axes/              每設計軸深度（含 13-self-verify-coverage.md）
  universal-care-rules.md   R-1~R-12 衛生規則
  prescription-template.md  設計圖格式（內含「軟體工程紀律映射」節：Strategy/Specification/Middleware/...）
  manual-template.md        說明書格式
  lessons.md                實戰教訓
experiments/
  meta-harness-eval/        meta-harness 自身的軸 13 落地（runner / test-*.sh scorer 組 / coverage.json）
  consolidation-loop/       自驗 loop 的 reference 實作
targets.yml.example         target 清單範本（cp 成 targets.yml）
─── 以下 gitignored（各 fork 自家內容，不上 git）───
targets.yml                 你本機的 target 清單
sessions/                   訪談紀要
prescriptions/              設計圖留痕
cases/                      任務性案例庫
experiments/*/runs/         自驗 raw 證據
BACKLOG.md                  未消化的失敗 / 缺口清單
```

---

## Status

**v0.5 — 軸 13 自驗覆蓋率 + 軟體工程方法學映射**

- ✅ **13 設計軸完整**（v0.5 新增「Self-Verify Coverage」——R-10 從紀律升級成可量化的 KPI + 物理閘門）
- ✅ universal rules R-1~R-12（R-11 雙語說明書、R-12 target self-containment）
- ✅ Consultant skill 鎖建築師身分 + 6 步流程
- ✅ `/document` skill（雙語 README + CONTRIBUTING 自動產出）
- ✅ Memory 多軸分類 + Plan-as-memory + Outcome-as-skill 雙向飛輪
- ✅ meta-harness 自身落地軸 13（以自身 scorer 組自驗、分母機器推導；即時數字見 `coverage.json`）
- ✅ atdd-task 首個外部 target 落地軸 13（自帶 scorer 組與 coverage.json）
- 🔄 跨 target 推廣中（ai-infra-management / figma2code / self-profile / google_sheet_builder 待補軸 13）

---

## License

MIT
