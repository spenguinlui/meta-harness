# consolidation-loop

**R-10 / Step 4.5 自驗 loop 的 reference 實作**（universal-care-rules.md R-10、consultant SKILL.md Step 4.5）。

原始命題：測試 ai-infra-management 的 `/advise all ec2` 能否在「給優化建議」任務上自我迭代、收斂到「合併專案到單機 + Docker」這個結論。實際跑下來變成 meta-harness 自身「設計>測試>經驗>優化」 loop 的 dogfood。

## 結構（新 target 仿這份）

```
experiments/<target>-<topic>/
├── README.md          實驗目的、迭代紀錄、known limitations
├── gold.md            期待輸出的關鍵特徵（關鍵字 / 結構 / 通過門檻）
├── prompts/v*.md      prompt 版本演進，每次失敗才 bump
├── run.sh             cd <target> && claude -p < prompt > runs/NNN.json
├── eval.sh            機器評分 → runs/NNN.eval.json
└── runs/              raw output + meta + eval（每輪一組）
```

## run.sh 要點

- `--permission-mode bypassPermissions` 才能讓 Skill / slash command 在 headless 跑得動
- 用絕對路徑 prompt file（cwd 進 target 後相對路徑會失效）
- `set -euo pipefail` 但 `ls` glob 空目錄會炸，用 `|| true`

## eval.sh 設計重點（這 session 學到的）

1. **共現判定**：單關鍵字命中容易誤判（「合併節點」≠「合併專案」）。同段落內必須關鍵動詞 + 關鍵名詞共現才算。
2. **短回應檢測**：當 output 是「請業主選 X」這類短回應時，含再多關鍵字也不算「真分析」。檢字數 + intent prompt 特徵詞短路 fail。
3. **多層**：關鍵字覆蓋 → structural check（`jq`）→ LLM-judge（暫未蓋）。R-10 step 4.5 要求三層至少兩層。

## 本實驗的 11 輪紀錄（meta findings）

| Run | Prompt | 結果 | 學到什麼 |
|-----|--------|------|---------|
| 001-003 | v1（top 3 建議） | 0/3 pass | Claude 預設「金額排序」走 SageMaker / EBS / ElastiCache，沒去看 utilization → 收斂到「錯」的答案 |
| 002 | — | **false positive pass** | 「合併 ElastiCache 節點」被誤判 → eval 加共現判定 |
| 004-006 | v2（禁 RI、目標倒推） | 1/3 pass | 004 完美命中合併方案，005/006 紀律衝突拒答 → target 的 CLAUDE.md 紀律比外部 prompt 強 |
| 007 | v3（/advise pipeline） | 1.0 pass | 9.5min/$3，4 架構師辯論把「合併」降到 P3，**和 v2 raw mode 結論相反** → 多視角辯論能抵消單視角短視 |
| 008 | v3 | fabrication 自爆 | 看到一個 missing file 就放棄、誤報所有 state 都壞 → 多 persona 沒比單 persona 更 robust |
| 009 | v3 (post-Stage0 fix) | usage limit | R-10 寫進「不能驗時怎麼降級」 |
| 010 | v3 (post-Stage0 fix) | Stage 0 fired 但中止 | headless 降級 (d) 沒觸發 → 強化規則 |
| 011 | v3 (after rule 強化) | tracking replay | /advise 看到 24hr 內紀錄就 replay 舊結論 → ai-infra-management 自己的 bug（不在此 session 修） |

## 留給下次顧問的 known limitations

- **eval 沒蓋 LLM-judge 層**：目前只有關鍵字 + 短回應 check。複雜語意（如「真的有引用真實 utilization 數據」vs「只引用 cost-summary 彙總」）抓不到。
- **每輪自驗 ~10min / $3**：對 /advise 這種重 pipeline 不便宜，迭代速度受限。
- **/advise tracking replay 反模式未修**（屬 ai-infra-management 任務內容、不是 meta-harness framework）。
