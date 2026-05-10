# cases/

跑過 5 步流程的 target repo 蒸餾物。**整個資料夾 gitignored**（除本 README）。

## 為什麼不上 git

每個 case 是業主自家 target repo 的設計細節 + 內部結構評析（屬「任務」性質）。他人 fork 本 repo 不該看到別人的任務。

## 一個 case 通常含

- `<target>-prescription.md` — 設計圖 snapshot（按 `docs/prescription-template.md` 格式）
- `<target>-pillar-cases.md` — 11 支柱對應評析
- `<target>-domain-rules.md` — 從 universal 砍出的 domain 規則範例

## 顧問不主動 Read

按 `.claude/skills/consultant/SKILL.md` 紀律，新 session 顧問**不**預設讀 cases/（業主明確要參考某份才 Read 那份）。
