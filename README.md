> 🌐 **繁體中文** | [English](README.en.md)

# meta-harness

> **設計 AI agent harness 的方法論 + 顧問 wiring。**
> Prompt engineering 是改字；harness engineering 是改「模型周圍的整套系統」。
> 適用任何實作介質——bash 腳本、web app、SaaS、hybrid 產品，只要裡面有 AI agent 就適用。

---

## 1. 這是什麼？能做什麼？

`meta-harness` 是一位住在 Claude Code 裡的「**AI agent 系統設計顧問（建築師）+ 實作器**」。

你不會「執行」這個專案——你**進到它的目錄、開一個 Claude Code session**，它就變成一位懂工法、懂最佳實踐的建築師，陪你把某個 AI agent 工具（我們稱為 **target repo**，目標專案）設計好、蓋出來。

```
業主提需求  →  顧問出設計圖  →  你 review  →  顧問把檔案實作進你的 target repo  →  驗收
```

它**不是** framework、不是 CLI 工具、不是腳手架產生器。它是一套**對話流程 + 一個內建 12 大設計軸 pattern library 的顧問身分**。

### 它能幫你做三類事

| 你想做的事 | 用哪個模式 | 產出 |
|---|---|---|
| **新建或重新設計**一個 AI agent 工具的「骨架」（要不要 hook？要 sub-agent 還是 skill？memory 怎麼存？） | `/design` | 一份設計圖 + 直接寫進你 target repo 的 wiring 檔案 |
| **健檢**一個既有系統，用 12 設計軸當鏡子找缺口、找反模式 | `/healthcheck` | 一份 12 軸對照健檢報告 |
| **回顧**一個已經跑了一陣子的系統，看它該怎麼進化 | `/retro` | retrospective 紀要 + 行動建議 |

### 為什麼是「顧問」而不是「腳手架」？

最初的直覺是做 `meta-harness new <domain>` 產出一套標準目錄。但 12 設計軸每一條都是**設計參數**而非開關，而且彼此耦合，沒有一組對誰都剛好的標準搭配。所以這裡採顧問模式：對話 + pattern library + 設計圖為主體，腳手架降級為顧問結論的編譯產物。

---

## 2. 安裝與前置

### 前置條件

- **Claude Code CLI** 已安裝（終端機能跑 `claude --version`）。這是唯一的硬需求。
- 你心裡有一個想設計的 target repo（**不需要已經存在**——只要能講出「想做什麼」就行）。

> **沒有 `.env`、不需要 API key 檔。** 這個專案本身不連任何外部服務、不存任何密鑰——它的「執行環境」就是 Claude Code 本身。唯一的本機設定檔是下面的 `targets.yml`，純粹是給你自己記錄 target 清單用的，**選用、不強制**。

### 取得專案

```bash
git clone <this-repo> ~/meta-harness
cd ~/meta-harness
```

### （選用）建立你的 target 清單

```bash
cp targets.yml.example targets.yml      # targets.yml 已被 gitignore，不會上傳
```

`targets.yml` 讓你記錄本機有哪些 target repo、各自的路徑與狀態（concept / pending-audit / audited）。開 session 時可以從這份挑一個，也可以完全略過、直接在對話裡告訴顧問 target 的絕對路徑。

---

## 3. 怎麼用（步驟）

### 開一個 session

開 session 跑設計工作前，**建議先 `/model` 切到最強的 model**——設計、推理、方法學任務的思考品質不能弱（弱 model 容易堆砌術語牆、給出反模式、留邏輯漏洞）。AI 不能切自己的 model，這是設計者要主動做的一步。

```bash
cd ~/meta-harness
claude
```

進去後，用 **slash command 當前門**選模式，或直接講白話（`consultant` skill 會自動載入）：

| Command | 白話講法 | 何時用 |
|---|---|---|
| `/design <target 絕對路徑>` | 「我想設計 / 重新設計 ~/my-project」 | 新建或重設一個 harness |
| `/healthcheck <target 絕對路徑>` | 「健檢 ~/my-project」 | 既有系統定點體檢、找缺口（冷啟動就能做） |
| `/retro <target 絕對路徑>` | 「回顧 ~/my-project」 | target 跑一陣子後回看進化 |
| （不打 command） | 「繼續上次 X 的設計」 | 接續上次未完的 session |

> command 只是「可被發現的前門」——進去之後一律走顧問對話，**不是填表單、不是腳手架**。

### 設計流程：6 步（`/design` 走完整流程）

