---
layout: page
eyebrow: Maintainer Guide
---

> 🌐 **繁體中文** | [English](CONTRIBUTING.en.md)

# 擴充 meta-harness 方法學

給**擴充這套顧問方法學本身**的人（加設計軸、加規則、沉澱教訓、加 skill）。
想「用」這套流程設計你的 harness 看 [`README.md`](./README.md)；這裡講**方法學的架構與怎麼動它**。

> 兩種讀者分流（meta-harness 自己就吃這套）：README = 使用顧問流程的人（Viewer）；本檔 = 改顧問框架的人（Maintainer）。

---

## 架構概覽

meta-harness 不是 framework，是「**顧問身分 + pattern library + 對話流程**」。三層構成：

```
身分層    .claude/skills/consultant/SKILL.md     建築師人格 + 6 步流程（不可漂移）
            .claude/skills/document/SKILL.md       /document 模式（雙語說明書產出）

知識層    docs/design-axes/ (13 軸)              設計參數空間（含軸 13 Self-Verify Coverage）
            docs/universal-care-rules.md (R-1~R-12) 衛生規則 floor
            docs/prescription-template.md          設計圖格式（含「軟體工程紀律映射」節）
            docs/manual-template.md                說明書格式
            docs/lessons.md                        洞察累積（未必升 R-N）

前門層    .claude/commands/                      design / healthcheck / retro / document 四個 slash command
            .claude/hooks/                         cwd 守衛 + 行數 / 提問自查提醒（3 advisory）+ self-verify-on-stop（1 blocking）

自驗層    experiments/meta-harness-eval/         meta-harness 自身軸 13 落地
            ├── run-self-verify.sh                 單一 entry point（13 scorer / 216 check）
            ├── test-*.sh                          各 Pattern A/B 的 scorer
            ├── coverage.json                      KPI 面板（覆蓋率 100%）
            └── generate-coverage.sh               從 test 結果生成 coverage.json
```

- **13 設計軸** = 設計**參數空間**（不是 checklist），彼此耦合。
- **R-1~R-12** = 跨 target 的衛生 floor（成文規則；落地機制以 hook 提醒為主，僅 Stop hook 具 blocking 能力）。
- **`docs/lessons.md`** = 洞察（為什麼這樣設計），和 rules 區別：rules 是強制、lessons 是經驗。

### dog food 三層閉環（meta-harness 自己證明方法學成立）

```
atdd-task 過自己自驗（7 scorer / 58 check）
    ↑ 規定
meta-harness（規定 target 自驗）
    ↑ 規定自己也得自驗
meta-harness 過自己自驗（13 scorer / 216 check / 100% 覆蓋）
    ↑ 規定 prescription 結構
本份 CONTRIBUTING（meta-harness 寫給自己的維護者文件）
```

「鞋匠的孩子有鞋穿」這句是**可驗證的工程事實**，不是比喻。

---

## wiring 怎麼運作

| 元件 | 做什麼 |
|---|---|
| `.claude/skills/consultant/` | 顧問身分 + 完整 6 步流程（核心，所有模式進去都載入）|
| `.claude/skills/document/` | `/document` 模式邏輯（雙語 README + CONTRIBUTING 自動產出）|
| `.claude/commands/{design,healthcheck,retro,document}.md` | 四個前門 slash command |
| `.claude/hooks/cwd-guard.sh` | SessionStart：守住 cwd 不離開 meta-harness（**advisory**，只印警告、不擋）|
| `.claude/hooks/post-write-line-check.sh` | PostToolUse(Write/Edit)：R-1（CLAUDE.md 行數）/ R-3（hook 行數）超標時提醒（**advisory**，不擋）|
| `.claude/hooks/pre-askquestion-reminder.sh` | PreToolUse(AskUserQuestion)：R-5（提問錨 artifact）/ R-6（不用未解釋專有名詞）自查提醒（**advisory**，不擋）|
| `.claude/hooks/self-verify-on-stop.sh` | Stop：**唯一 blocking hook**——session 結束跑全棧自驗，drift exit 2 擋住（軸 13 物理閘門）|
| `.claude/settings.json` | hook 註冊（SessionStart / PreToolUse / PostToolUse / Stop）——**1 blocking（Stop）+ 3 advisory（提醒但不擋）** |
| `docs/*-template.md` | prescription（設計圖）+ manual（說明書）格式 |
| `experiments/<topic>/` | reference 實作（如 `consolidation-loop/`）|
| `experiments/meta-harness-eval/` | **meta-harness 自身的軸 13 落地**——dog food 證據 |

