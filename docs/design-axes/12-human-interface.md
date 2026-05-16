# 設計軸 12：Human Interface

target repo 跑出來的東西**給誰看**。和「給工程師 / 系統看」的設計軸 9 觀測對稱——設計軸 9 是 system-facing IO 邊界，設計軸 12 是 **human-facing** IO 邊界。

## Builder vs Human（必先區分）

| 角色 | 是誰 | 是該領域 peer 嗎 |
|---|---|---|
| **Builder** | 用 meta-harness 顧問身分設計 target repo 的工程師 | 通常是工程 peer，看得懂工程術語 |
| **Human** | 每天跑 target repo 指令、看結果做決定的人 | **未必是 target 領域的 peer**——常常正是因為不是 peer 才需要 AI 補位 |

`ai-infra-management` 業主自己 = builder + human 同一人；
會計系統可能：工程師 = builder、會計助理 = human；
醫療輔助：工程師 = builder、醫師助理 = human。

**設計軸 12 對象是 human，不是 builder**。

## 為什麼獨立成設計軸（不併入 R-6）

- R-6（不用未解釋專有名詞 / 縮寫）= 行為紀律「**該怎麼寫**」，顆粒度小
- 設計軸 12 = 機制設計「**翻譯層怎麼蓋**」，決策面豐富
- 兩者分工：R-6 是 floor，設計軸 12 是 architecture

## 設計決策

### 1. Human 識別（必跑）

- 這 target 有幾種 human？（單一 / 多角色，例會計系統可能 human = 會計助理 + 月結會計師 + 老闆三層）
- 各 human 在哪些子領域是 peer、哪些是非 peer？（例業主在 infra ops 是非 peer 但在自家業務邏輯是 peer）
- human 識別錯了 → 翻譯層做白工 / 沒做到

### 2. 翻譯誰負責

- **main agent 自翻**：簡單但容易漏（同一 agent 寫產出又翻譯，可能省事跳過）
- **專門 translator sub-agent**：分工乾淨、強保證；多一次 sub-agent 呼叫成本
- **後處理 hook**：output 後攔截改寫；schema 風險（hook 改 output 容易壞）
- **command markdown 內硬規則**：寫進 `.claude/commands/<x>.md` Stage 5，靠 main agent 守紀律（弱保證但零成本）

### 3. 翻譯時機

- **Draft 前**：persona / sub-agent 一開始就被 priming 「對 human 講話」
- **Output 後**：peer 對 peer 討論用術語、最終整合給 human 才翻譯
- 出口翻譯（Output 後）通常更乾淨——保留 peer 對話 transparency + 給 human 可讀版

### 4. 翻譯深度

- **術語表 lookup**：詞典式 1:1 替換 / 括號展開
- **整段重寫**：每個 human-facing 段落重寫成白話
- **雙層輸出**：raw（peer 術語）+ translated（human 白話）並陳，human 想 dig 可展開 raw

### 5. 翻譯顆粒度

- **per-command** 各自寫 Stage 5 翻譯紀律
- **per-output 段落** 細粒度標記哪段給 human、哪段給 builder
- **global** 全 target 統一翻譯規格

#### 翻譯範圍：Input 端 + Output 端皆要（從 ai-infra-management v1 業主反饋學到）

viewer-facing IO **不只結果輸出**。設計時必檢查以下清單全部翻譯：

| 範圍 | 例子 | 漏翻的後果 |
|---|---|---|
| 結果輸出（results） | `/advise` 跑完最終建議 | 已知範圍（子設計軸 4 翻譯深度已 cover）|
| **命令描述（command description）** | `.claude/commands/<x>.md` 第一行 description；`/<cmd>` 自動補全顯示文字 | **業主猜錯用法 → 命令等於不存在**（業主把單專案 `/advise` 誤以為跨專案一次診斷） |
| Help text | `/help` 顯示內容、`--help` 顯示文字 | 業主不知道怎麼用 |
| Error message | 出錯時 stderr 輸出 | 業主不知道怎麼救 |
| 自動補全 hint | sub-command / option 提示 | 業主錯過進階用法 |
| 反饋 prompt 本身 | 強制收評分時的問句（如 Stage 5.5「跑完印象 1-5 分」） | 業主跳過 / 答錯方向 |

R-6 範圍 (c) 條對應此清單——任何 viewer 會接觸到的介面文字都該守翻譯紀律。

### 6. Human 能力模型

