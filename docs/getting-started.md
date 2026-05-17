# Getting Started with meta-harness

> 讀完這份文件你應該能在 30 分鐘內跑完第一次顧問 session 的 Phase 0。

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

## Phase 0 訪談（10–20 分鐘）

顧問透過 **AskUserQuestion**（UI 按鈕）問你 5 件事：

| 問什麼 | 你要想清楚的 |
|---|---|
| 使命 / 痛點 | 今天哪件事讓你覺得「如果有個 agent 就好了」 |
| 現有形狀 | 已有的模組 / 流程，哪些想保留、哪些不確定 |
| Anti-scope | 這個工具**不該**做什麼（必須挑出 ≥ 3 條） |
| 失敗 floor + 壽命 | 什麼狀況你會放棄它；預計用幾週 / 幾月 / 永久 |
| Human 領域熟悉度 | 每天用這工具的人（可能不是你）在這個領域是 peer 嗎 |

訪談結束，顧問給你一張**設計軸篩選表**——哪些軸要全力設計、哪些 N/A——你 review 確認後顧問才進 Phase 1。

---

## Phase 1：設計圖（不需要你做什麼）

顧問獨自寫 `prescriptions/<date>-<target>.md`，完成後把**重點摘要貼給你看**（不是叫你自己打開檔案）。

你的工作是 review 摘要、給文字回饋。沒意見就說「OK 開始實作」。

---

## 完整 6 步流程（概覽）

```
Phase 0  需求訪談（你 + 顧問）
Phase 1  建築師出設計圖（顧問獨自）
Phase 2  業主 review，反覆修改
Phase 3  分期實作落地 → 寫進 target repo
Phase 4  驗收（顧問自動驗 + 你跨 session 試用）
Phase 5  飛輪 retrospective（數週後回看）
```

第一次用通常只跑 Phase 0–3，Phase 4–5 視需要。

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
| `docs/design-axes.md` | 12 設計軸索引（設計參數總覽） |
| `docs/design-axes/<軸>.md` | 每條軸的深度設計選項 + 反模式 |
| `docs/universal-care-rules.md` | R-1~R-9 衛生規則（顧問內建強制遵守） |
| `docs/prescription-template.md` | 設計圖格式（供 review 時對照） |
| `docs/consultant-flow.md` | 顧問重排機制（顧問怎麼做判斷） |
| `prescriptions/` | 每次 session 的設計圖留痕（gitignored） |
| `sessions/` | 訪談紀要（gitignored） |
