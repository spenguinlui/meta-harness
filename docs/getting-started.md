---
layout: page
eyebrow: 新手入口
---

# Getting Started with meta-harness

> 讀完這份文件你應該能在 30 分鐘內跑完第一次顧問 session 的 Step 1（需求訪談）。

---

## 前提

- Claude Code CLI 已安裝（`claude --version` 可跑）
- 你已知道想設計的 target repo 路徑（如 `~/my-project`）
- target repo 不需要已存在——描述「想做什麼」就夠

---

## 開始一個 Session

```bash
cd ~/meta-harness
claude
```

**第一句話講：**
```
我想設計 ~/my-project 這個工具
```

`consultant` skill 自動載入，顧問會問 5 個問題。

> 第一句話說「繼續 X」而非「設計 X」的話，顧問會問你指的是哪份 `sessions/` 紀錄，然後接續。

---

## Step 1 訪談（10–20 分鐘）

顧問透過 **AskUserQuestion**（UI 按鈕）問你 5 件事：

| 問什麼 | 你要想清楚的 |
|---|---|
| 使命 / 痛點 | 今天哪件事讓你覺得「如果有個 agent 就好了」 |
| 現有形狀 | 已有的模組 / 流程，哪些想保留、哪些不確定 |
| Anti-scope | 這個工具**不該**做什麼（必須挑出 ≥ 3 條） |
| 失敗 floor + 壽命 | 什麼狀況你會放棄它；預計用幾週 / 幾月 / 永久 |
| Human 領域熟悉度 | 每天用這工具的人（可能不是你）在這個領域是 peer 嗎 |

訪談結束，顧問給你一張**設計軸篩選表**——哪些軸要全力設計、哪些 N/A——你 review 確認後顧問才進 Step 2。

---

## Step 2：設計圖（不需要你做什麼）

顧問獨自寫 `prescriptions/<date>-<target>.md`，完成後把**重點摘要貼給你看**（不是叫你自己打開檔案）。

你的工作是 review 摘要、給文字回饋。沒意見就說「OK 開始實作」。

---

## 完整 6 步流程（概覽）

```
Step 1   需求訪談（你 + 顧問）
Step 2   建築師出設計圖（顧問獨自）
Step 3   業主 review，反覆修改
Step 4   分期實作落地 → 寫進 target repo
Step 4.5 自驗 loop（顧問 headless 跑 ≥ 3 次 + 機器評分，通過才交付）
Step 5   驗收（顧問自動驗 + 你跨 session 試用）
Step 6   飛輪 retrospective（數週後回看）
```

第一次用通常只跑 Step 1–4，Step 5–6 視需要。

---

## 常見第一次卡關

**「顧問問太多了」**
→ Anti-scope 那題最多人想跳過。不問 = 設計圖過度膨脹 = 實作後更難砍。先給 3 條粗略邊界就夠。

**「我的 target repo 還沒建」**
→ 可以，顧問會出設計圖後再建目錄 / 初始化。先聊需求。

**「我不知道壽命」**
→ 誠實說「不確定」。顧問會幫你分析：若壽命短，設計圖就輕量；若永久，才補 memory / eval 全套。

**「設計圖我看不懂」**
→ 設計圖摘要用中文功能名描述（如「安全守衛」「回饋通道」），顧問不會丟「Part A-F」字母編號給你。看不懂就直接問。

---

## Repo 核心文件導覽

| 文件 | 用途 |
|---|---|
| `docs/design-axes.md` | 13 設計軸索引（設計參數總覽） |
| `docs/design-axes/<軸>.md` | 每條軸的深度設計選項 + 反模式 |
| `docs/universal-care-rules.md` | R-1~R-12 衛生規則（顧問內建強制遵守） |
| `docs/prescription-template.md` | 設計圖格式（供 review 時對照） |
| `docs/consultant-flow.md` | 顧問重排機制（顧問怎麼做判斷） |
| `prescriptions/` | 每次 session 的設計圖留痕（gitignored） |
| `sessions/` | 訪談紀要（gitignored） |

