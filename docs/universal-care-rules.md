# Universal Rules

跨任何 harness target repo 通用的衛生規則。Domain 無關——不論該 repo 在做 infra 管理 / ATDD / figma 轉 code / google sheet builder / 別的，都該守。

規則簡稱 **R-N**（Universal Rule 第 N 條）。

---

## R-1：CLAUDE.md ≤ 50 行（不含 fenced code block）
- **為什麼**：超出嚴重佔 context budget（Claude 每 session 載入額度）、cache 命中率掉
- **落地**：`grep -v '^\`\`\`' CLAUDE.md | grep -cv '^\`\`\`' | awk '$1 > 50'`

## R-2：設定規則放 committed 檔
- **為什麼**：gitignored 路徑「完成」是幻覺——改完無法 commit、新 session / fresh clone 看不到
- **規則**：`.claude/settings.json` = 團隊規則（入版控）；`.claude/settings.local.json` = 個人 override（gitignored）
- **落地**：`git status` 確認 settings.json 在版控

## R-3：每個 hook ≤ 100 行
- **為什麼**：hook 同步執行影響延遲；複雜邏輯抽 `bin/hook-helpers/<name>.sh`，hook 自身只做分派
- **落地**：`wc -l .claude/hooks/*.sh`

## R-4：文件 / plan 不允許流暢編造（fluent fabrication）
- **定義**：LLM 寫出讀起來流暢、看似真實但實為虛構的內容（捏造 metric 值 / cost 數字 / 不存在的資源 ID / API endpoint）
- **為什麼**：讀者錨定在虛構直到「等等，這個東西根本不存在」存在性危機
- **規則**：所有具體範例必引真實 inspect / log / API 輸出。無證據時必明標 `[FABRICATED — replace with real data before execution]`
- **落地**：plan review 抽樣校核資源 ID / metric / URL 對得上實際輸出

## R-5：提問 / 寫文件必錨到具體 artifact
- **為什麼**：拋抽象問題給使用者→「看不太懂」→ 設計選擇題滑成翻譯題
- **規則**：送出前自檢三條 —
  - (a) 名詞落到具體 artifact（檔案路徑 / 函式名 / 既有變數名）
  - (b) 不熟術語時能否用使用者剛剛講過的話替換
  - (c) 選項說明寫「選這個會發生什麼」而非設計者內部分類詞
- **失敗回應**：使用者回「看不太懂」時**不要解釋抽象概念**，重新用具體物件提問

## R-6：不用未解釋的專有名詞 / 縮寫
- **為什麼**：使用者被未解釋詞 / 縮寫打斷反問「這是什麼意思」→ 節奏崩
- **規則**：
  - 動詞 / 名詞優先中文（reconcile→對帳、sunset→收掉、backlog→待辦清單、fan-out→分派）
  - 縮寫首次出現必括號展開（ADR=Architecture Decision Record，架構決策紀錄）
  - 真要用英文（檔名 / API / 業界唯一指稱）首次出現括號中文
  - 已落到使用者自己常用的可繼續用
- **範圍三條都適用**：
  - (a) 顧問 ↔ builder 對話（meta-harness session 中）
  - (b) **target repo 跑出來、由 AI 給 human 看的最終輸出**（如 `/advise` `/audit` 等指令的回應）。human 通常不是該領域 peer（非 SRE / 非會計師 / 非醫師），peer-level jargon 直丟 human = 等於沒做
  - (c) **command description / help text / error message 等 viewer-facing 介面文字**（從 ai-infra-management v1 業主反饋學到）。human 在自動補全（`/<cmd>` 列表）/ `--help` / 出錯時讀這些 → 決定**用不用、何時用、出錯該怎麼救**。peer-level jargon 直丟 = 命令等於不存在 / error 等於無解。例：description 寫「External-knowledge advisor with 4-stage architect-debate pipeline」業主猜錯用法（誤以為「跨專案一次診斷」結果只跑單專案），命令對業主關閉
  - **機制怎麼蓋** = 設計軸 12 Human Interface；**R-6 是 floor，設計軸 12 是 architecture**

## R-7：wiring 升級不固化壞流程；fix 先找 root cause、不疊規則
- **定義**：wiring = 對 harness 行為的程式化約束（hook / skill / slash command / sub-agent / settings.json）
- **為什麼**：(a) 把當下踩過的壞流程加固成 enforcement 永久卡死；(b) 看到失敗就疊新規則 / 反模式段，會累積 1+1+1-1-1 補丁堆，越疊越脆
- **規則**：
  - 任何 wiring 落地前自問：「這把好習慣自動化嗎？」（OK）/「還是把當下踩過的壞流程加固成 enforcement？」（禁）
  - 任何 fix 前先 grep root cause：默認動作是**刪源頭**而非**疊蓋住症狀的規則**
- **落地**：
  - 新 wiring commit message 必含「自動化什麼好習慣」
  - 新規則 / 反模式段 commit 必含「為什麼不能刪源頭」；答不出 = 沒做 root cause 分析

## R-8：跨層越權禁止——自家層的問題在自家層修，不替別層表態
- **定義**：設計者 / 顧問 / 文件 / wiring 對「自家層級之外」（別 session / 別 repo / 別業主 / 別角色 / 別子系統的權限範圍）做命令式表態
- **為什麼**：把「自家 X」生硬對比成「所以對方該 Y」的二分 table = 越權替別層做選擇、剝奪對方自主性。R-7 管「自家當下 vs 未來」（時間軸），R-8 管「自家 vs 別層」（空間軸），兩條互補
- **典型踩法**（從 ai-infra-management v1 session 學到，2026-05-16）：
  - meta-harness README 寫「大腦 = Opus 4.7 / **手腳 = Sonnet（target 用）**」table
  - 「自家 = 大腦」陳述對，但生硬推論「對方 = 手腳所以用 X」就越權替 target repo 業主在 target session 內的 model 選擇表態
  - 業主原話「我會在選擇適合的 model」明示自主——meta-harness 不需替他預設
- **規則**：寫建議 / 文件 / 設計時自檢三條：
  - (a) 這條建議是對哪個 session / repo / 角色 / 子系統開？對「自家」OK；對「別層」必停
  - (b) 對立面（如「X 對 → Y 該」中的 Y）是不是另一層的權限範圍？是 → 砍掉或改單向陳述
  - (c) 有沒有用「自家 default」掩飾「跨層命令」？例：把「target 用 Sonnet」包裝成「meta-harness 的 default 假設」就是
- **落地**：「X 對 → Y 該」二分 table 看到先警覺；改成「自家 X」單向陳述 + 明示「對方層級自決，我不表態」

---

## Domain-specific 規則不放這裡

以下隨 target repo 不同，不入 universal：cache metadata（某 domain 沒 cache）、safety_level 分類（沒 mutating ops）、inventory `--refresh`（沒 inventory 概念）、skill schema 形式化（沒 skill 架構）。

domain 規則範例見 `cases/<target>-domain-rules.md`，套用走 `docs/prescription-template.md` Part C。
