# 支柱 12：Viewer Interface

target repo 跑出來的東西**給誰看**。和「給工程師 / 系統看」的支柱 9 觀測對稱——支柱 9 是 system-facing IO 邊界，支柱 12 是 **viewer-facing** IO 邊界。

## Builder vs Viewer（必先區分）

| 角色 | 是誰 | 是該領域 peer 嗎 |
|---|---|---|
| **Builder** | 用 meta-harness 顧問身分設計 target repo 的工程師 | 通常是工程 peer，看得懂工程術語 |
| **Viewer** | 每天跑 target repo 指令、看結果做決定的人 | **未必是 target 領域的 peer**——常常正是因為不是 peer 才需要 AI 補位 |

`ai-infra-management` 業主自己 = builder + viewer 同一人；
會計系統可能：工程師 = builder、會計助理 = viewer；
醫療輔助：工程師 = builder、醫師助理 = viewer。

**支柱 12 對象是 viewer，不是 builder**。

## 為什麼獨立成支柱（不併入 R-6）

- R-6（不用未解釋專有名詞 / 縮寫）= 行為紀律「**該怎麼寫**」，顆粒度小
- 支柱 12 = 機制設計「**翻譯層怎麼蓋**」，決策面豐富
- 兩者分工：R-6 是 floor，支柱 12 是 architecture

## 設計決策

### 1. Viewer 識別（必跑）

- 這 target 有幾種 viewer？（單一 / 多角色，例會計系統可能 viewer = 會計助理 + 月結會計師 + 老闆三層）
- 各 viewer 在哪些子領域是 peer、哪些是非 peer？（例業主在 infra ops 是非 peer 但在自家業務邏輯是 peer）
- viewer 識別錯了 → 翻譯層做白工 / 沒做到

### 2. 翻譯誰負責

- **main agent 自翻**：簡單但容易漏（同一 agent 寫產出又翻譯，可能省事跳過）
- **專門 translator sub-agent**：分工乾淨、強保證；多一次 sub-agent 呼叫成本
- **後處理 hook**：output 後攔截改寫；schema 風險（hook 改 output 容易壞）
- **command markdown 內硬規則**：寫進 `.claude/commands/<x>.md` Stage 5，靠 main agent 守紀律（弱保證但零成本）

### 3. 翻譯時機

- **Draft 前**：persona / sub-agent 一開始就被 priming 「對 viewer 講話」
- **Output 後**：peer 對 peer 討論用術語、最終整合給 viewer 才翻譯
- 出口翻譯（Output 後）通常更乾淨——保留 peer 對話 transparency + 給 viewer 可讀版

### 4. 翻譯深度

- **術語表 lookup**：詞典式 1:1 替換 / 括號展開
- **整段重寫**：每個 viewer-facing 段落重寫成白話
- **雙層輸出**：raw（peer 術語）+ translated（viewer 白話）並陳，viewer 想 dig 可展開 raw

### 5. 翻譯顆粒度

- **per-command** 各自寫 Stage 5 翻譯紀律
- **per-output 段落** 細粒度標記哪段給 viewer、哪段給 builder
- **global** 全 target 統一翻譯規格

### 6. Viewer 能力模型

- viewer 在哪些領域是 peer / 非 peer 怎麼**追蹤**？（CLAUDE.md 寫死 / 動態 memory）
- 怎麼**更新**？（viewer 自己標「這詞我已經懂了」→ 之後不必再括號展開）
- 沒能力模型 = 每次都把 viewer 當零基礎，囉嗦 / 拖慢

### 7. Viewer 可讀性驗證

- viewer 給「這次輸出讀懂幾分」評分（1-5）
- 累積評分 < 4 的場次 → 抓 viewer comment 揭露的盲點調翻譯紀律
- 對位支柱 8 outer eval

### 8. 子軸：其他 viewer-facing 設計（v1 留 placeholder）

支柱 12 v1 聚焦「翻譯層」。其他 viewer-facing 軸後續展開：

- **回饋通道**：viewer 採納 / 拒絕 / 評分怎麼回灌系統（部分對位支柱 8 / 3 飛輪）
- **可中斷時機**：哪些動作前該停下來等 viewer 決定、哪些不必
- **授權邊界**：哪些 viewer 可以一鍵授權批次、哪些必逐次確認
- **多 viewer persona**：同 target 多角色 viewer 各自的視角 / 權限 / 翻譯深度

## 跟其他支柱的耦合

| 支柱 | 耦合點 |
|---|---|
| 3 Memory | viewer 能力模型 / 看得懂的詞庫累積進 memory |
| 8 Eval | viewer 可讀性評分 = outer eval 訊號 |
| 9 觀測 | 兩者對稱：9 = system-facing IO、12 = viewer-facing IO |
| 10 Multi-agent | 多 viewer persona / translator sub-agent |
| R-6（規則層） | R-6 是 floor，支柱 12 是 architecture |

## 反模式

### 1. Builder / Viewer 不分
「業主」「user」混用 → 翻譯層該寫不該寫不清楚 → 多數時候漏寫

### 2. 把 viewer 當 builder
peer 對 peer 用術語直丟 viewer = jargon 牆 = viewer 看不懂等於沒做

### 3. 把 viewer 當零基礎
每個術語都解釋 = 囉嗦 = viewer 嫌煩 = 失去信任。沒能力模型 / 沒記住 viewer 已熟詞會踩

### 4. 翻譯只做表面
只展開術語縮寫、保留 jargon priority 代號（P0a / P1）/ persona 名稱 = 半個翻譯

### 5. 翻譯遮蓋 transparency
為了給 viewer 看就把 peer 辯論原文砍掉 = 失 transparency 防線。應**並陳**（翻譯版 + 折疊 peer 原文）

### 6. 翻譯層做進 persona
讓 persona 同時對 peer 對話又對 viewer 翻譯 → persona 角色錯亂、辯論軟化。翻譯該是後處理層，不是 persona 內責任

### 7. 沒 viewer 可讀性驗證
做了翻譯但沒人量「viewer 真的讀懂了嗎」→ 翻譯做白工不知道
