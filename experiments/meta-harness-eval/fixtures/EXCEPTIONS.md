# 陰性樣本例外清單（fixtures/EXCEPTIONS.md）

`run-self-verify.sh --negative` 對每支 scorer 以 `fixtures/<scorer名>/` 為 `CLAUDE_PROJECT_DIR`
餵一個 seeded-bad 樣本，斷言 scorer **必須 fail**（mutation testing 精神：scorer 從沒被測過
「該 fail 時會不會 fail」）。沒有 fixture 的 scorer 一律要在本檔具名列出理由，否則 runner 視為
「沉默跳過」而 fail。上限 3 支。

目前例外：**1 支**（上限 3）。

## test-coverage-derivation.sh

**理由**：本 scorer 是 `generate-coverage.sh --check` 的薄包裝，語義依賴「掃整個 repo 拓撲
（settings.json hooks × commands × skills × bin × docs 模板 × eval 基建）重新推導分母、與檔內
coverage.json 比對」。要在最小 fixture 樹下讓它 fail，得複製整份 `.claude/` + `docs/` + `bin/` +
eval 基建**外加**一份刻意 drift 的 coverage.json，且 `generate-coverage.sh` 用 `SCRIPT_DIR`
相對 `HUB` 推 `EVAL_DIR`，fixture 下路徑推導會失真——最小 fixture 反而不可靠。

**它的陰性行為改由驗收條件直接證明**（比 fixture 更強）：手動把 `coverage.json` 的 `total`
分母 +1 → `generate-coverage.sh --check` 立即 exit 1、本 scorer 亦 exit 1（見 Stage 2 交付證據
`--check` 前後對照）。也就是這支的「該 fail 會 fail」有實跑證據，只是不走 fixture 管道。
