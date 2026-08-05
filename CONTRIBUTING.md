---
layout: page
eyebrow: 給維護者
---

> 🌐 **繁體中文** | [English](CONTRIBUTING.en.md)

# 擴充 meta-harness 這套方法

這份文件是給要擴充這套方法本身的人看的：加一個設計面向、加一條規則、記下教訓、加一種模式或 skill。

只是想用這套流程設計你自己的 harness，看 [`README.md`](./README.md)。這裡講的是這套方法的架構，以及怎麼動它。

兩種讀者分開寫，meta-harness 自己也吃這套規矩：README 給使用這套流程的人，這份給改這套框架的人。

---

## 架構概覽

meta-harness 不是 framework。它是一個顧問角色、一份手法清單、加上一段對話流程。分成四層：

```
角色層    .claude/skills/consultant/SKILL.md     顧問角色和六步流程，不可以跑掉
          .claude/skills/document/SKILL.md       產雙語說明書

知識層    docs/design-axes/                      13 個設計面向，這是選項空間
          docs/universal-care-rules.md           R-1 到 R-12，基本規則的最低標準
          docs/prescription-template.md          設計方案的格式，含對應軟體工程做法那節
          docs/manual-template.md                說明書的格式
          docs/lessons.md                        累積的心得，不一定會升級成規則

入口層    .claude/commands/                      design / healthcheck / retro / document 四個指令
          .claude/hooks/                         工作目錄守衛、行數檢查、提問前自查（三個只提醒），
                                                 加上 self-verify-on-stop（唯一會擋下來的）

驗證層    experiments/meta-harness-eval/         meta-harness 自己的自我驗證
          ├── run-self-verify.sh                 單一入口，跑完所有 test-*.sh
          ├── test-*.sh                          各項驗證腳本
          ├── coverage.json                      數據面板，即時數字以這個檔為準
          └── generate-coverage.sh               從測試結果產生 coverage.json
```

幾件要先理解的事：

13 個設計面向是選項空間，不是檢查表，而且彼此牽連。

R-1 到 R-12 是跨專案的最低標準。它們是成文的規則，落實的機制以 hook 提醒為主，只有 Stop hook 真的擋得住。

`docs/lessons.md` 記的是心得，也就是「為什麼這樣設計」。它跟規則的差別在於：規則是強制的，心得是經驗。

### 自己用自己的方法，是三層閉環

```
atdd-task 通過自己的自驗（自帶驗證腳本，即時數字見它的 coverage.json）
    ↑ 這是 meta-harness 規定的
meta-harness 規定目標專案要自驗
    ↑ 也規定自己得自驗
meta-harness 通過自己的自驗（數字見 coverage.json，由 generate-coverage.sh 維護）
    ↑ 這件事規定在
這份 CONTRIBUTING（meta-harness 寫給自己維護者的文件）
```

「鞋匠的孩子有鞋穿」在這裡是可以驗證的工程事實，不是比喻。

---

## 各元件在做什麼

| 元件 | 做什麼 |
|---|---|
| `.claude/skills/consultant/` | 顧問角色和完整的六步流程。這是核心，所有模式進去都會載入 |
| `.claude/skills/document/` | `/document` 的邏輯，自動產出雙語 README 和 CONTRIBUTING |
| `.claude/commands/{design,healthcheck,retro,document}.md` | 給目標專案用的四個指令入口 |
| `.claude/commands/upkeep.md` | 維護 meta-harness 自己用的。人隔一段時間沒來之後，跑一輪保鮮：自驗、重算專案清單和覆蓋率、檢查待辦有沒有放太久，最後給一份健康摘要。建議每週跑一次 |
| `.claude/hooks/cwd-guard.sh` | session 開始時檢查工作目錄有沒有離開 meta-harness。只印警告，不擋 |
| `.claude/hooks/post-write-line-check.sh` | 寫檔之後檢查 CLAUDE.md 和 hook 的行數有沒有超標。只提醒，不擋 |
| `.claude/hooks/pre-askquestion-reminder.sh` | 問問題之前提醒自查 R-5 和 R-6。只提醒，不擋 |
| `.claude/hooks/self-verify-on-stop.sh` | 唯一會擋下來的 hook。session 結束時跑完整套自驗，發現對不上就 exit 2 擋住 |
| `.claude/settings.json` | hook 的註冊。總共一個會擋的，三個只提醒的 |
| `docs/*-template.md` | 設計方案和說明書的格式 |
| `experiments/<主題>/` | 參考實作，例如 `consolidation-loop/` |
| `experiments/meta-harness-eval/` | meta-harness 自己的自我驗證，也是自己用自己方法的證據 |

