---
name: document
description: meta-harness 顧問——為已設計/落地的 target repo 產出交付說明書(雙語 Viewer 說明書 + 維護者文件)。任何 user 說「寫說明書 / 產 README / 更新文件 / document X / 補 target 文件 / 給別人用要有說明書」類請求載入。從 prescription + repo 現況 + human-profile 自動萃取,不重新發明。設計流程 Step 5 驗收後也會呼叫這個 skill。
---

# /document — target 交付說明書產出

顧問流程產出的 prescription 是**設計圖（建築師看的）**。target 建出來要給別人用，還缺**說明書**。這個 skill 補這塊。

## 你在做什麼

把一個 target repo 的「給人看的文件」生出來，**兩種讀者分流**（對應設計軸 9 vs 12）：
- **Viewer 說明書** → target 的 `README.md` + `docs/`（給每天用它的人，用他的語言）
- **維護者文件** → target 的 `CONTRIBUTING.md`（給日後接手改的人）

**雙語**：中英各一版（兩個檔、不交錯）。

## 開場 checklist

1. `pwd` 確認 `~/meta-harness`（產出寫到 target 用絕對路徑，cwd 不離開 meta-harness）。
2. 確認 target 絕對路徑（空則問）。
3. Read：`docs/manual-template.md`（結構 + 雙語慣例 + 深度校準）。
4. 不重跑完整訪談——背景從既有 artifact 萃取。

## Step 0：repo 自我探索（blocking，動筆前必做）

**不管有沒有現成 README，都要先懂這個專案再寫。**

讀的順序：
1. `CLAUDE.md`（角色定義 + 核心規則）
2. `.claude/commands/` 主要 command（feature / fix / continue / status 等）
3. `.claude/agents/*.md`（各 agent 的職責 + 交付物）
4. `.env.example`（存取與參數）
5. prescription（設計意圖補充，**不取代** repo 現況）

讀完後用自己的話確認能回答：
- 這個工具是什麼？viewer 用它來做什麼事？
- viewer 下什麼指令、會看到什麼、怎麼知道做對了？
- 不做什麼？用錯了會怎樣？

說不清楚 = 還沒懂，繼續讀。

> **現有 README 不算「已懂」**：README 可能是 builder 視角或已過時。自我探索是讀 source（commands / agents），不是讀現有說明書。

## Step 1：viewer 校準宣告（blocking，動筆前輸出）

讀完 repo 後，動筆前先明確輸出：

```
viewer：[誰]（如：PM / RD / 業務，工程非 peer）
深度策略：[術語直用 or 白話展開]、[給/藏實作細節]
```

這份宣告決定 10 個段落的每一段要怎麼寫。不輸出就動筆 = 跳過校準，必補。

## Step 2：10 段 checklist（逐項對完再動筆）

對照 `docs/manual-template.md` 的 Viewer 說明書結構，逐項確認：

| # | 段落 | 有 repo 來源？ | 深度符合 viewer？ | 備注 |
|---|------|--------------|-----------------|------|
| 1 | 是什麼 / 能做什麼 | | | |
| 2 | 快速開始 | | | |
| 3 | 存取與參數 | | | |
| 4 | 怎麼用 / 常見任務 | | | |
| 5 | 可用指令 / skill 清單 | | | |
| 6 | 產出什麼 + 怎麼確認做對了 | | | |
| 7 | 邊界：不做什麼 + 已知限制 | | | |
| 8 | 出錯怎麼辦 | | | |
| 9 | 誰維護 / 怎麼回報 | | | |
| 10 | 詞彙表（條件性）| | | |

每段必須有明確的 repo 來源（commands / agents / config / .env.example）。寫不出來源 = 標 `[需業主補]`，不流暢虛構。

## 萃取來源（Step 0 探索後對照，prescription 是補充不是主源）

