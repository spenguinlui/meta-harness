> 🌐 **繁體中文** | [English](README.en.md)

# meta-harness

設計 AI agent harness 的一套方法，外加一個會幫你把設計實作出來的顧問。

所謂 harness，指的是模型周圍的那一整套系統：工具怎麼給、上下文怎麼塞、記憶怎麼存、什麼時候該擋下來問人。改 prompt 是調字句，設計 harness 是調整整套系統。不管你用什麼做——bash 腳本、Web app、SaaS、混合型產品——只要裡面有 AI agent，這套方法都用得上。

---

## 1. 這是什麼

meta-harness 是一位住在 Claude Code 裡的顧問，專門幫你設計 AI agent 系統，也會動手實作。

你不會「執行」這個專案。你是進到它的目錄、開一個 Claude Code session，它就變成一位懂做法、懂常見陷阱的設計顧問，陪你把某個 AI agent 工具設計好、蓋出來。那個你要設計的專案，本文一律稱為「目標專案」。

流程大致是：你提需求，顧問出設計方案，你看過給意見，顧問把檔案寫進你的目標專案，最後驗收。

它不是 framework，不是 CLI 工具，也不是產目錄骨架的產生器。它是一段對話流程，加上一份內建的設計手法清單。

### 能幫你做四件事

**設計新工具，或重新設計現有的。** 要不要用 hook？該用 sub-agent 還是 skill？記憶怎麼存？用 `/design`，會給你一份設計方案，以及直接寫進你目標專案的設定檔。

**健檢現有系統。** 拿 13 個設計面向當鏡子，照出哪裡漏了、哪裡做錯了。用 `/healthcheck`，產出一份對照報告。

**回顧跑了一陣子的系統。** 看看接下來該怎麼調整。用 `/retro`，產出回顧紀要和行動建議。

**產對外文件。** README 加 CONTRIBUTING，中英雙語。用 `/document`，會產兩份：一份給每天用的人，一份給日後接手維護的人。

### 為什麼是顧問，不是產生器

那 13 個設計面向，每一個都是有很多選項的參數，不是「要」或「不要」的開關；而且它們彼此牽連，A 選了什麼會影響 B 該怎麼選。沒有一組搭配對所有專案都剛好。

所以主體是對話、手法清單、和一份設計方案。自動產檔案這件事被降格成附屬品——是顧問談完之後的產物，不是入口。

---

## 2. 快速開始

你需要：

- 裝好 Claude Code CLI（`claude --version` 跑得起來）。這是唯一硬需求。
- 心裡有一個想設計的目標專案。它不需要已經存在，你講得出「想做什麼」就行。

不需要 `.env`，不需要 API key 檔。這個專案不連任何外部服務、不存任何密鑰，執行環境就是 Claude Code 本身。

```bash
git clone <this-repo> ~/meta-harness
cd ~/meta-harness
claude
```

開了 session 之後，第一件事是用 `/model` 切到最強的 model。設計和推理這類任務對思考品質很敏感，弱一點的 model 容易堆術語、給出有問題的做法、留下邏輯漏洞。AI 不能自己切 model，這步要你主動做。

接下來可以打指令，也可以直接講白話（顧問角色會自動載入）：

```
/design ~/my-project              # 設計新的，或重新設計現有的
/healthcheck ~/my-project         # 幫現有系統做一次體檢
/retro ~/my-project               # 跑一陣子之後回顧
/document ~/my-project            # 產對外說明書
（不打指令，直接講）              # 接續上次的 session
```

第一次跑，通常 10 到 20 分鐘就能做完訪談、看到第一份設計方案。想看更完整的引導，讀 [`docs/getting-started.md`](docs/getting-started.md)。

---

## 3. 設定檔

只有一個選用的設定檔：`targets.yml`。它記錄你本機有哪些目標專案，包含路徑、目前狀態（構想中／待健檢／已健檢），以及選填的 `eval_dir` 用來蓋掉自驗目錄的預設位置。

```bash
cp targets.yml.example targets.yml
```

