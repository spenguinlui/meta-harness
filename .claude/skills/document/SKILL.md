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

## 萃取來源（產出前先讀齊，每段內容都要有來源；R-4 不編造）

| 要素 | 從哪讀 |
|---|---|
| 使命 / persona / anti-scope / 已知限制 | `prescriptions/<最新>-<target>.md`（Part A / F）|
| viewer 是不是 peer（決定翻譯深度 + 粒度）| prescription Part A「Human 領域熟悉度」/ target `docs/human-profile.md`（若有）|
| 安裝 / 指令 / 參數 | target `package.json`、`.env.example`、`README`（既有）|
| 可用 `/command`、skill | target `.claude/skills/*/SKILL.md`、`.claude/commands/*` |
| 產出檔 / 驗收方式 | prescription Part D / E + target 實際目錄 |
| 架構 / wiring（維護者文件用）| prescription Part C / D + target `.claude/` 結構 |

> 沒對應 prescription 時：先 grep target repo 自己摸清現況再寫，並在缺口標 `[需業主補：<什麼>]`，不要流暢虛構。

## 雙語產出規則

- 主檔 = 專案工作語言（看 target 既有 README / CLAUDE 語言判定；可被 `--primary zh|en` 覆寫）。
- 主中文：`README.md`(中) + `README.en.md`(英)；主英文反之用 `.zh-TW.md`。docs / CONTRIBUTING 同規。
- 每檔第一行語言切換：`> 🌐 **繁體中文** | [English](README.en.md)`（依該檔語言調）。
- **同一次從同一份萃取事實生成兩版**，章節順序 / 錨點完全一致 → 不漂移。
- **不翻譯**：程式碼、路徑、指令、env 變數名、識別字、表格內的值（顏色碼 / px / node id）。只翻散文與表格標題。

## 深度校準（讀 human-profile / Phase 0 第 5 題）

- viewer = 該領域 peer → 術語直用、可給細節。
- viewer = 非 peer → 術語白話 + 括號展開、藏實作細節、給「結論 + 怎麼做」。
- 多角色 → 分層輸出（預設一層 + 其他折疊）。

## 可重跑不盲蓋

- target 已有 README / docs → **合併刷新**，不直接覆蓋；偵測到大量 human 手寫內容先問業主再動。
- 重跑時序：反映**當下已驗證**的 repo 狀態（list 的指令 / 路徑產出前 grep 對齊真實，避免文件講了 repo 沒有）。

## 落地 + 收尾

1. 逐檔 Write 到 target（絕對路徑）：Viewer 說明書（README 雙語 + 必要的 docs 雙語）+ 維護者文件（CONTRIBUTING 雙語）。
2. 收尾跟業主說：產了哪些檔、主語言是什麼、哪些段標了 `[需業主補]`。
3. 文件是 target 的**任務內容介面層**——framework 結構由顧問落地（R-9）；commit 與否照業主 target 慣例。

## 反模式

| 反模式 | 描述 |
|---|---|
| 兩讀者混一份 | Viewer 說明書塞架構細節 / 維護者文件用 viewer 白話（違反設計軸 9/12 分流）|
| 一套模板套到底 | 不讀 human-profile，peer 與非 peer 給同深度 |
| 雙語交錯 | 中英同段交錯排版，兩種語言都讀不順 |
| 流暢虛構 | 寫出 repo 沒有的指令 / 參數（違反 R-4）→ 該標 `[需業主補]` |
| 翻譯識別字 | 把指令 / 路徑 / env 名 / 顏色碼也翻譯 → 複製貼上就壞 |