---

## 怎麼擴充

### 加一個設計面向

1. 建 `docs/design-axes/<編號>-<名稱>.md`，寫清楚有哪些選項、跟其他面向怎麼牽連、常見的錯誤做法、實際案例。
2. 在 `docs/design-axes.md` 的索引加一條。
3. 把 `docs/design-axes.md` 標題裡的總數加一。
4. 更新 `.claude/commands/healthcheck.md` 裡引用的數字。自驗會抓這兩處對不對得上。
5. 確認它不跟現有的重疊。第 7 和第 11、第 9 和第 12 的界線已經劃清楚了，可以參考。

跑 `bash experiments/meta-harness-eval/run-self-verify.sh`，應該要全過。

### 加一條規則

1. 在 `docs/universal-care-rules.md` 加一個 `## R-N：<名稱>` 段落，寫清楚它在講什麼、為什麼、規則是什麼、怎麼落實。
2. 判斷標準是：離開這個專案、離開這個人，這條還成立嗎？跨得過去才收進通用規則。只跟某個專案有關的，留在那個專案自己的文件裡。
3. commit message 一定要回答「為什麼不能把源頭刪掉」。這是 R-7 的紀律：不要固化壞流程，先修根本原因。
4. 跑自驗，`test-universal-care-rules-schema.sh` 會檢查編號連續、每條都有內容。

### 記一條教訓

踩到反覆出現的失誤，寫進 `docs/lessons.md`。那是心得，不是強制規則。

累積驗證過、確認夠普遍之後，才升級成規則。

### 加一種模式或 skill

照著 `document` skill 的樣子做：

1. 建 `.claude/skills/<名稱>/SKILL.md`，frontmatter 的 `name` 和 `description` 必填。
2. 在 consultant skill 的觸發表加一列。
3. 需要的話掛進六步流程裡。
4. 在 `.claude/commands/<名稱>.md` 加一個對應的指令入口。
5. 自驗時 `test-skill-spec-format.sh` 和 `test-slash-command-flow-integrity.sh` 會檢查 frontmatter 和引用有沒有對上。

### 改設計方案或說明書的格式

直接編 `docs/prescription-template.md` 或 `docs/manual-template.md`。

跑自驗，`test-prescription-template-structure.sh` 會檢查結構還在（Header、Part A 到 F、模板使用守則）。

---

## 為什麼這樣設計

**為什麼是顧問，不是產目錄骨架的工具。** 13 個面向是互相牽連的參數，沒有一組模板對所有人都剛好。所以主體是對話加上手法清單。

**為什麼規則要分層擺放。** 這是為了避免出現「一份文件裡有 13 條互不連貫的錯誤做法」那種狀況。跨流程的通則、設計流程、方案格式、錯誤做法，各放各的地方。

**為什麼要把 R-10 變成擋得住的機制。** R-10 說「機器驗得了的產出，交付前先自己驗過」，原本只是一條紀律。現在升級成自動擋關：Stop hook、coverage.json、run-self-verify.sh 三個檔案。這樣「沒自驗就不准 commit」變成作業系統層級的事實，不靠人記得。

**為什麼寫進目標專案的檔案要能獨立看懂。** 目標專案是獨立的 repo，它的讀者手上沒有 meta-harness。

但這條（R-12）對 meta-harness 自己不適用。設計方案、設計面向、規則編號，就是 meta-harness 內部的共通語言，本來就該講。

### 改這套方法之前必讀的四條

- **R-7**：不要固化壞流程，修東西先找根本原因。疊上去蓋住症狀，最後會變成一堆規則。
- **R-8**：不要跨層越權。方法層的規則不要寫進針對特定專案的文件。
- **R-9**：框架歸框架，任務內容歸任務內容。meta-harness 動框架，不動目標專案的業務邏輯。
- **R-12**：寫進目標專案的檔案要能獨立看懂。這條對 meta-harness 自己不適用，但你要改 R-12 或 `/document` skill 的時候，要懂這條的目的。

---

## 怎麼驗證你的改動

### 跑自驗

跑 `bash experiments/meta-harness-eval/run-self-verify.sh`，必須全部通過。

任何一支紅的，就表示有東西對不上。Stop hook 會擋住 session 結束，直到修好為止。

驗證腳本涵蓋的範圍大致如下。完整清單和即時數字看 `coverage.json`，下表只是子集：

