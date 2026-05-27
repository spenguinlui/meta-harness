# 設計軸 13：Self-Verify Coverage（自驗覆蓋率）

target repo 的可機驗 wiring 是否都有對應自驗腳本＋持續被跑。從**事件性的 R-10 紀律**升級成**可量化的飛輪 KPI**。

## 為什麼獨立成設計軸（vs R-10）

| | R-10 | 設計軸 13 |
|---|---|---|
| 顆粒 | 行為紀律（小） | 機制設計（大）|
| 問題 | 「該不該自驗」 | 「自驗系統怎麼蓋、覆蓋率怎麼量、誰拉曲線」|
| 形態 | floor（最低標準）| dashboard + accountability |
| 落地 | prescription 條文 | 基建 + 數據 + 看板 |

R-10 講「禁止把可機驗 outcome 丟過牆給業主」；軸 13 講「**把這條紀律物理化、量化、可比較**」。

## 設計決策

### 1. 自驗基建（必裝三件）

每個 target repo 必有：

```
experiments/<target>-eval/
  ├── run-self-verify.sh       # runner：單一 entry point，跑所有 test-*.sh
  ├── test-*.sh                # scorers：每支對應一個 wiring / mechanism
  └── coverage.json            # 數據面板（schema 見 §3）

.claude/hooks/self-verify-on-stop.sh   # Stop hook：drift → exit 2 擋 session 結束
.claude/settings.json                  # 註冊 Stop hook
```

參考實作：`atdd-task`、`meta-harness` 自身。

### 2. 四 Pattern 分類（每支 test-*.sh 必歸屬其一）

| Pattern | 適用 | 招式 |
|---|---|---|
| **A. 單一真實來源 + drift 偵測** | 配置 / wiring 跨檔一致性 | hardcode 推薦表，parse N 個檔比對 |
| **B. 觸發 + 斷言** | hook / 中介機制是否被吃到 | 構造 stdin / env，呼叫 hook，斷 stdout/exit |
| **C. Scorer + METRICS 行** | 行為品質（agent 輸出）| 受控實例 + ground truth + 量化 |
| **D. 快照 + Diff** | 副作用是否正確 | 跑前 snapshot、跑後比 |

寫新 test 前先選 Pattern；不要硬發明新招式。新 Pattern 若真有需要，回寫本軸文件擴充。

### 3. coverage.json schema

每個 target 在 `experiments/<target>-eval/coverage.json` 維護：

```json
{
  "target": "<name>",
  "generated_at": "<ISO8601>",
  "runner": "experiments/<target>-eval/run-self-verify.sh",
  "scorers": [
    {
      "name": "test-XX.sh",
      "pattern": "A|B|C|D",
      "checks": 27,
      "last_pass": true,
      "covers": ["mechanism-1", "mechanism-2"]
    }
  ],
  "totals": {
    "scorers": 7,
    "checks_total": 58,
    "checks_passed": 58
  },
  "mechanisms_inventory": {
    "total": 20,
    "covered": 7,
    "coverage_pct": 35,
    "uncovered": ["mechanism-name-1", "mechanism-name-2"]
  },
  "last_run": {
    "timestamp": "<ISO8601>",
    "rc": 0
  }
}
```

**`coverage_pct = (covered / total) * 100`**——不到 100% 不是錯，但**飛輪上不能停**。

### 4. 自動 vs 手動

| 欄位 | 誰維護 |
|---|---|
| `scorers[*]`、`totals.*`、`last_run.*` | runner 跑完自動 patch |
| `scorers[*].covers`、`mechanisms_inventory.total / uncovered` | **target builder 手動維護**——誰知道 target 全部 wiring |
| `mechanisms_inventory.covered` | union(scorers[*].covers) 自動算 |
| `coverage_pct` | 自動算 |

Builder 維護 `mechanisms_inventory.total` 是要付出的紀律，**換得的是「覆蓋率不會作弊」的可信度**——若 builder 設 total=1、covered=1，誰都看得出來在唬人。

### 5. /healthcheck 整合

`/healthcheck <target>` 跑時讀 target 的 `coverage.json` → 印「軸 13：自驗覆蓋 X%、N 支 scorer、未覆蓋 [...]」。沒檔 → 警示「軸 13 未落地」。詳見 `.claude/commands/healthcheck.md` Step 3.5。

## Mechanism

- **Write triggers**：每次 `run-self-verify.sh` 跑完自動 patch；builder 加新 test-*.sh 或更新 mechanism 清單時手動編輯
- **Read mechanism**：`/healthcheck` 在逐軸盤點時讀 target coverage.json；可選擇 session-start auto-load 摘要
- **Lifecycle**：runner 跑寫 → /healthcheck 讀 → `last_run.timestamp` 超過 30 天標 stale 提示重跑
- **Validation**：對應 Part E 的 V<n>（target 端的 `test-self-verify-coverage.sh`）驗 coverage.json schema 合法 + `mechanisms_inventory` 內部一致

## Anti-patterns

1. **「文件講了沒落地」**：prescription 寫 V<n>=script 但 target 沒對應 `test-*.sh` → R-10 違反、軸 13 暴露
2. **「自驗工具放著沒人跑」**：test-*.sh 存在但 `last_run.timestamp` 超過 30 天 → 自驗變蚊子館
3. **「覆蓋率永遠 0%」**：`mechanisms_inventory.total>0` 但 `covered=0` → 跟「沒裝自驗」沒差
4. **「靠 builder 自覺」**：沒 Stop hook 擋住 → 回到事件性紀律，R-10 軟規則化
5. **「100% 但 total=1」**：覆蓋率作弊；total 要老實列出 target 的全部 wiring 數
6. **「scorer 寫好但沒進 runner」**：test-*.sh 在 disk 但 `run-self-verify.sh` 沒撿到（命名不對 / 沒 +x）→ 覆蓋率假象

## 與其他軸的耦合

- **軸 7 Hooks**：Stop hook 是軸 13 的物理執行層
- **軸 8 Evaluation**：軸 13 是 outer eval 的元覆蓋指標（「eval 自己有沒有覆蓋到」）
- **軸 9 觀測**：coverage.json 是觀測介面之一
- **R-10**：軸 13 把 R-10 從紀律升級成 KPI

## 落地參考（依時間順序）

- **meta-harness 自身**（2026-05-27）：3 scorer / Pattern A / 14 checks ──「鞋匠的孩子有鞋穿」首落地
- **atdd-task**（2026-05-26）：7 scorer / Pattern A + B + C / 58 checks ──首個 target 完整落地

跨 target 比對由 `/healthcheck` 或未來的 `/coverage` 統計命令處理。