> `sessions/` 裡的舊紀要是**當時的快照**，其中的路徑 / 檔名連結可能已隨 repo 演化而失效——當歷史看，別當現況。

---

## 從零複製這套方法（不 clone 本 repo）

你不需要 clone meta-harness 才能用這套方法。它不是一個要安裝的框架，而是**一組可以照抄進你自己 repo 的紀律**。最小可行版只要五樣東西：

### (a) 拿 13 設計軸當設計 checklist

設計任何 AI harness 前，把 [`docs/design-axes.md`](design-axes.md) 的 13 條當「設計參數空間」逐條問「這條對我的 target 是 existential / 要設計 / N/A？」。不是全套都要做——多數輕量工具只需 3–5 條（篩選邏輯見 [`consultant-flow.md`](consultant-flow.md)）。這一步就足以避開「想到哪做到哪」的漏設計。

### (b) 抄這三條衛生規則（最小集）

完整 12 條見 [`docs/universal-care-rules.md`](universal-care-rules.md)，但外部採用先守這三條就有八成價值：

- **R-4 不編造**：找不到 / 做不到就直說 + 列出試過什麼，不要用流暢的猜測填補。
- **R-10 先自驗再交付**：任何「機器能驗」的產出（腳本 / command / agent），交給人之前自己先跑通、留證據，不要「改完 = 完成」。
- **R-12 不洩漏框架**：寫進 target 的檔案要能獨立看懂，不引用你設計時用的內部術語 / 編號 / 這套方法本身的行話。

### (c) 六步流程合約（骨架摘要）

不管誰來執行，這六步的**產出物 + 閘門**是合約，做法可自由：

```
1  五件事訪談   → 紀要（使命 / 形狀 / 邊界 / 失敗 floor+壽命 / human 熟悉度）+ 設計軸篩選表
2  設計圖       → 一份 prescription（文字 + 關鍵檔案骨架）
3  review 收斂  → 業主自由文字回饋，改到定案（不是選擇題）
4  分期落地     → 逐 Stage 把檔案寫進 target
4.5 自驗 loop   → 可機驗產出 headless 跑 ≥ 3 次 + 機器評分通過才交付（R-10）
5  驗收         → 靜態檢查 + 跨 session 實際試用
```

### (d) 最小自驗起步（三個檔就能開跑）

R-10「先自驗」怎麼物理化？最小基建只有三塊，都可以照抄本 repo 的對應檔案當範例：

| 你要建的 | 抄哪個當範例 | 作用 |
|---|---|---|
| 一支 `test-<feature>.sh` | [`test-prescription-template-structure.sh`](../experiments/meta-harness-eval/test-prescription-template-structure.sh)（簡單 Pattern A：grep 關鍵結構在不在）| 驗某條 wiring 沒漂走 |
| `run-self-verify.sh` | [`run-self-verify.sh`](../experiments/meta-harness-eval/run-self-verify.sh) | 單一 entry point，跑所有 `test-*.sh`，回 0 / 1 |
| Stop hook | [`self-verify-on-stop.sh`](../.claude/hooks/self-verify-on-stop.sh) + [`settings.json`](../.claude/settings.json) 的 `Stop` 註冊 | 動過架構檔的那輪才跑自驗，drift 時擋住 session 結束，讓「改了沒驗就收工」變成不可能 |

先做後兩塊基建（一次性），之後每加一條 wiring，只多寫一支 `test-*.sh`。

### (e) 什麼時候才需要完整 meta-harness

上面的最小集適合**一個人、一個 target**。當你遇到以下情況，才值得把整套 meta-harness 搬來（顧問 skill + prescription 模板 + 13 軸深度文件 + 陰性樣本庫）：

- 你要**反覆**設計多個 target，需要可重用的 pattern library 而非每次重想；
- target 要**交給不是你**的人用 / 維護，需要正式的說明書與維護者文件（R-11）；
- 你想要 prescription 的**語義合約機器閘門**（防掏空）與跨 target 的登記簿追蹤。

只做一個小工具？留在最小集就好——提前搬整套框架 = 沒有證據的疊層。