```
Step 1  需求訪談（你 + 顧問，10–20 分鐘）
        顧問先請你介紹專案，再用按鈕選擇題問 5 件事：
        使命/痛點、現有形狀、anti-scope（不該做什麼）、失敗 floor + 壽命、human 領域熟悉度
        → 產出「12 設計軸 stakes 篩選表」（哪些軸要全力設計、哪些 N/A）

Step 2  建築師獨自出設計圖（你不用做事）
        顧問寫 prescriptions/<date>-<target>.md，完成後把重點摘要貼給你看

Step 3  你 review，反覆收斂
        你給白話文字回饋 → 顧問改設計圖 → 再給你看（不是選擇題）

Step 4  分期實作落地
        prescription 拆成 Stage 1/2/3，逐期把檔案寫進你的 target repo（用絕對路徑）

Step 4.5 自驗 loop（強制）
        任何「可機器驗證」的產物（slash command / skill / pipeline），
        顧問必須先 headless 跑 ≥ 3 次 + 機器評分，通過了才交給你，不准肉眼瞄一眼說 OK

Step 5  驗收
        顧問代跑能自動驗的（檔案存在、hook 真被觸發、權限對齊）；
        你做跨 session 的實際試用

Step 6  飛輪 retrospective（數週後）
        target 跑一段時間後回看：要不要把反覆手做的動作沉澱成 skill？
        memory 形狀健不健康？暴露的反覆失誤該不該升級成方法學？
```

> 第一次用通常只跑到 Step 3 或 4，Step 5–6 視需要。健檢（`/healthcheck`）與回顧（`/retro`）是獨立模式，不走完整 6 步。

### 兩種角色：Builder vs Human

meta-harness 設計出來的 target repo 服務兩種人（可能同人也可能不同人），設計時必須區分：

- **Builder**：用 meta-harness 顧問身分**設計**這個 target repo 的工程師（就是看這份 README 的你）。
- **Human**：每天跑 target repo 指令、看結果做決定的人——**未必是該領域的專家**（例：會計系統的 human 可能是會計助理而非工程師）。

設計軸 12「Human Interface」就是專門設計給 human 的介面層（翻譯、粒度、回饋通道），對稱於設計軸 9「Observability」（給工程師 / 系統看）。Builder 看得懂術語、human 未必——這是設計時的硬區分。

---

## 4. 會產生哪些檔案 / 需要哪些檔案

### 你需要準備的檔案

| 檔案 | 必要？ | 說明 |
|---|---|---|
| `targets.yml` | **選用** | 你的本機 target 清單。`cp targets.yml.example targets.yml` 後自行編輯。已 gitignore。 |
| `.env` | **不需要** | 這個專案不用 `.env`、不需任何 API key 檔。執行環境＝Claude Code 本身。 |

### Session 過程中會產生的檔案

這些都是顧問在 session 裡幫你建立的「留痕」，**全部已 gitignore**（含真實 PII / infra ID / 業主對話，不該上傳；各人 fork 自己的任務不互相污染）：

| 路徑 | 內容 |
|---|---|
| `sessions/<date>-<topic>.md` | 每次需求訪談的紀要（5 段答案 + 設計軸篩選表） |
| `prescriptions/<date>-<target>.md` | 顧問動手前的設計圖 / audit trail（「打算改什麼、為什麼」） |
| `cases/` | 特定 target 蒸餾出的案例（他人 fork 不該看到別人的任務） |
| `experiments/<target>-<topic>/runs/` | Step 4.5 自驗 loop 跑出的 raw 證據（含 target 真實 ID） |
| `BACKLOG.md` | 你自己「踩到的規則 / 方法學缺口」未當場消化的清單 |

> 每個 gitignored 目錄都保留了一份入版控的 `README.md` 或結構檔（`gold.md` / `run.sh` / `eval.sh` / `prompts/`），讓 fork 拿到時知道該目錄怎麼用，但看不到別人的私密內容。

### 寫進「你 target repo」的檔案

Step 4 落地時，顧問會用**絕對路徑**把 wiring 檔案直接寫進你的 target repo（cwd 不離開 meta-harness）。寫什麼由設計圖決定，常見的有：`.claude/hooks/*.sh`、`.claude/skills/<name>/SKILL.md`、`.claude/commands/*.md`、`.claude/settings.json` 等。

---

## 5. 核心文件導覽

想深入了解顧問腦中的 pattern library，看這幾份：