---

## 怎麼擴充

### 加設計軸

1. 建 `docs/design-axes/<n>-<name>.md`（決策選項 + 耦合 + 反模式 + 案例）
2. 在 `docs/design-axes.md` 索引加一條
3. 升 `# Harness <N> 大設計軸（索引）` 標題的數字
4. 更新 `.claude/commands/healthcheck.md` 的軸數引用（自驗會抓 drift）
5. **正交檢查**：別跟現有 13 軸重疊（如 7 vs 11、9 vs 12 的邊界已劃清）

跑 `bash experiments/meta-harness-eval/run-self-verify.sh` → 應全綠（test-healthcheck-axis-consistency 會抓軸數對齊）。

### 加 universal rule（R-N）

1. 在 `docs/universal-care-rules.md` 加 `## R-N：<name>` section（定義 / 為什麼 / 規則 / 落地）
2. **判準**：**離開這個 target / 這個人還成立嗎**？跨 target 才入 universal；target-specific 留 target 自己 doc
3. commit message 必答「**為什麼不能刪源頭**」（R-7 紀律——不固化壞流程、fix root cause）
4. 跑自驗 → `test-universal-care-rules-schema.sh` 驗 R-N 編號連續 + 內容完整

### 加教訓（lesson）

踩到反覆失誤 → 寫 `docs/lessons.md`（洞察，**非強制規則**）。累積驗證夠普世 → 升 R-N。

### 加模式 / skill

仿 `document` skill：

1. 建 `.claude/skills/<name>/SKILL.md`（frontmatter `name:` + `description:` 必填）
2. 在 consultant skill 的觸發表加一列
3. 必要時掛進 6 步流程（如 Step 5.5 / Step 6）
4. 加對應 slash command 在 `.claude/commands/<name>.md`（前門）
5. 自驗會被 `test-skill-spec-format.sh` + `test-slash-command-flow-integrity.sh` 抓 frontmatter / 引用對齊

### 改 prescription / manual template

直接編 `docs/prescription-template.md` 或 `docs/manual-template.md`。跑自驗 → `test-prescription-template-structure.sh` 驗結構（Header + Part A-F + 模板使用守則 都還在）。

---

## 設計依據（為什麼這樣）

- **顧問而非腳手架**：13 軸是耦合參數，沒有對誰都剛好的標準模板 → 對話 + pattern library 為主體。
- **規則分層**（避免「一份文件 13 條互不連貫的反模式」）：跨流程通則（R-N）/ 設計流程（consultant-flow）/ 設計圖格式（template）/ 反模式 分開放。
- **R-10 物理化（軸 13）**：R-10「可機驗 outcome 必先自驗再交付」原本是紀律，現在升級成**物理閘門**——Stop hook + coverage.json + run-self-verify.sh 三件套。所以「沒自驗不准 commit」變成 OS 級事實，不靠人記得。
- **R-12 self-containment**（target 落地檔不洩漏 meta-harness 身分）：target 是獨立 repo、它的讀者沒有 meta-harness。但 **R-12 對 meta-harness 自身不適用**——prescription / 設計軸 / R-N 是 meta-harness 的 ubiquitous language，本該講。

### 治理四條（改方法學前必讀）

- **R-7**：不固化壞流程、fix 先 root cause（疊蓋症狀 = 規則膨脹陷阱）
- **R-8**：不跨層越權（method-level 規則別寫進 target-specific 文件）
- **R-9**：framework vs 任務內容分流（meta-harness 動 framework、不動 target 業務邏輯）
- **R-12**：target 落地檔 self-contained（**不適用 meta-harness 自身**，但你改 R-12 / `/document` skill 時要懂這條的目的）

---

## 怎麼驗證改動

### 軸 13 自驗（OS 級閘門）

跑 `bash experiments/meta-harness-eval/run-self-verify.sh` → **必須 13/13 全綠**。

任一支紅 = drift。Stop hook 會擋住 session 結束（除非 drift 修掉）。

13 支 scorer 涵蓋的 mechanism：

