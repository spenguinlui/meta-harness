# meta-harness

> **設計 AI agent harness 的方法論 + 顧問 wiring**
> Prompt engineering 改字；harness engineering 改模型周圍的整套系統。

## What

`meta-harness` 是「**harness 設計顧問（建築師）+ 施工器**」。業主提需求 → 顧問出設計圖 → review loop → 施工 → 驗屋。**不是** framework / CLI / 腳手架。

```
~/meta-harness session
   ├─ Step 1 需求討論（5 件事訪談 10-20 min）
   ├─ Step 2 顧問獨自出設計圖 → prescriptions/<date>-<target>.md
   ├─ Step 3 業主 review loop
   ├─ Step 4 分期施工 → 絕對路徑寫進 target repo
   ├─ Step 5 驗屋（顧問代跑能自動驗的 + 業主跨交互）
   └─ Step 6 飛輪 retrospective（跑一段時間後回看：outcome 沉澱 / 訊號累積 / memory 形狀 / 方法學缺口升級）
```

## Builder vs Human（兩種角色）

`meta-harness` 設計的 target repo 服務兩種角色——可能同人也可能不同人：

- **Builder**：用 meta-harness 顧問身分**設計**這個 target repo 的工程師（你看這份 README 的人）
- **Human**：每天跑 target repo 指令、看結果做決定的人；**未必是該領域 peer**（例：會計系統的 human = 會計助理而非工程師）

設計軸 12 Human Interface 專門設計 human 介面層（翻譯、粒度、回饋通道），對稱設計軸 9 觀測（給工程師 / 系統看）。設計時必區分——builder 看得懂 jargon、human 未必。

## Why 顧問模式而非腳手架

最初直覺是 `meta-harness new <domain>` 產出標準目錄。深思後發現：12 設計軸每條都是設計參數而非開關，且彼此耦合，沒有單一最佳搭配。

採顧問框架：對話 + pattern library + 設計圖為主體，腳手架降級為顧問結論的編譯產物。

被拒絕的兩條：
- 純腳手架：凍結一組搭配，對誰都不剛好
- 純顧問無載體：建議三天內忘光（要靠 wiring 落地，不只靠對話）

## How to use

```bash
cd ~/meta-harness && claude
# 第一句講：「我想設計 ~/<your-target-repo> 這個工具」
```

`consultant` skill 自動載入，按 6 步流程跑。詳 `.claude/skills/consultant/SKILL.md`。

## 核心

- **6 步業主-建築師流程** — `.claude/skills/consultant/SKILL.md`
- **12 大設計軸（pattern library）** — `docs/axes.md`
  Tool / Context / Memory / Planning / Execution / Safety / Hooks / Eval / Observability / Multi-agent / Triggers / **Human Interface**
- **7 universal rules（衛生規則）** — `docs/universal-care-rules.md`
- **設計圖格式** — `docs/prescription-template.md`

## Repo 結構

```
.claude/                顧問 wiring（hook + skill）
docs/
  axes.md            12 設計軸索引
  axes/              每設計軸深度
  universal-care-rules.md   R-1~R-7
  prescription-template.md  設計圖格式
cases/                  案例庫（gitignored — 各 fork 自家任務不交叉）
prescriptions/          施工前留痕（gitignored）
sessions/               對話歷史（gitignored）
BACKLOG.md              未消化失敗（gitignored — 各 fork 自家失敗）
```

## Status

**v0.4 — Human Interface 設計軸 + 多軸 memory + 飛輪 retrospective**

- ✅ **12 設計軸完整**（v0.4 新增 Human Interface — human-facing IO 邊界，對稱設計軸 9 system-facing）
- ✅ 7 universal rules（R-6 擴範圍含 target runtime 輸出）
- ✅ Consultant skill 鎖建築師身分 + **6 步流程**（v0.4 新增 Step 6 飛輪 retrospective）
- ✅ Cwd-guard hook + R-1/R-3/R-5/R-6 enforce hook
- ✅ **Memory 多軸分類**（v0.4：content type / scope / storage form / access pattern，業界 CoALA 共識）
- ✅ **Plan-as-memory + Outcome-as-skill 雙向飛輪**（v0.4）
- 🔄 跨 target 驗證中（ai-infra-management v1 已實彈 + 多輪迭代回饋）

## License

MIT
