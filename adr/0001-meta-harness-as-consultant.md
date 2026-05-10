# ADR 0001：meta-harness 採顧問框架，不是腳手架工廠

Date: 2026-05-02
Status: Accepted（核心決定仍有效，但 v0.3 起顧問身分鎖在 `.claude/skills/consultant/SKILL.md`，不再是純對話流程文件）

## Context

最初直覺是把 meta-harness 做成「`meta-harness new <domain>` 產出標準目錄結構」的腳手架工具。深思後發現：9 支柱每條都是設計參數而非開關，且彼此耦合，沒有單一最佳搭配。

## Decision

採顧問框架：對話 + 決策紀錄 + 案例庫為主體，腳手架降級為顧問結論的編譯產物。

## Consequences

- 主體是知識與對話流程，不是 CLI 子命令
- 每次使用會產出 ADR（domain harness 的第一批 memory）
- 工具自己也是 harness（meta = 同層自舉，非高一層）
- 路徑：先把現有 3 repo 寫成案例 → 第 4 個 domain 刻意走顧問流程 → 蒸餾決策樹 → 才包裝工具

## Rejected

- 純腳手架：凍結一組搭配，對誰都不剛好
- 純顧問無載體：建議三天內忘光
