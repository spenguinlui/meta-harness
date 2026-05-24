> 🌐 **繁體中文** | [English](CONTRIBUTING.en.md)

# 擴充 meta-harness 方法學

給**擴充這套顧問方法學本身**的人（加設計軸、加規則、沉澱教訓）。
想「用」這套流程設計你的 harness 看 [`README.md`](./README.md)；這裡講**方法學的架構與怎麼動它**。

> 兩種讀者分流（meta-harness 自己就吃這套）：README = 使用顧問流程的人（Viewer）；本檔 = 改顧問框架的人（Maintainer）。

## 架構概覽

meta-harness 不是 framework，是「**顧問身分 + pattern library + 對話流程**」。三層構成：

```
身分層    .claude/skills/consultant/SKILL.md   建築師人格 + 6 步流程（不可漂移）
知識層    docs/design-axes/ (12 軸) + docs/universal-care-rules.md (R-1~R-11)
前門層    .claude/commands/ + 各模式 skill（design / healthcheck / retro / document）
```

- 12 設計軸 = 設計**參數空間**（不是 checklist），彼此耦合。
- R-1~R-11 = 跨 target 的衛生 floor（已落地為 enforcement 的規則）。
- `docs/lessons.md` = 洞察（為什麼這樣設計），和 rules 區別：rules 是強制、lessons 是經驗。

## wiring 怎麼運作

| 元件 | 做什麼 |
|---|---|
| `.claude/skills/consultant/` | 顧問身分 + 完整 6 步流程（核心，所有模式共用） |
| `.claude/skills/{design,healthcheck,retro,document}/` | 四個模式前門，進去走顧問對話 |
| `.claude/commands/` | slash command 可發現入口 |
| `.claude/hooks/` | cwd 守衛、CLAUDE.md 行數檢查（R-1）、提問自查（R-5/R-6） |
| `docs/*-template.md` | prescription（設計圖）+ manual（說明書）格式 |
| `experiments/<topic>/` | 自驗 loop 的 reference 實作（R-10） |

## 怎麼擴充

- **加設計軸**：建 `docs/design-axes/<n>-<name>.md`（決策選項 + 耦合 + 反模式 + 案例）→ 在 `docs/design-axes.md` 索引加一條。確認它**正交**於既有 12 軸（別跟現有軸重疊；如 7 vs 11、9 vs 12 的邊界）。
- **加 universal rule**：在 `docs/universal-care-rules.md` 加 `R-N`（定義 / 為什麼 / 規則 / 落地）。判準：**離開這個 target / 這個人還成立嗎**？跨 target 才入 universal；target-specific 留 target 自己 doc。commit message 必答「為什麼不能刪源頭」（R-7）。
- **加教訓**：踩到反覆失誤 → `docs/lessons.md`（洞察，非強制規則）。累積驗證夠普世 → 升 R-N。
- **加模式 / skill**：仿 `document` skill——一個 `.claude/skills/<name>/SKILL.md` + 在 consultant 觸發表加一列 + 必要時掛進 6 步流程。

## 設計依據（為什麼這樣）

- **顧問而非腳手架**：12 軸是耦合參數，沒有對誰都剛好的標準模板 → 對話 + pattern library 為主體。
- **規則分層**（避免「一份文件 12 條互不連貫的反模式」）：跨流程通則（R-N）/ 設計流程（consultant-flow）/ 設計圖格式（template）/ 反模式 分開放。
- **治理三條**：R-7（不固化壞流程、fix 先 root cause）、R-8（不跨層越權）、R-9（framework vs 任務內容分流）——改方法學前先讀。

## 怎麼驗證改動

- **dogfood**：任何新能力先拿真實 target 跑一遍（如 `/document` 先寫 figma2code 再寫自己）。不 dogfood 就交付 = 未驗成品（R-10）。
- **自驗可機驗的**：新 skill / hook 行為 → headless 跑 + 機器評分 ≥ 3 次（`experiments/<topic>/`）。
- **改規則**：grep root cause、確認不是疊蓋症狀（R-7）；確認沒替別層表態（R-8）。