| 驗證腳本 | 涵蓋什麼 |
|---|---|
| `test-cross-references.sh` | 設計方案裡引用的規則編號和面向編號是否都存在 |
| `test-prescription-format.sh` | 各份設計方案的結構 |
| `test-prescription-template-structure.sh` | 方案格式本身的結構 |
| `test-target-coverage.sh` | targets.yml 和各專案 coverage.json 的落地進度 |
| `test-design-axes-doc-completeness.sh` | 13 個設計面向的文件結構完整 |
| `test-healthcheck-axis-consistency.sh` | healthcheck 引用的數字跟實際檔案數一致 |
| `test-skill-spec-format.sh` | SKILL.md 的 frontmatter |
| `test-universal-care-rules-schema.sh` | 規則編號連續、每條都有內容 |
| `test-self-verify-stop-hook-behavior.sh` | Stop hook 在三種情況下的行為：沒有入口、通過、失敗 |
| `test-run-self-verify-runner-integrity.sh` | 入口腳本在三種狀態下的行為 |
| `test-slash-command-flow-integrity.sh` | 指令的 frontmatter，以及引用的檔案是否真的存在 |
| `test-consultant-skill-structure.sh` | 顧問角色的核心用詞是否完整 |
| `test-coverage-json-schema.sh` | 跨專案的 coverage.json 格式一致 |

加了新設定就加一支新的 `test-*.sh` 蓋住它。寫的時候挑四種驗法之一（細節見設計面向 13 的文件）：

- **A. 比對設定是否一致**：同一份設定散在多個檔案時。
- **B. 觸發後看有沒有反應**：hook 或中介機制有沒有被正確叫起來。
- **C. 跑分評輸出品質**：agent 產出的內容。
- **D. 比對前後差異**：副作用對不對。

### 新能力一定要先自己用過

任何新的 skill、指令、格式，都要先拿真實的專案跑一遍。

例如 `/document` 是先拿 figma2code 試，才用來寫自己的文件；自我驗證是先在 meta-harness 自己身上做起來，才推給 atdd-task。

沒有自己先用過就交付，等於交出一個沒驗過的成品，那正是 R-10 要防的事。

### 改規則或加面向時的檢查

- **先 grep 找根本原因。** 不要只疊上去蓋住症狀（R-7）。
- **確認不重疊。** 第 7 和第 11、第 9 和第 12 的界線已經劃清；面向 13 和 R-10 的分工是「指標」對上「紀律」。
- **跨專案試過。** 要升成通用規則之前，先在至少兩個真實專案上驗證它夠普遍。不然就先放進 `docs/lessons.md`。
- **commit message 要回答 R-7 的自問。** commit 之前先回答「為什麼不能刪源頭，只能加規則」。

### 改完格式之後

跑自驗，看 `test-prescription-template-structure.sh` 還是綠的。

如果你改的是 Part A 到 F 以外的結構（例如加了 Part G），要同步更新那支測試的預期。

---

## 跟外部專案的關係

meta-harness 設計出來的目標專案是獨立的 repo。它應該能自己站著，不需要 meta-harness 才跑得起來。

R-12 規範的就是這件事：寫進目標專案的檔案不要洩漏 meta-harness 的內部身分，不要在它的 README 裡提設計方案、設計面向、規則編號這些內部行話。

但這個關係是單向的：目標專案不該知道 meta-harness，而 meta-harness 知道並且追蹤各個目標專案，靠的是 `targets.yml` 和 `test-target-coverage.sh`。

各專案的自驗落地進度是即時變動的，這裡不手抄。要看現況就跑：

```bash
bash experiments/meta-harness-eval/test-target-coverage.sh
```

要推一個新專案做起自我驗證，流程是：

1. 在那個專案建 `experiments/<專案>-eval/run-self-verify.sh`，可以複用 meta-harness 的可攜版本。
2. 加 `.claude/hooks/self-verify-on-stop.sh`，並在 `settings.json` 註冊到 `Stop`。
3. 對那個專案的各項設定各寫一支 `test-*.sh`，照四種驗法挑一種。
4. 跑 `generate-coverage.sh` 產生 `coverage.json`，設計者手動填上項目總數的清單。
5. 在 meta-harness 的 `targets.yml` 裡，那個專案的條目加上 `eval_dir`，如果它的目錄名不是 `<專案>-eval` 的話。
6. 跑 `test-target-coverage.sh`，應該要抓得到新的進度。