| 要素 | 主要來源 | 補充來源 |
|---|---|---|
| 使命 / 能做什麼 | `.claude/commands/` 主要 command | prescription Part A |
| viewer 是不是 peer | prescription Part A「Human 領域熟悉度」/ `docs/human-profile.md` | — |
| 安裝 / 存取 / 參數 | `.env.example`、`projects.yml` | prescription Part A persona |
| 可用指令清單 | `.claude/commands/*`（逐一讀，不靠記憶） | — |
| 產出 / 驗收方式 | `.claude/agents/*.md` 的交付物規格 | prescription Part D / E |
| 已知限制 / anti-scope | prescription Part A / F | CLAUDE.md 禁止事項 |
| 架構 / wiring（維護者文件）| `.claude/` 目錄結構 + hooks + config | prescription Part C / D |

> **現有 README 不是萃取來源**：是合併對象。讀它是為了「保留人工手寫的部分」，不是為了「複製到新文件」。

## 可重跑不盲蓋

- target 已有 README / docs → **先判斷性質**：
  - 純 viewer 用途（how-to 導向）→ 合併刷新，偵測到大量 human 手寫先問業主
  - 混有 builder / 架構細節（hook 腳本名、config 路徑、agent 架構）→ **這不算已覆蓋 viewer 說明書**，需重構分流，把 builder 細節移到 CONTRIBUTING，README 留 viewer 視角
- 重跑時序：反映**當下已驗證**的 repo 狀態（list 的指令 / 路徑產出前 grep 對齊真實，避免文件講了 repo 沒有）。

## 雙語產出規則

- 主檔 = 專案工作語言（看 target 既有 README / CLAUDE 語言判定；可被 `--primary zh|en` 覆寫）。
- 主中文：`README.md`(中) + `README.en.md`(英)；主英文反之用 `.zh-TW.md`。docs / CONTRIBUTING 同規。
- 每檔第一行語言切換：`> 🌐 **繁體中文** | [English](README.en.md)`（依該檔語言調）。
- **同一次從同一份萃取事實生成兩版**，章節順序 / 錨點完全一致 → 不漂移。
- **不翻譯**：程式碼、路徑、指令、env 變數名、識別字、表格內的值（顏色碼 / px / node id）。只翻散文與表格標題。

## 落地 + 收尾

1. 逐檔 Write 到 target（絕對路徑）：Viewer 說明書（README 雙語 + 必要的 docs 雙語）+ 維護者文件（CONTRIBUTING 雙語）。
2. 收尾跟業主說：產了哪些檔、主語言是什麼、哪些段標了 `[需業主補]`。
3. **落地後 self-containment 自檢（R-12，blocking gate）**：`grep -rn "meta-harness\|prescription\|設計軸\|consultant\|顧問\|Stage [0-9]\|R-[0-9]" <target> --include=*.md` → 有命中（非 target 自身文案）= 洩漏，**先清乾淨 + 再 grep 確認零命中才能 commit**。grep 跑成「印出來看看」不算做（會帶著洩漏 push 出去）。
4. 文件是 target 的**任務內容介面層**——framework 結構由顧問落地（R-9）；commit 與否照業主 target 慣例。

## 反模式

| 反模式 | 描述 |
|---|---|
| 兩讀者混一份 | Viewer 說明書塞架構細節 / 維護者文件用 viewer 白話（違反設計軸 9/12 分流）|
| 一套模板套到底 | 不讀 human-profile，peer 與非 peer 給同深度 |
| 雙語交錯 | 中英同段交錯排版，兩種語言都讀不順 |
| 流暢虛構 | 寫出 repo 沒有的指令 / 參數（違反 R-4）→ 該標 `[需業主補]` |
| 翻譯識別字 | 把指令 / 路徑 / env 名 / 顏色碼也翻譯 → 複製貼上就壞 |
| 洩漏框架身分 | target 檔引用 meta-harness / prescription / R-N / 設計軸 / 顧問 jargon → target 該 self-contained，設計依據用 target 自己的話講（R-12）|
| 以現有 README 代替 repo 探索 | 現有 README 可能是 builder 視角或已過時，直接信任它等於沒懂專案就動筆 → Step 0 必讀 source（commands / agents）|
| 附加而非重構 | 現有 README 混有 builder 細節，只在尾巴補段落 → viewer 說明書仍未達標；應重構分流，把 builder 細節移 CONTRIBUTING |