這個檔案已經在 `.gitignore` 裡。開 session 時你可以從這份清單挑一個，也可以完全略過它、直接在對話裡給目標專案的絕對路徑。

`.env` 不需要，本專案不用任何 API key 檔。

---

## 4. 怎麼用

進去之後你會走五種模式之一。每個模式都只是一個入口，進去之後一律是跟顧問對話，不是填表單。

| 模式 | 指令 | 白話講法 | 什麼時候用 |
|---|---|---|---|
| 設計 | `/design <目標專案>` | 「我想設計／重新設計 ~/X」 | 從零開始，或打掉重來 |
| 健檢 | `/healthcheck <目標專案>` | 「健檢 ~/X」 | 現有系統做一次體檢、找漏洞（還沒開始跑也能做）|
| 回顧 | `/retro <目標專案>` | 「回顧 ~/X」 | 目標專案跑一陣子後回頭看 |
| 說明書 | `/document <目標專案>` | 「寫說明書」 | 文件過期，或要交給別人用 |
| 接續 | （不打指令）| 「繼續上次 X 的設計」 | 接上次沒做完的 session |

### 設計流程的六個步驟

`/design` 會走完整流程：

1. **需求訪談。** 10 到 20 分鐘，混合選擇題和開放題。
2. **顧問自己寫設計方案。** 這段你不用做事。
3. **你看過、給意見、來回改到定案。** 這步用文字自由回饋，不是選擇題。
4. **分階段實作。** 拆成第一、二、三階段，逐步把檔案寫進你的目標專案。
5. **自我驗證（必經）。** 凡是機器驗得了的產出，顧問會用非互動模式跑至少三次、跑分通過，才交給你。這步編號是 4.5，因為它是實作的一部分。
6. **驗收。** 顧問跑能自動驗的部分，你自己開新 session 實際試用。
7. **定期回顧。** 幾週之後回頭看該怎麼調整。

第一次用通常跑到第三或第四步就夠了，後面兩步看需要。`/healthcheck` 和 `/retro` 是獨立的短流程，不走這六步。

### 兩種人：設計者和使用者

meta-harness 設計出來的目標專案，服務兩種人，設計時必須分清楚：

**設計者**是用 meta-harness 顧問設計這個目標專案的工程師，也就是正在讀這份 README 的你。

**使用者**是每天跑這個目標專案、看結果做決定的人。他未必懂這個領域的技術。舉例來說，一套會計系統的使用者可能是會計助理，不是工程師。

設計面向 12「人的介面」就是專門為使用者設計的那一層——講法怎麼翻譯、資訊給多細、意見怎麼回流。它和設計面向 9「可觀測性」是對照的：後者是給工程師和系統看的。

---

## 5. 人和 AI 怎麼分工

```
┌────────────────────────────────────────────────────┐
│                    你（設計者）                     │
│      提需求 / 看設計方案 / 開新 session 試用        │
└──────────────────┬─────────────────────────────────┘
                   │ /design ~/my-target
                   ▼
┌────────────────────────────────────────────────────┐
│         meta-harness 顧問（Claude Code session）    │
├────────────────────────────────────────────────────┤
│  1   訪談五件事（按鈕選擇 UI）                      │
│  2   顧問自己寫設計方案（你不用動）                 │
│  3   你給意見 → 改方案 → 再給你看（來回收斂）       │◀───┐
│  4   分階段把檔案寫進目標專案（用絕對路徑）          │    │
│  4.5 自我驗證（非互動模式跑 ≥ 3 次 + 跑分）         │    │ 對話
│  5   驗收（顧問代跑 + 你開新 session 試用）         │ ───┘
│  6   幾週後定期回顧                                 │
└──────────────────┬─────────────────────────────────┘
                   │
                   ▼
┌────────────────────────────────────────────────────┐
│            你的目標專案（做出來的 AI 工具）          │
│  Stop hook + run-self-verify.sh                    │
│  設定跟設計方案對不上 → exit 2 擋住 session 結束     │
│  coverage.json 持續追蹤驗證覆蓋率                   │
└────────────────────────────────────────────────────┘
```

