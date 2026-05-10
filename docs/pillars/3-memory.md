# 支柱 3：Memory 管理

跨 session 的持續知識。和 context 不是同一件事——context 管「這次怎麼塞」，memory 管「下次還在不在」。

## 層級

| 層 | 範圍 | 例子 |
|---|---|---|
| Session memory | 單 session | TaskList、當前 plan |
| Project memory | 跟 repo 走、團隊共用 | CLAUDE.md、AGENTS.md、settings.json |
| User memory | 個人、跨專案 | ~/.claude-work/.../MEMORY.md |
| Shared/world memory | 團隊知識庫 | runbook、ADR、RAG corpus |

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

## 跟其他支柱的耦合

| 支柱 | 耦合點 |
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