| Scorer | 覆蓋 |
|---|---|
| `test-cross-references.sh` | prescription 引用 R-N / 軸 N 完整性 |
| `test-prescription-format.sh` | prescriptions 結構（Part A-F + frontmatter）|
| `test-prescription-template-structure.sh` | template 自身結構 |
| `test-target-coverage.sh` | targets.yml ↔ target coverage.json 落地進度 |
| `test-design-axes-doc-completeness.sh` | 13 設計軸文件結構齊 |
| `test-healthcheck-axis-consistency.sh` | healthcheck 引用軸數 ↔ 實際 |
| `test-skill-spec-format.sh` | SKILL.md frontmatter |
| `test-universal-care-rules-schema.sh` | R-N 編號連續 + 內容存在 |
| `test-self-verify-stop-hook-behavior.sh` | Stop hook 三種行為（無 runner / 綠 / 紅）|
| `test-run-self-verify-runner-integrity.sh` | runner 三種狀態（無 test / 全綠 / 紅）|
| `test-slash-command-flow-integrity.sh` | slash command frontmatter + 引用檔實存 |
| `test-consultant-skill-structure.sh` | 顧問核心 vocab 完整 |
| `test-coverage-json-schema.sh` | 跨 target coverage.json schema 一致 |

加新 wiring → 加新 `test-*.sh` 蓋它。**寫 scorer 用四 Pattern 之一**（見軸 13 文件）：

- **A. 單一真實來源 + drift 偵測**（配置 / wiring 跨檔一致性）
- **B. 觸發 + 斷言**（hook / 中介機制接收正確 trigger）
- **C. Scorer + METRICS 行**（行為品質 / agent 輸出）
- **D. 快照 + Diff**（副作用是否正確）

### dogfood（任何新能力先實彈跑）

任何新 skill / command / template 先拿真實 target 跑一遍（如 `/document` 先寫 figma2code 再寫自己；軸 13 先在 meta-harness 自身落地再推 atdd-task）。**不 dogfood 就交付 = 未驗成品（R-10 反模式）**。

### 改規則 / 加軸的衛生檢查

- **grep root cause**：別只疊蓋症狀（R-7）。
- **正交確認**：別跟現有軸 / R-N 重疊（如 7 vs 11、9 vs 12 邊界已劃清；軸 13 vs R-10 是「KPI vs 紀律」分層）。
- **跨 target 試**：升 universal 前先在 ≥ 2 個真實 target 驗證該規則普世（不然落 `docs/lessons.md`）。
- **commit message R-7**：commit 前自答「為什麼不能刪源頭、只能加規則」。

### 改 prescription / template 後

跑自驗看 `test-prescription-template-structure.sh` 仍綠。若改了 Part A-F 之外的結構（如加 Part G），要同步更新該 test 的期望。

---

## 與外部 target 的關係

meta-harness 設計出來的 target 是**獨立 repo**——它應該能 self-contain，不依賴 meta-harness 才能 run。R-12 規範「target 落地檔不洩漏 meta-harness 身分」（不在 target README 提 `prescription / 設計軸 / R-N` 等內部 jargon）。

但**這個關係是單向的**：target 不該知道 meta-harness，meta-harness 知道並追蹤 target（透過 `targets.yml` + `test-target-coverage.sh`）。

跨 target 的 dog food 進度由 `experiments/meta-harness-eval/test-target-coverage.sh` 持續監測：

| Target | 軸 13 落地 |
|---|---|
| meta-harness 自身 | ✅ 100%（15/15）|
| atdd-task | ✅ 47%（7/15）|
| ai-infra-management | ⏳ 待補 |
| figma2code | ⏳ 待補 |
| self-profile | ⏳ 待補 |
| google_sheet_builder | ⏳ 待補 |

推一個新 target 落地軸 13 的流程：

1. 在 target 建 `experiments/<target>-eval/run-self-verify.sh`（複用 meta-harness portable 版）
2. 加 `.claude/hooks/self-verify-on-stop.sh` + `settings.json` Stop 註冊
3. 對 target 的 wiring 各寫 `test-*.sh`（依四 Pattern）
4. 跑 `generate-coverage.sh` 產 `coverage.json`、builder 手填 `mechanisms_inventory`
5. 在 meta-harness `targets.yml` 該 target 條目加 `eval_dir`（若目錄名 ≠ `<target>-eval`）
6. 跑 `meta-harness/experiments/meta-harness-eval/test-target-coverage.sh` 應抓到落地進度