交給 AI 做的是第 2 步（寫設計方案）、第 4 步（實作寫檔）、第 4.5 步（自我驗證），以及第 5 步裡機器驗得了的部分。

你自己來的是第 1 步（提需求）、第 3 步（看設計方案）、第 5 步的實際試用，和第 6 步的回顧。

有兩道自動擋關：第 4.5 步要自我驗證跑過至少三次才能往下；還有一個 Stop hook，動過架構檔案時才會跑自驗，發現設定跟設計方案對不上就擋住 session 結束。這兩道是規則 R-10「機器驗得了的產出，交付前必須先自己驗過」的執行層，繞不過去。純諮詢、純閱讀的 session 不會被罰跑一整套（靠檔案指紋比對判斷）；想強制每次都驗，設 `META_HARNESS_VERIFY=always`。

---

## 6. 指令和 skill 清單

四個指令入口：

| 指令 | 用途 |
|---|---|
| `/design <目標專案>` | 設計或重新設計，走完整六步 |
| `/healthcheck <目標專案>` | 用 13 個設計面向做體檢，產報告 |
| `/retro <目標專案>` | 跑一陣子之後的回顧 |
| `/document <目標專案>` | 產雙語 README 和 CONTRIBUTING |

兩個 skill：`consultant` 是顧問角色的定義和完整六步流程，不管從哪個指令進去都會載入；`document` 負責從設計方案和專案現況萃取內容，產出說明書。

想深入讀的話，這幾份文件是核心：

| 文件 | 用途 |
|---|---|
| [`docs/getting-started.md`](docs/getting-started.md) | 新手入口，30 分鐘跑完第一次訪談 |
| [`.claude/skills/consultant/SKILL.md`](.claude/skills/consultant/SKILL.md) | 顧問角色和六步流程的細節 |
| [`docs/design-axes.md`](docs/design-axes.md) | 13 個設計面向的索引 |
| [`docs/design-axes/<n>-<name>.md`](docs/design-axes/) | 每個面向的選項、常見錯誤做法、案例 |
| [`docs/universal-care-rules.md`](docs/universal-care-rules.md) | R-1 到 R-12，顧問內建必守的基本規則 |
| [`docs/prescription-template.md`](docs/prescription-template.md) | 設計方案的格式，你看方案時可對照 |
| [`docs/manual-template.md`](docs/manual-template.md) | 說明書的格式 |
| [`docs/consultant-flow.md`](docs/consultant-flow.md) | 顧問怎麼做判斷 |
| [`docs/lessons.md`](docs/lessons.md) | 實戰踩過的坑 |

### 13 個設計面向

工具執行、上下文管理、記憶、規劃、執行迴圈、權限與安全、hook、成效評估、可觀測性、多 agent 協作、觸發時機、人的介面、自我驗證覆蓋率。

每一個都是有很多選項的參數，而且彼此牽連。這正是為什麼用對話顧問，而不是固定模板。

---

## 7. 會產出什麼，怎麼知道做對了

### session 期間留在 meta-harness 本機的東西

這些全部都在 `.gitignore` 裡：

- `sessions/<日期>-<主題>.md`：訪談紀要，包含五段答案和設計面向的篩選表。
- `prescriptions/<日期>-<目標專案>.md`：顧問動手前寫的設計方案，也是稽核軌跡。
- `cases/`：從特定目標專案整理出來的案例。別人 fork 走不該看到你的任務內容。
- `experiments/<目標專案>-<主題>/runs/`：第 4.5 步自我驗證跑出來的原始證據，含真實的專案識別資訊。
- `BACKLOG.md`：你自己記下的「這裡的規則或方法有缺口」清單。

每個被 gitignore 的目錄底下都留了一份有進版控的 `README.md` 或結構檔，讓 fork 的人知道這目錄怎麼用，但看不到別人的私密內容。

### 寫進你目標專案的檔案

