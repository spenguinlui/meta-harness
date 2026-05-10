# 支柱 8：Evaluation loop

最容易被忽略、但對「能否系統化改進」決定性最大的一條。分兩層，性質完全不同。

## 兩層結構

### Inner eval（單次任務內、即時）

**目的**：模型做完一步立刻驗證，錯了能即時修。

**特徵**：
- 同 session 內發生
- 自動化、快、便宜
- 失敗回灌 context 讓模型重試或改方向
- 屬於 execution loop 的一環

**範例**：
- 寫完 code → 跑 test / type check / lint
- 改完 SQL → 跑 EXPLAIN
- 動完 infra → inspect 確認狀態
- 呼叫完 API → 檢查 response schema

### Outer eval（跨任務、離線）

**目的**：衡量整個 harness 能力。改 prompt / 換 model / 加 skill 時知道是變好還是變壞。

**特徵**：
- 跨 session、跨時間
- 預先建好任務集
- 需要打分機制
- 用於 harness 版本比較

**範例**：
- 收集 50 個歷史任務 → 跑新版 prompt → 比較 pass 率
- SWE-bench
- 收集成功 operation → 換 model 後是否還能正確規劃

| 軸 | Inner | Outer |
|---|---|---|
| 何時跑 | 任務進行中 | 任務後 / CI |
| 對誰負責 | 這次任務 | harness 本身 |
| 失敗後果 | 模型 replan | 工程師 replan harness |

沒 inner = 單次不可靠。沒 outer = 改 harness 沒依據。

## Inner eval 設計決策

### 1. 觸發點
- 副作用大的動作
- 可逆性低的動作
- 後續會依賴的動作
- 純 read 不必 verify

### 2. 驗證強度
從輕到重：
1. Tool 回傳值（最便宜）
2. Schema 檢查
3. 語意檢查（值合理嗎）
4. 獨立查詢（重新讀對比）
5. 下游影響（跑 test）

驗證強度 ≈ 出錯後的修復成本。

### 3. 失敗處理
- Retry
- Replan
- Halt + ask
- Continue with warning

預設 halt+ask；自動化高偏 retry/replan。

### 4. 驗證者
- 規則（lint / schema / test）：便宜確定
- LLM-as-judge：主觀任務必要
- Self-verify：便宜但有偏差
- 人類：高 stakes 必要

**反模式**：同一 model 自評還大膽相信。

## Outer eval 設計決策

### 1. 任務集來源
- 歷史成功（不退步）
- 過往失敗（學會不重犯）
- 挑戰集（cover 邊界）
- 公開 benchmark

對 domain harness 最有 ROI 是「歷史成功 + 過往失敗」混合。

### 2. 規模
- 冒煙：5-10（commit 級）
- 回歸：30-100（nightly）
- 完整：>500（release 前）

少於 5 沒統計意義，多於 100 跑不起。

### 3. 評分
從硬到軟：
1. Exact match
2. Diff-based
3. 行為驗證（產出能跑能 pass test）
4. Rubric scoring（多軸 LLM 評）
5. Pairwise（誰更好）

行為驗證是 sweet spot——比 exact 寬容、比 LLM judge 客觀。

### 4. 對比基準
- 跟自己上一版（regression，最常用）
- 跟最強配置（best of breed）
- 跟人比（human baseline）

### 5. 失敗分類
跑完一輪必須分類，否則「失敗 23%」沒法改進：
- Model 錯 → 換 model / 改 prompt
- Harness 錯 → 改 harness
- 環境錯 → 修 fixture
- 規格不清 → 修 eval set 或標 unscored

## 跟其他支柱的耦合

### 跟 Memory（核心飛輪）
- Outer fail → 寫 memory「下次注意」
- Memory 累積 → outer 驗哪些有效，淘汰沒用的
- 沒 eval 的 memory = 噪音堆

### 跟 Planning
- Plan 預設「成功的驗收標準」= inner eval
- 沒驗收條件 = 做完不知對錯

### 跟 Tool
- Tool 回穩定可驗的輸出，eval 才寫得出
- Tool 該標「成功怎麼判」

### 跟 觀測
- 觀測給 trace（怎麼做）；eval 給分數（做得對嗎）
- 沒觀測的 eval：知道 fail 不知為何

## 反模式

### 1. 只看 vibes
沒 eval set 全憑印象。改了東西無法回頭比。

### 2. Eval set = production task
拿正式任務當 eval 會被個案污染。eval set 要獨立、穩定、版本化。

### 3. LLM judge 自評
同 model 既做事又評分，分數虛高。換 model 評，或規則化。

### 4. 只記分不分類
失敗率 30% 不知哪類。三個月後還是 30%。

### 5. 只 inner 沒 outer
覺得「每步都驗就夠」——但你不知整體勝率。inner 驗局部，outer 驗整體。

### 6. Outer 太重啟動不起來
追求 100 個完美 case 結果 0 個。先做 5 個粗的，跑起來再加。

### 7. Eval 跟 production 不對齊
eval 都過了 production 還是出包。eval set 要從 production 抽。

### 8. Eval 不版本化
改了 eval 又改了 harness，分數變化不知是誰的功勞。eval set 改動該獨立 commit。

