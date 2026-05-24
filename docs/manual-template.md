# Manual Template — target repo 的交付文件結構

> 顧問流程 Step 5 驗收通過後，交付給 target repo 的**說明書**結構。和 `prescription-template.md` 的差別：
> prescription 是**設計圖（給建築師看）**；manual 是**說明書（給每天用 target 的人 + 日後維護的人看）**。
> 由 `/document` skill 從 prescription + repo 現況 + human-profile 自動產出，可重跑刷新。

---

## 兩種讀者 = 兩份文件（對應設計軸 9 vs 12，不可混）

| 交付物 | 給誰 | 聲音 | 落地 |
|---|---|---|---|
| **Viewer 說明書** | 每天用 target 的人（**未必是 builder**） | 他的語言、任務導向 | `README.md` + `docs/<topic>.md` |
| **維護者文件** | 日後接手改 / 擴充 target 的工程師 | 技術、架構、為什麼這樣設計 | `CONTRIBUTING.md` 或 `docs/architecture.md` |

混在一份 = builder 嫌囉嗦 + viewer 看不懂（設計軸 9/12 邊界反模式）。

---

## Viewer 說明書結構（README.md 為入口，深的下沉 docs/）

每段標「來源」= 該段內容從哪萃取，不要無中生有（違反 R-4）。

| # | 段落 | 內容 | 來源 |
|---|---|---|---|
| 1 | **是什麼 / 能做什麼** | 一段話定位 + 能力條列 | prescription Part A 使命 |
| 2 | **快速開始** | 前置工具 / 安裝 / 第一次跑（最短路徑到「看到它動」） | repo（package.json scripts、README 既有） |
| 3 | **存取與參數** | `.env` 要哪些值 **+ 怎麼拿到**（帳號 / token / 權限申請步驟） | `.env.example` + Part A persona |
| 4 | **怎麼用 / 常見任務** | 「我想做 X → 這樣下指令」具體範例（viewer 最常讀的一段） | Part A 使命 + Part E user intent |
| 5 | **可用指令 / skill 清單** | 有哪些 `/command`、各自何時用（一句白話用途） | `.claude/skills/` + `.claude/commands/` |
| 6 | **產出什麼 + 怎麼確認做對了** | 會生出哪些檔 / 結果 + viewer 怎麼驗證成功 | Part D 產出 + Part E 驗收 |
| 7 | **邊界:不做什麼 + 已知限制** | 明確排除的能力 + known limitations（防誤用、防錯誤期待） | Part A anti-scope + Part F |
| 8 | **出錯怎麼辦** | 常見失敗 → 怎麼救（含 error message 對照） | Part F + 實測踩過的坑 |
| 9 | **誰維護 / 怎麼回報** | 維護人是誰、怎麼回報問題 / 給回饋 | Phase 0 builder + 設計軸 12 回饋通道 |
| 10 | **詞彙表**（條件性） | 領域術語白話對照 | **僅 viewer 非該領域 peer 時才寫**（設計軸 12 翻譯層） |

**精簡版**（壽命短 / 自用工具）：至少 1、2、3、4、7。

## 維護者文件結構（CONTRIBUTING.md / docs/architecture.md）

| 段落 | 內容 |
|---|---|
| **架構概覽** | 主要模組 / 資料流 / 關鍵抽象（一張圖或一段話講清骨架） |
| **wiring 怎麼運作** | hook / skill / command / settings 各自做什麼、怎麼串 |
| **怎麼擴充** | 加一個新 X（元件 / 命令 / 規則）的步驟 |
| **設計依據** | 為什麼這樣設計（連回 prescription，或摘要關鍵決策 + anti-scope） |
| **怎麼驗證改動** | 跑哪些測試 / 自驗 loop（連回 Part E）|

---

## 雙語慣例（中英兩版）

- **兩個檔、不交錯**：交錯排版兩種語言都讀不順。
- **主檔 + companion**：主檔 = 專案工作語言（看既有 README/CLAUDE 語言判定）。
  - 主中文：`README.md`（中）+ `README.en.md`（英）
  - 主英文：`README.md`（英）+ `README.zh-TW.md`（中）
  - docs / CONTRIBUTING 同規（`<name>.md` + `<name>.en.md` / `.zh-TW.md`）
- **頂端切換行**（每檔第一行）：`> 🌐 **繁體中文** | [English](README.en.md)`
- **同一次生成兩版**：由同一份萃取事實渲染，結構 / 錨點 / 章節順序完全一致 → 不漂移。
- **不翻譯**：程式碼、檔案路徑、指令、env 變數名、識別字、表格內的值（如顏色碼、px、node id）。**只翻散文與表格標題**。

---

## Viewer 深度校準（不可一套模板套到底）

第 4、10 段的深度由「**viewer 是不是該領域 peer**」決定（讀 Phase 0 第 5 題 / `docs/human-profile.md`）：

| viewer 類型 | 翻譯深度 | 內容粒度 |
|---|---|---|
| 該領域 peer（如前端工具給前端） | 術語直用、不括號 | 可給實作細節 |
| 非 peer（如 infra 工具給會計） | 術語白話 + 括號展開 | 結論 + 怎麼做，藏實作細節 |
| 多角色 | 分層輸出（老闆視角 / 執行者視角折疊） | 每角色預設一層 |

只蓋翻譯不蓋粒度 = 資深嫌囉嗦 + 初級卡關（設計軸 12 反模式）。

---

## 進階：大型 / 成熟 target 的文件組織（選用，來源：ai-infra-management）

當 target 累積到很多份 docs（超出基本 README 的 1-10 段、有多個記憶 / 文件落點）時，光把文件平鋪會讓 viewer 不知從哪讀起。兩個 pattern 讓厚文件仍可導航：

1. **讀順序階梯**（reading-order ladder）：不平鋪，給**分層讀順序**——「5 分鐘進入狀況 → 30 分鐘理解架構 → 動手 / 動 prod 前必讀 → 領域知識（碰到再查）→ 演化與歷史」。落在 `docs/_READING_ORDER.md`，README 指向它。對位設計軸 12（viewer 介面）+ 設計軸 3 反模式「把 memory 當文件平鋪丟人猜」的反向。
2. **「寫東西前該問哪裡」路由表**：當 target 有多個記憶落點（如 knowledge / decisions / runbook / postmortems），給「想寫 X → 該進哪格」的決策表，避免內容亂落、之後召回變噪音。落在文件分流判準檔（如 `docs/<knowledge>/_README.md`）。

**何時用**：target docs 超過約 8-10 份、或有多種記憶落點時。**小 target（figma2code 級）不必**——平鋪 1-10 段就夠，硬搞五層階梯反而過度（對位設計軸篩選「壽命 / 規模決定深度」）。

---

## 產出守則

1. **每段必有來源**：寫不出來源 = 該段在編造（R-4）→ 標 `[需業主補：<什麼>]`，不要流暢虛構。
2. **可重跑不盲蓋**：重跑時 target 已有手寫內容 → 保留 / 合併，不直接覆蓋（偵測到大量 human 編輯先問）。
3. **反映已驗證狀態**：在 Step 5 驗收後產出，寫 target「現在真的會做什麼」，不是設計時的想像。
4. **指令 / 路徑必對得上 repo 真實**：list 的 `/command`、scripts、檔名要實際存在（產出前 grep 對齊）。