第 4 步實作時，顧問用絕對路徑直接把檔案寫進你的目標專案，工作目錄不會離開 meta-harness。寫什麼由設計方案決定，常見的有 `.claude/hooks/*.sh`、`.claude/skills/<name>/SKILL.md`、`.claude/commands/*.md`、`.claude/settings.json`，以及 `experiments/<目標專案>-eval/test-*.sh`。

### 怎麼確認做對了

這是設計面向 13 在做的事，也是規則 R-10 的具體執行。每個目標專案（包含 meta-harness 自己）實作完之後，會有這幾個檔案：

- `experiments/<目標專案>-eval/run-self-verify.sh`：單一入口，跑所有 `test-*.sh`。
- `experiments/<目標專案>-eval/test-*.sh`：各項設定對應的驗證腳本。
- `experiments/<目標專案>-eval/coverage.json`：數據面板，記錄有幾支驗證腳本、幾項檢查、覆蓋率多少。
- `.claude/hooks/self-verify-on-stop.sh` 加上 settings.json 裡的 Stop 註冊：動過架構才驗，發現對不上就擋住 session 結束。

每支 `test-*.sh` 都要歸到四種驗法之一：

- **A. 比對設定是否一致。** 同一份設定散在多個檔案時，看它們有沒有對不上。
- **B. 觸發後看有沒有反應。** hook 這類中介機制有沒有被正確叫起來。
- **C. 跑分評輸出品質。** 針對 agent 產出的內容。
- **D. 比對前後差異。** 看副作用對不對。

即時的數字——幾支腳本、幾項檢查、覆蓋率百分比——一律看 [`experiments/meta-harness-eval/coverage.json`](experiments/meta-harness-eval/coverage.json)，那份由 `generate-coverage.sh` 維護。這裡不手抄，手抄一定會過期。

meta-harness 自己也照這套驗自己：跑一整組驗證腳本，覆蓋率的分母是掃描 hooks、commands、skills、bin、模板之後由機器算出來的，人工只能附理由排除，沒被覆蓋到的項目在 `coverage.json` 裡逐條列出來。atdd-task 是第一個照做的外部專案，自帶一組驗證腳本和自己的 `coverage.json`。

有件事要講清楚：目前報的覆蓋率是結構面和行為面的（也就是四種驗法裡的 A 和 B），分母由機器推導，避免人工灌水。至於語意層面的覆蓋——也就是驗法 C，用 LLM 當評審去判斷內容品質——還沒完全做起來，列在待辦。現在 consultant skill 的輸出品質是用結構檢查（`test-consultant-skill-structure.sh`）暫時代替，那不是真正的語意驗證。

細節見 [`docs/design-axes/13-self-verify-coverage.md`](docs/design-axes/13-self-verify-coverage.md)。

---

## 8. 不做什麼，以及已知限制

不做的事：

- **不產目錄骨架。** 沒有 `meta-harness new <type>` 這種指令。理由見第 1 節。
- **不替你寫業務邏輯。** 顧問只動框架層（hook、skill、指令、設定、驗證腳本），不碰你的任務內容，像是業務規則、agent prompt 裡的領域知識。這是規則 R-9。
- **不跨層越權。** 框架層不替任務內容表態（同樣是 R-9）；方法層的規則不會寫進針對特定專案的文件（R-8）。
- **不繞過驗證。** 機器驗得了的產出，交付前一定要非互動跑過至少三次（第 4.5 步，R-10）。Stop hook 會直接擋住「沒驗就 commit」。
- **不連外部服務。** 沒有 API key，沒有遙測，沒有遠端同步。執行環境就是 Claude Code 本身。

已知限制：

