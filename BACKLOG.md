# Backlog（未消化的失敗）

> **本檔人類維護用，consultant skill 不應 Read**。含具體案例 token、被顧問載入會污染當前 session。已消化的教訓在 `docs/universal-care-rules.md` R-1~R-7 / `docs/pillars/` / SKILL 反模式段。

只記**還沒消化進結構**的失敗。一旦對應 rule / hook / template 落地 → 從本檔刪掉（不留紀念碑）。

---

## 待消化

### R-6 自律失效（4 題塞滿 + 內部分類詞 + 縮寫）
失敗：AskUserQuestion 一次塞滿 4 題、用未解釋分類詞當題目標題。SKILL 反模式段已寫但顧問未自查。
修法候選：UserPromptSubmit hook 在 AskUserQuestion 送出前掃題目 / 選項文字，未解釋英文 / 縮寫超過 N 個 → 警告。

### Memory ↔ Eval 飛輪：prescription template 沒強制兩者對映
失敗：兩條任一缺，另一條退化（沒 eval 的 memory 變垃圾、沒 memory 的 eval 沒輸入）。
現況：pillars/3-memory.md + pillars/8-evaluation-loop.md 寫了，但 prescription template 沒互引必填欄位。
修法候選：prescription Part C「memory」與「eval」段加 cross-link 必填。

### 支柱現況評估：覆蓋寬度 × 強度（非 0/1）
失敗：「outer eval 沒做」不夠精準——可能 inner 做一半、postmortem 半結構化。
現況：prescription Status 欄仍多 binary。
修法候選：prescription Part C 每條 status 改「覆蓋: low/med/high × 強度: prompt-only/hook/runtime-verified」二維。

### Hooks 是其他支柱的實作機制
失敗：把 hooks 當獨立支柱，沒看到它**承載**其他支柱的 mechanism。
現況：pillars/7-hooks.md + prescription Mechanism 段提了，仍常忘。
修法候選：每條 pillar spec 顯式加「mechanism via: prompt / hook / runtime」必填欄。

### Audit / observability 與入口 `exec` 互斥
失敗：harness 主入口若 `exec "$action_script"` 收尾，所有 post-hook 都不可能跑。
現況：pillars/9-observability.md 反模式條目寫了，設計時顧問不會主動點。
修法候選：prescription template Part D Hook installations 段加「入口若用 exec 無 post-hook」前置 check。

---

## 寫入紀律

- 新觀察 = 一個段落（標題 = 失敗一句話、內文 = 失敗 / 現況 / 修法候選）
- 對應 rule / hook / template 落地 → 從本檔刪掉
- 不留「✅ 已消化」紀念碑（git history 有）
- 不用編號（標題即 anchor）

## 半年回顧

每半年 review：躺 6 個月還沒消化的——是真不重要（刪），還是規則沒設計好（升 design session 主題）。
