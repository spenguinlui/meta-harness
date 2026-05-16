# 設計軸 3：Memory 管理

跨 session 的持續知識。和 context 不是同一件事——context 管「這次怎麼塞」，memory 管「下次還在不在」。

## 多軸分類（2026 業界共識，**不是只一條 scope 軸**）

業界 de facto framework：CoALA paper (arXiv:2309.02427) + 2025/12 survey 升級為 **3 正交軸**（Form × Function × Dynamics）。實務上設計 target memory 該至少跨 **4 軸**思考，每軸選擇形狀；單看「scope」會踩反模式（業主常把所有東西全塞 user-scope auto-memory）。

### 軸 A：Content type（內容類型，認知科學分類）

| 類型 | 是什麼 | 例子 |
|---|---|---|
| **Working memory** | 當前 session 的短期暫存 | TaskList、當前 plan、in-flight 對話 |
| **Episodic**（事件記憶） | 過去發生的事 / 互動紀錄 | advise 全文紀錄、過去 incident、commit history |
| **Semantic**（事實知識） | 客觀事實 / 知識 / 名單 | 客戶清單、價格表、`docs/concepts.md`、業界 tool landscape |
| **Procedural**（流程規則） | 怎麼做事的規則 | system prompt、skill `.md`、settings.json、hook 邏輯 |

**LangGraph/LangMem 明確警告**：procedural **不該全塞 memory store**，它本質是「prompt + code + weights」。

### 軸 B：Scope（誰能看到）

| 層 | 範圍 | 例子 |
|---|---|---|
| Session | 單 session | TaskList、當前 plan |
| Project | 跟 repo 走、團隊共用 | CLAUDE.md、AGENTS.md、settings.json |
| User | 個人、跨專案 | `~/.claude-work/.../MEMORY.md` |
| Shared/world | 團隊知識庫 / 跨組織 | runbook、ADR、RAG corpus |

### 軸 C：Storage form（儲存形態）

| 形態 | 適合什麼 | 取捨 |
|---|---|---|
| **File**（markdown / json） | 小量、可讀、易 grep | 規模大就慢 |
| **Vector DB** | 語意檢索、模糊召回 | 多 hop 查詢弱 |
| **Graph DB** | 關係查詢、多 hop traversal | 寫入成本高 |
| **Parametric** (model weights) | 內化、隱式 | 不可控、不可審 |
| **Latent**（中間 hidden state） | 跨步驟保留 | 不可解釋 |

2026 主流：vector + graph **hybrid**（Graph-RAG 68.4% vs vector-only 66.9% LLM score）。

### 軸 D：Access pattern（取用模式）

| 模式 | 何時取用 |
|---|---|
| **Auto-inject** | session start 自動載（CLAUDE.md、MEMORY.md 索引） |
| **Explicit recall** | 主動 grep / Read 特定路徑 |
| **Agent-driven tool call** | sub-agent 自主查詢（RAG / DB query） |

---

## 業界 framework 對位（你下次設計時可選 reference）

| Framework | Memory model | URL（抓取 2026-05-12） |
|---|---|---|
| **CoALA**（學術 de facto） | working + episodic + semantic + procedural × internal/external action | https://arxiv.org/abs/2309.02427 |
| **Anthropic 官方 memory tool** | file-based `/memories` + context-management beta；強調 deliberate bootstrapping | https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool |
| **Anthropic effective harnesses** | progress log + feature checklist + init script，不要 ad-hoc 寫入 | https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents |
| **LangGraph/LangMem** | short-term thread state + long-term namespace；procedural = prompt+code+weights | https://docs.langchain.com/oss/python/langgraph/memory |
| **Letta/MemGPT** | 3-tier OS 類比：core (RAM) / recall (raw history) / archival (processed) | https://docs.letta.com/concepts/memgpt/ |

---

## 分流原則（哪類訊息該落哪格）

設計 target repo 時逐項問：

| 訊息類別 | Content type | 該落哪 Scope | 該用什麼 Storage form | 反模式 |
|---|---|---|---|---|
| 個人風格偏好（不用 jargon） | Procedural | User | File（`~/.claude-work/memory`） | 寫進 project memory 強迫團隊接受 |
| 團隊規則（hook 邏輯、CLAUDE.md） | Procedural | Project | File（git tracked） | 塞 user memory 換人接手斷層 |
| 過去 advise 全文紀錄 | Episodic | Project | File `decisions/<id>-debate/` | 落 `/tmp/`（開機就清=沒落地） |
| 客戶 / 資源清單 | Semantic | Project / Shared | File（小）/ Vector DB（大）| 全塞 user memory |
| 業界 best practice / tool landscape | Semantic | Shared | 即時 WebSearch + 緩存 file | 寫死成靜態 list（會撞作者知識上限）|
| 當前 task 狀態 | Working | Session | TodoWrite / 主對話 | 寫進跨 session memory |
| 過去類似 plan template | Procedural / Episodic 混 | Project | File（git tracked）| 每次重新發明 |
| 業主給的 ad-hoc 指令 | Procedural | User（個人偏好）/ Project（團隊規則） | 看 scope 決定 | 不分層全塞同一檔 |