- **綁 Claude Code。** 在 ChatGPT、Cursor、其他 IDE 上跑不了，因為顧問角色是靠 Claude Code 的 skill 和指令機制實作的。
- **要有人在才好用。** 設計流程靠對話，沒有設計者在場就跑不動（定期回顧的部分例外）。
- **驗 LLM 輸出品質這件事還偏結構面。** 驗法 A、B、D 都做起來了；驗法 C（用 LLM 當評審判斷 agent 輸出品質）的基礎建設還在演進。
- **會撞 session 額度。** 跑大量 `claude -p` 子程序（例如把不同 agent 和 model 排列組合去跑評估）會撞到 Claude Code 訂閱的 session 上限。要避開的話，設 `ANTHROPIC_API_KEY` 改走 API 帳單。

---

## 9. 出錯怎麼辦

**Stop hook 一直擋住 session 結束，一直印「自驗失敗」。**
跑 `bash experiments/meta-harness-eval/run-self-verify.sh`，直接看是哪一支對不上。這不是在處罰你，是在提醒：確實有東西對不上了，先修掉。

**顧問開始講概念，不出設計方案。**
把它拉回來：「你是設計者，不是在唸教科書，直接給做法。」consultant skill 內建了防止角色跑掉的機制，但你自己盯著也是一層保險。

**不確定某條規則或某個面向該不該升級成通則。**
看 `docs/consultant-flow.md` 的判斷邏輯，或直接在 session 裡問顧問：「這該升成通則嗎？換到別的專案還成立嗎？」

**實作完發現設定跟設計方案對不上。**
跑 `experiments/meta-harness-eval/test-cross-references.sh`，它會自動抓出對不上的規則編號和面向編號。也可以自己 grep。

**撞到 Claude session 額度上限。**
看訊息裡寫的重置時間。長期解法是設 `ANTHROPIC_API_KEY` 改走 API 帳單，那是另一池額度。

踩過的坑持續累積在 `docs/lessons.md`，每條都寫了為什麼會踩到、之後怎麼防。