- human 在哪些領域是 peer / 非 peer 怎麼**追蹤**？（CLAUDE.md 寫死 / 動態 memory）
- 怎麼**更新**？（human 自己標「這詞我已經懂了」→ 之後不必再括號展開）
- 沒能力模型 = 每次都把 human 當零基礎，囉嗦 / 拖慢

### 7. Human 可讀性驗證

- human 給「這次輸出讀懂幾分」評分（1-5）
- 累積評分 < 4 的場次 → 抓 human comment 揭露的盲點調翻譯紀律
- 對位設計軸 8 outer eval

### 8. 回饋通道（feedback loop）

**核心 insight**：迭代主動方是 **builder**，human 只當**訊號源**。human 不該被要求改 git / 改 prompt / 寫 issue——他不會、也不該負責。

```
human 行為 / 反饋
  ↓ (捕捉訊號)
tracking jsonl / 行為 log / 評分
  ↓ (累積到門檻 trigger)
builder 跑 retrospective
  ↓ (消化訊號)
改 prompt / 改 wiring / 加 persona / 補 incidents.md
  ↓
下次 human 跑就用到新版
```

#### 5 個子設計軸

| 子軸 | 設計題 | 例 |
|---|---|---|
| **捕捉** | 怎麼收 human 訊號？ | 強制評分 / 行為偵測 / 對話解析 |
| **累積** | 訊號落哪、用什麼 schema？能 query 嗎？ | `decisions/<x>-tracking.jsonl` append-only |
| **trigger** | 什麼條件下叫 builder 來消化？ | 評分 < 4 累積 N 筆 / 同類 comment 反覆出現 |
| **消化** | builder 用什麼工具看訊號 / 怎麼變動作？ | `/retrospective` slash command / 自動 prompt evolve |
| **回灌** | 改完怎麼讓下次 human 跑就用到新版？ | 無感升級 / 公告變更 / version bump |

#### 5 種捕捉機制（從 human 友善度排）

| # | 機制 | human 非工程師友善 | 對位設計軸 |
|---|---|---|---|
| 1 | **強制評分**：每次 command 末尾固定問 1-5 分 + 一句評語，main agent 自動寫 tracking | ✅ 高 | 12 |
| 2 | **採納行為訊號**：hook 偵測 human 後續是否跑了建議命令、是否被改寫，自動 mark `accepted` | ✅ 高（human 無感） | 7 + 12 |
| 3 | **自然語言對話解析**：human 下次說「上次那個 X 我沒做因為 Y」，main agent grep tracking 找對應 id 補 outcome 欄 | ✅ 高（對話介面內） | 12 |
| 4 | **Batch retrospective**：累積 N 筆後跑 `/retrospective` 看哪類常被拒、哪 persona 評分低 | ❌ 需 builder 跑 | 8 outer eval |
| 5 | **Prompt 自我迭代**：累積 < 4 分 comment 達門檻 → 自動 prompt builder「persona X 常被嫌看不懂，要不要改」 | ❌ 需 builder 介入 | 8 + 12 |

#### human 非工程師時的硬規則

- **機制 1-3 必硬編進設計**（不能假設 human 會手動回報）
- **機制 4-5 該設計自動 trigger**（不是被動等 builder 主動想到）—— builder 該「**被訊號累積叫來**」而非「自己想起來去看」
- **builder 不存在的 target 不該設計**——這是結構問題不是 mechanism 能救的；Phase 0 必確認「這 target 有沒有持續維護人」

#### 回饋流失發生在三處

| 處 | 症狀 | 用什麼擋 |
|---|---|---|
| **沒捕捉** | human 跑完直接走、沒留評分 | 機制 1 強制評分（Stage 5 末尾必收）|
| **沒消化** | tracking 堆滿沒人看、accept 欄位永遠 null | 機制 4-5 自動 trigger builder |
| **沒回灌** | builder 改了 prompt 但 human 還在用舊版 | 設計時就含版本 bump / SessionStart 載最新版 |

### 9. 多 human persona + 內容粒度光譜

**核心 insight**：human 不是 binary（peer vs 非 peer），是**多維度光譜**——同 target 可能有多種 human 角色（資深會計師 / 初級會計師 / 老闆 / 稽核員），各自在不同子領域熟悉度不同、看分析時需要的**內容粒度**也不同。

#### 翻譯深度 vs 內容粒度（兩維度，不可混為一談）

| 維度 | 是什麼 | 例（會計系統） |
|---|---|---|
| **翻譯深度**（子軸 4 已設計） | 術語要不要白話、要不要括號中文 | 「accrual（應計制）」vs「應計」vs 不解釋 |
| **內容粒度**（本子軸新議題） | 給多深的分析、多少細節、不同決策層級要哪類訊息 | 老闆要「結論+利潤+風險」、資深會計要「策略+異常+趨勢」、初級會計要「逐筆 verify+程序」 |