---

## 設計決策

### 1. 寫入觸發
- **明確觸發**：用戶說「記下這個」
- **自動觸發**：模型判斷重要 → 寫
- **事件觸發**：某類動作後強制寫（destructive 操作後寫 ADR）
- **失敗觸發**：eval 失敗自動歸檔

預設「明確 + 事件」，「自動」要小心會堆積垃圾。

### 2. 寫入分類
分類學決定後續召回效率。常見：
- `fact` — 客觀事實
- `preference` — 用戶偏好
- `decision` — 為什麼選 A 不選 B
- `failure-lesson` — 踩過的坑
- `reference` — 外部系統指標

每類有不同 TTL、不同召回時機。

### 3. 寫入格式
- 自由文字：寫得快、召回難
- 結構化（frontmatter + body）：寫得慢、可索引可過濾
- 混合：metadata 結構化、內容自由

中型 repo 推薦結構化 + 自由 body。

### 4. 讀取策略
- **全載**：所有 memory 進系統 prompt（小規模可用）
- **索引**：MEMORY.md 列摘要，按需讀全文（Claude Code 的做法）
- **語意召回**：embedding 找相關（規模大才需要）
- **規則召回**：tag/category 過濾

### 5. TTL 與失效
- 永久：用戶身分、團隊習慣
- 中期：當前專案目標
- 短期：「升級進行到 phase 3」這種會過期
- 失效機制：時間 / 條件 / 手動標記

沒有 TTL 設計 = memory 變垃圾場。

### 6. 衝突解決
新事實跟舊 memory 矛盾：
- 信現況（讀 code / state）
- 更新或刪除 memory
- 不要兩邊都留（會精神分裂）

### 7. 驗證
Memory 說 X 存在，用前要 grep 一下。Memory 是「過去某時為真」，不保證「現在為真」。

### 8. 隱私邊界
- User memory 不該寫公司機密（會跨 repo 流動）
- Project memory 不該寫個人偏好（會 commit 出去）
- 邊界清楚比節省精巧重要

## 設計決策

### 1. 寫入觸發
- **明確觸發**：用戶說「記下這個」
- **自動觸發**：模型判斷重要 → 寫
- **事件觸發**：某類動作後強制寫（destructive 操作後寫 ADR）
- **失敗觸發**：eval 失敗自動歸檔

預設「明確 + 事件」，「自動」要小心會堆積垃圾。

### 2. 寫入分類
分類學決定後續召回效率。常見：
- `fact` — 客觀事實
- `preference` — 用戶偏好
- `decision` — 為什麼選 A 不選 B
- `failure-lesson` — 踩過的坑
- `reference` — 外部系統指標

每類有不同 TTL、不同召回時機。

### 3. 寫入格式
- 自由文字：寫得快、召回難
- 結構化（frontmatter + body）：寫得慢、可索引可過濾
- 混合：metadata 結構化、內容自由

中型 repo 推薦結構化 + 自由 body。

### 4. 讀取策略
- **全載**：所有 memory 進系統 prompt（小規模可用）
- **索引**：MEMORY.md 列摘要，按需讀全文（Claude Code 的做法）
- **語意召回**：embedding 找相關（規模大才需要）
- **規則召回**：tag/category 過濾

### 5. TTL 與失效
- 永久：用戶身分、團隊習慣
- 中期：當前專案目標
- 短期：「升級進行到 phase 3」這種會過期
- 失效機制：時間 / 條件 / 手動標記

沒有 TTL 設計 = memory 變垃圾場。

### 6. 衝突解決
新事實跟舊 memory 矛盾：
- 信現況（讀 code / state）
- 更新或刪除 memory
- 不要兩邊都留（會精神分裂）

### 7. 驗證
Memory 說 X 存在，用前要 grep 一下。Memory 是「過去某時為真」，不保證「現在為真」。

### 8. 隱私邊界
- User memory 不該寫公司機密（會跨 repo 流動）
- Project memory 不該寫個人偏好（會 commit 出去）
- 邊界清楚比節省精巧重要

## 跟其他設計軸的耦合

| 設計軸 | 耦合點 |
|---|---|
| Eval | eval 失敗 → 寫 memory；memory 累積 → eval 驗證有效性。**飛輪核心**。|
| Planning | plan 該召回類似任務的 memory |
| Context | memory 召回後塞 context，要看 budget |
| Hooks | 寫入觸發常用 hook 實作 |
| Tool | destructive tool 完成後該強制寫 decision memory |