找不到答案的話，去 [Issues](https://github.com/spenguinlui/meta-harness/issues) 或直接開 PR。也歡迎在 session 裡跟顧問說「我覺得這套方法有個缺口」，它會幫你判斷該升成通則，還是先記進 `docs/lessons.md`。

---

## 10. 維護與回報

維護者是 [@spenguinlui](https://github.com/spenguinlui)。

要回報問題或提建議，開 [GitHub Issue](https://github.com/spenguinlui/meta-harness/issues)。附上你踩到的具體情境——哪個 session、哪份設計方案、卡在哪條規則或哪個面向——比抽象的建議有用得多。

想擴充這套方法本身（加面向、加規則、加 skill），先讀 [`CONTRIBUTING.md`](CONTRIBUTING.md)，那裡講的是「怎麼擴 meta-harness 自己」。

想分享你的設計方案，歡迎開 PR 加進 `cases/`。但注意 `prescriptions/` 本身是 gitignored、含目標專案的私密內容，要分享得另外寫一份精簡版。

---

## 11. 詞彙表

這些是 meta-harness 內部的講法，第一次接觸容易混：

| 詞 | 意思 |
|---|---|
| 目標專案 | 你正在設計的那個 AI agent 工具的 repo，不是 meta-harness 本身。原始碼和指令裡叫 target repo。 |
| 設計者 | 用 meta-harness 設計目標專案的工程師。讀這份 README 的就是你。原始碼裡叫 builder。 |
| 使用者 | 每天實際用目標專案的人。可能跟設計者是同一個人，也可能不是（例如會計助理對上系統工程師）。原始碼裡叫 human 或 viewer。 |
| 顧問角色 | Claude Code session 載入 `consultant` skill 之後扮演的角色。 |
| 設計方案 | 顧問動手前寫的那份設計文件，放在 `prescriptions/<日期>-<目標專案>.md`。原始碼和指令裡叫 prescription。 |
| 說明書 | `/document` 產給目標專案的對外 README 和 CONTRIBUTING。原始碼裡叫 manual。 |
| 設計面向 | 那 13 條設計參數（工具執行、上下文、記憶……）。每條都是一個選項空間，不是開關。原始碼和指令裡叫 design axis / 設計軸。 |
| R-N | 12 條跨專案通用的基本規則。例如 R-1 是 CLAUDE.md 不超過 50 行，R-10 是交付前先自驗，R-12 是寫進目標專案的檔案要能獨立看懂。 |
| 串接設定 | hook、skill、指令、settings 這些元件怎麼接起來變成一個行為。原始碼裡叫 wiring。 |
| 做法 | 一條串接設定的具體實作方式。是一個行為，不是一個檔案。原始碼裡叫 mechanism。 |
| 不該做的事 | 明確列出「這個工具不該做什麼」。第一步訪談一定會問。原始碼裡叫 anti-scope。 |
| 定期回顧 | 目標專案跑一陣子後回頭檢視四件事：哪些成果該累積成 skill、訊號累積起來看到什麼、記憶的形狀對不對、方法本身有沒有缺口。原始碼裡叫飛輪或 retrospective。 |
| 自己驗自己 | meta-harness 用自己的那套驗證方法驗自己。原始碼裡叫 dog food。 |
| 非互動驗證 | 用 `claude -p` 跑至少三次加上機器跑分，第 4.5 步的要求。原始碼裡叫 headless。 |
| 對不上 | 串接設定跟設計方案或原始來源不一致。這是自我驗證要抓的東西。原始碼裡叫 drift。 |

hook、skill、slash command、CLI、DDD、TDD 這類業界通用術語不列在這，預設讀者懂。

---

## Repo 結構

```
.claude/
  hooks/                    顧問自己用的 hook（工作目錄守衛、CLAUDE.md 行數檢查、
                            提問前自查；只有 self-verify-on-stop 會擋住 session）
  skills/consultant/        顧問角色，核心，所有指令進去都會載入
  skills/document/          /document 用的 skill
  commands/                 design / healthcheck / retro / document 四個入口
                            （document 只是薄薄一層，主邏輯在 skill 裡）
  settings.json             hook 註冊，含自驗用的 Stop hook
docs/
  getting-started.md        新手入口
  consultant-flow.md        顧問怎麼做判斷
  design-axes.md            13 個設計面向的索引
  design-axes/              每個面向的深入說明
  universal-care-rules.md   R-1 到 R-12 基本規則
  prescription-template.md  設計方案的格式
  manual-template.md        說明書的格式
  lessons.md                實戰踩過的坑
experiments/
  meta-harness-eval/        meta-harness 自己的驗證（入口腳本、各驗證腳本、coverage.json）
  consolidation-loop/       自驗流程的參考實作
targets.yml.example         目標專案清單範本（複製成 targets.yml）
─── 以下都在 .gitignore（每個 fork 自己的內容，不上 git）───
targets.yml                 你本機的目標專案清單
sessions/                   訪談紀要
prescriptions/              設計方案留檔
cases/                      案例庫
experiments/*/runs/         自驗的原始證據
BACKLOG.md                  還沒處理的失敗和缺口
```

---

## 目前進度

**v0.5：加入自我驗證覆蓋率，以及跟軟體工程方法的對應。**

已完成：

- 13 個設計面向齊了。v0.5 新增第 13 個「自我驗證覆蓋率」，把 R-10 從一條規則升級成可量化的指標加上自動擋關。
- R-1 到 R-12 通用規則齊了。R-11 是雙語說明書，R-12 是目標專案的文件要能獨立看懂。
- consultant skill 鎖住顧問角色，六步流程完整。
- `/document` 能自動產雙語 README 和 CONTRIBUTING。
- 記憶分多個維度歸類，加上「計畫存成記憶」和「成果累積成 skill」兩個方向的循環。
- meta-harness 自己做完了自我驗證，用自己的驗證腳本驗自己，分母由機器推導。即時數字看 `coverage.json`。
- atdd-task 是第一個做完自我驗證的外部專案，自帶驗證腳本和 coverage.json。

進行中：推廣到其他專案。各專案目前做到哪，跑 `bash experiments/meta-harness-eval/test-target-coverage.sh` 看即時進度，這裡不手抄。

---

## License

MIT