翻譯深度解決「字看不看得懂」；內容粒度解決「**這個層級的人需不需要這份訊息**」。資深會計師不需要逐筆程序、初級會計師看不懂策略含義——同一份財報該**多層輸出**。**只蓋翻譯不蓋粒度** = 資深嫌囉嗦 + 初級卡關。

#### 設計輪廓

```
[Analysis 完成]
  ↓
main agent 識別 human 角色 + 子領域熟悉度
  ↓
按角色 + 熟悉度選輸出層：
  - 層 1 老闆視角：結論 + 預算 + 風險（200-300 字）
  - 層 2 決策者視角：決策 + 後果 + 折衷（800 字）
  - 層 3 執行者視角：具體動作 + 為什麼（2000 字）
  - 層 4 深度技術視角：含 implementation detail（完整）
  ↓
預設輸出對應層 + 其他層摺疊
human 可在對話中說「更深 / 更淺」動態切換
```

#### 關鍵 mechanism：human profile

每 target 該建 `docs/human-profile.md`（或同義位置）列：

| 欄位 | 內容 |
|---|---|
| **角色** | 資深會計 / 初級會計 / 老闆 / 稽核員 / ... |
| **領域熟悉度光譜** | 在哪些子領域是 peer / 哪些非 peer（如：會計但稅務不熟） |
| **看什麼決定** | 不只看訊息，看「**我這個位子需要拿這份訊息做什麼決定**」 |
| **預設輸出層** | 對應上面 4 層哪一層 |
| **特殊紀律** | 例如老闆角色強制隱藏 implementation detail |

session start 時 auto-inject human-profile.md → main agent 對話開頭識別「你是哪個角色」（從 auto-memory 抓 / human 自己標 / 路徑推斷）→ Stage 5 翻譯 + 粒度同時調整。

#### 反模式

- ❌ **只設計一層 human**：所有 human 用同個翻譯深度 + 同個內容粒度 = 撞「資深嫌囉嗦 / 初級卡關」雙重失敗
- ❌ **只蓋翻譯不蓋粒度**：術語白話化了，但內容深度沒分層 = 資深會計看到滿頁括號中文的「accrual（應計制）」嫌煩
- ❌ **只蓋粒度不蓋翻譯**：分層輸出但每層都用 peer 術語 = 老闆看到「結論+利潤」但每個字都不懂
- ❌ **角色寫死不能動態切換**：human 在同 session 中可能要切換角色（老闆看完結論想 dig 細節）= 設計時就該支援「更深 / 更淺」動態指令

### 10. 其他 human-facing 子軸（v1 留 placeholder）

- **可中斷時機**：哪些動作前該停下來等 human 決定、哪些不必
- **授權邊界**：哪些 human 可以一鍵授權批次、哪些必逐次確認

## 跟其他設計軸的耦合

| 設計軸 | 耦合點 |
|---|---|
| 3 Memory | human 能力模型 / 看得懂的詞庫累積進 memory |
| 8 Eval | human 可讀性評分 = outer eval 訊號 |
| 9 觀測 | 兩者對稱：9 = system-facing IO、12 = human-facing IO |
| 10 Multi-agent | 多 human persona / translator sub-agent |
| R-6（規則層） | R-6 是 floor，設計軸 12 是 architecture |

## 反模式

### 1. Builder / Human 不分
「業主」「user」混用 → 翻譯層該寫不該寫不清楚 → 多數時候漏寫

### 2. 把 human 當 builder
peer 對 peer 用術語直丟 human = jargon 牆 = human 看不懂等於沒做

### 3. 把 human 當零基礎
每個術語都解釋 = 囉嗦 = human 嫌煩 = 失去信任。沒能力模型 / 沒記住 human 已熟詞會踩

### 4. 翻譯只做表面
只展開術語縮寫、保留 jargon priority 代號（P0a / P1）/ persona 名稱 = 半個翻譯

### 5. 翻譯遮蓋 transparency
為了給 human 看就把 peer 辯論原文砍掉 = 失 transparency 防線。應**並陳**（翻譯版 + 折疊 peer 原文）

### 6. 翻譯層做進 persona
讓 persona 同時對 peer 對話又對 human 翻譯 → persona 角色錯亂、辯論軟化。翻譯該是後處理層，不是 persona 內責任

### 7. 沒 human 可讀性驗證
做了翻譯但沒人量「human 真的讀懂了嗎」→ 翻譯做白工不知道