## 反模式

### 1. Memory 變日誌
- 什麼都記、不分類、不刪
- 三個月後召回噪音 > 訊號
- 要有寫入門檻：「下次會用到嗎？」

### 2. 沒 TTL 的進度記錄
- 「升級到 phase 3」永遠留著
- 升完了還在誤導模型
- 帶日期 + 完成後刪

### 3. Memory 跟 code 真相分離
- Memory 說「使用 ALB」，code 改用 NLB 沒同步
- 模型按 memory 行動 = 撞牆
- 用前驗證、用後更新

### 4. 把 memory 當文件
- 寫長篇大論
- 模型讀不完、人讀不完
- Memory 是 hint 不是 manual；長文寫進 docs

### 5. Memory 寫滿個人偏好但沒寫 why
- 「不要用 yarn」← 為什麼？
- 沒 why 之後遇到邊界 case 不知能否破例
- 寫 rule 必附 reason

### 6. 全靠 user memory 撐 project knowledge
- 團隊 / 跨 session 重要的東西放個人 memory
- 換人接手 = 知識斷層
- Project-relevant 必須 commit 進 repo

### 7. 不分層
- 個人偏好寫 CLAUDE.md（強迫團隊接受）
- 團隊規則寫 user memory（其他人看不到）
- 邊界搞錯整個 memory 系統失效

### 8. Reasoning artifact 落 `/tmp/`（**從 ai-infra-management v1 學到**）
- AI 跑完 sub-agent 辯論 / draft 推理過程把全文丟 `/tmp/<x>/`
- `/tmp/` 開機就清 = 跨 session 看不到 = memory 沒落地
- 本質是「episodic memory（事件記憶）落不對 scope+storage 組合」：應該落 project scope + git tracked file（`decisions/<id>-debate/`），不是 ephemeral 暫存
- 業主自發補的解：移 `decisions/advise-<advise_id>-debate/` 永久保留

### 9. 過度依賴 user-scope auto-memory（**從業主原話「不要把所有東西都存進 Claude MEMORY」學到**）
- Claude auto-memory（`~/.claude-work/memory`）按 CoALA 分類 = user-scope file-based，**只該裝個人 procedural memory**（你的習慣 / 用詞偏好 / 跨專案紀律）
- **不該裝**：episodic（事件→`decisions/`）、大量 semantic（事實→`docs/`）、project-scope procedural（團隊規則→git）
- 全塞 user memory 的代價：換人接手知識斷層、跨專案污染、git 看不到、團隊看不到、無法 audit
- 寫入前自問：「這條離開我這個人還對嗎？離開這 session 還對嗎？」決定 scope

### 10. Auto-memory 變終點而非孵化層（**Claude Code 預設行為的結構性傾向**）
- Claude Code 預設 prompt 鼓勵 AI 看到「值得記住的偏好」就寫 user-scope auto-memory——但沒分流判準告訴 AI「這該存 user memory 還是該升 git docs/」
- 後果：規則卡在 user memory 永遠不升級，team 接手看不到、跨 fork 不共用
- 對位機制本身的問題：「per-project user memory」hybrid scope（`~/.claude-work/projects/<path>/memory/`）讓「個人偏好」跟「專案知識」混存，AI 無 scope 判準 → 預設都往這塞

---

## Auto-memory 健康使用 pattern：孵化層 vs 成熟層

user-scope auto-memory 該當「**規則尚未成熟到升 universal rule 的孵化中介層**」，不該當「永久存放規則的終點」：

```
踩到某類失敗 → 寫 auto-memory 條目（孵化期）
            ↓ 累積跑過幾次驗證確實普世
            ↓
升 docs/universal-care-rules.md R-N（成熟期 / 跨 fork 共用）
            ↓ auto-memory 該條目可砍或保留當「個人風格版」
```

**範例**（從 meta-harness session 學到）：
- `feedback_no_cross_layer_overreach`：踩過 → 寫 auto-memory → 確認跨類重複適用 → 升 R-8 ✅
- 升完 universal rule 後 auto-memory 條目仍保留也 OK（個人風格不衝突）

**判準（什麼時候該升 git）**：
- (a) 這條規則離開「我這個人」還對嗎？跨 user 還對 → 升 user-level `~/.claude/CLAUDE.md` 或 universal rule
- (b) 這條規則離開「這個專案」還對嗎？跨 project 還對 → 升 universal rule
- (c) 累積踩過幾次都吻合此規則 → 升 git
- (d) team 接手新人也該看到 → 升 git

**反向 pattern（避免）**：寫一次 auto-memory 就放著、永遠不 review 升級。這違反設計軸 3 反模式 #10「auto-memory 變終點」。