| 文件 | 用途 |
|---|---|
| `docs/getting-started.md` | **新手入口**——30 分鐘內跑完第一次 Phase 0 |
| `.claude/skills/consultant/SKILL.md` | 顧問身分定義 + 完整 6 步流程（核心） |
| `docs/design-axes.md` | **13 大設計軸索引**（設計參數總覽） |
| `docs/design-axes/<n>.md` | 每條設計軸的深度選項 + 反模式 |
| `docs/universal-care-rules.md` | universal rules（R-1~R-12，顧問內建強制遵守的衛生規則） |
| `docs/prescription-template.md` | 設計圖格式（review 時對照） |
| `docs/manual-template.md` | 說明書格式（target 交付文件結構） |
| `docs/consultant-flow.md` | 顧問決策邏輯（Phase 0→1 重排機制） |
| `docs/lessons.md` | 實戰教訓 |

### 13 大設計軸

> Tool / Context / Memory / Planning / Execution / Safety / Hooks / Eval / Observability / Multi-agent / Triggers / Human Interface / **Self-Verify Coverage**

每一條都是「設計參數」而非開關，彼此耦合——這正是為什麼用顧問模式而非固定模板。

### 軸 13 自驗覆蓋率（self-verify coverage）

R-10「可機驗 outcome 必先自驗再交付」的**物理執行層 + KPI 化**。每個 target（包含 meta-harness 自身）落地三件套：

- `experiments/<target>-eval/run-self-verify.sh` — 單一 entry point，跑所有 test-*.sh
- `experiments/<target>-eval/test-*.sh` — 各 wiring 對應 scorer（依四 Pattern 寫）
- `experiments/<target>-eval/coverage.json` — 數據面板（scorers / check 總數 / mechanism 覆蓋率）
- `.claude/hooks/self-verify-on-stop.sh` + settings.json Stop 註冊 — drift 物理擋 session 結束

**四 Pattern 分類**（每支 test-*.sh 必歸屬其一）：

- **A. 單一真實來源 + drift 偵測**（配置 / wiring 跨檔一致性）
- **B. 觸發 + 斷言**（hook / 中介機制是否被正確 trigger）
- **C. Scorer + METRICS 行**（行為品質 / agent 輸出）
- **D. 快照 + Diff**（副作用是否正確）

落地參考：meta-harness 自身 30%（3/10）、atdd-task 47%（7/15）。詳見 `docs/design-axes/13-self-verify-coverage.md`。

---

## 6. Repo 結構

```
.claude/
  hooks/                    顧問 wiring 的 hook（cwd 守衛、行數檢查、提問自查、self-verify-on-stop）
  skills/consultant/        顧問身分 skill（核心）
  skills/{design,healthcheck,retro,document}/  四個模式前門
  commands/                 slash command 可發現入口
  settings.json             hook 註冊（含軸 13 Stop hook）
docs/
  getting-started.md        新手入口
  consultant-flow.md        顧問決策邏輯
  design-axes.md            13 設計軸索引
  design-axes/              每設計軸深度（含 13-self-verify-coverage.md）
  universal-care-rules.md   R-1~R-12 衛生規則
  prescription-template.md  設計圖格式
  manual-template.md        說明書格式
  lessons.md                實戰教訓
experiments/
  meta-harness-eval/        meta-harness 自身的軸 13 落地（runner / scorer / coverage.json）
  consolidation-loop/       自驗 loop 的 reference 實作（run.sh / eval.sh / prompts / gold）
targets.yml.example         target 清單範本（cp 成 targets.yml 使用）
─── 以下 gitignored（各 fork 自家內容，不上 git）───
targets.yml                 你的本機 target 清單
sessions/                   訪談紀要
prescriptions/              設計圖留痕
cases/                      任務性案例庫
experiments/*/runs/         自驗 raw 證據
BACKLOG.md                  未消化的失敗 / 缺口清單
```

---

## 7. Status

**v0.4 — Human Interface 設計軸 + 多軸 memory + 飛輪 retrospective**

- ✅ **12 設計軸完整**（v0.4 新增 Human Interface — human-facing IO 邊界，對稱設計軸 9 system-facing）
- ✅ universal rules R-1~R-11（R-8 跨層越權禁止；R-9 framework vs 任務內容分流；R-10 可機驗 outcome 必先自驗；R-11 可被他人使用必交付雙語說明書）
- ✅ Consultant skill 鎖建築師身分 + 完整 6 步流程
- ✅ Cwd-guard hook + R-1/R-3/R-5/R-6 enforce hook
- ✅ Memory 多軸分類（content type / scope / storage form / access pattern）
- ✅ Plan-as-memory + Outcome-as-skill 雙向飛輪
- 🔄 跨 target 驗證中（ai-infra-management v1 已實彈 + 多輪迭代回饋）

---

## License

MIT
