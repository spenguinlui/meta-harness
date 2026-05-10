# meta-harness

> **設計 AI agent harness 的方法論 + 顧問 wiring**
> Prompt engineering 改字；harness engineering 改模型周圍的整套系統。

## What

`meta-harness` 是「**harness 設計顧問（建築師）+ 施工器**」。業主提需求 → 顧問出設計圖 → review loop → 施工 → 驗屋。**不是** framework / CLI / 腳手架。

```
~/meta-harness session
   ├─ Step 1 需求討論（4 件事訪談 10-20 min）
   ├─ Step 2 顧問獨自出設計圖 → prescriptions/<date>-<target>.md
   ├─ Step 3 業主 review loop
   ├─ Step 4 分期施工 → 絕對路徑寫進 target repo
   └─ Step 5 驗屋（顧問代跑能自動驗的 + 業主跨交互）
```

## Why 顧問模式而非腳手架

最初直覺是 `meta-harness new <domain>` 產出標準目錄。深思後發現：11 支柱每條都是設計參數而非開關，且彼此耦合，沒有單一最佳搭配。

採顧問框架：對話 + pattern library + 設計圖為主體，腳手架降級為顧問結論的編譯產物。

被拒絕的兩條：
- 純腳手架：凍結一組搭配，對誰都不剛好
- 純顧問無載體：建議三天內忘光（要靠 wiring 落地，不只靠對話）

## How to use

```bash
cd ~/meta-harness && claude
# 第一句講：「我想設計 ~/<your-target-repo> 這個工具」
```

`consultant` skill 自動載入，按 5 步流程跑。詳 `.claude/skills/consultant/SKILL.md`。

## 核心

- **5 步業主-建築師流程** — `.claude/skills/consultant/SKILL.md`
- **11 大支柱（pattern library）** — `docs/pillars.md`
  Tool / Context / Memory / Planning / Execution / Safety / Hooks / Eval / Observability / Multi-agent / Triggers
- **7 universal rules（衛生規則）** — `docs/universal-care-rules.md`
- **設計圖格式** — `docs/prescription-template.md`

## Repo 結構

```
.claude/                顧問 wiring（hook + skill）
docs/
  pillars.md            11 支柱索引
  pillars/              每支柱深度
  universal-care-rules.md   R-1~R-7
  prescription-template.md  設計圖格式
cases/                  案例庫（gitignored — 各 fork 自家任務不交叉）
prescriptions/          施工前留痕（gitignored）
sessions/               對話歷史（gitignored）
BACKLOG.md              未消化失敗（gitignored — 各 fork 自家失敗）
```

## Status

**v0.3 — 建築師模型 + 顧問 wiring**

- ✅ 11 支柱完整（含 Multi-agent + Triggers）
- ✅ 7 universal rules（從污染累積中蒸餾）
- ✅ Consultant skill 鎖建築師身分 + 5 步流程
- ✅ Cwd-guard hook + R-1/R-3/R-5/R-6 enforce hook
- 🔄 跨 target 驗證中

## License

MIT
