# Gold reference

理想的優化建議應該包含以下要素。eval.sh 用關鍵字 / 片語比對覆蓋率。

## 必要關鍵字（每命中一個 +1，總分 / count）

- 合併 / consolidat / merge / bin-pack
- docker / container / 容器
- 利用率 / utilization / CPU
- 省 / saving / cost / 成本
- t3.medium 或 t2.micro 或 EC2 實例型號（證明有看真實數據）

## 加分項（有提到代表分析較深）

- 具體點名專案 ID（api-server / core-web / ai-task / e-trading...）
- 引用具體數字（$697 / 14 台 / 2.88% / 利用率百分比）
- 提到 ECS / docker-compose / Kubernetes 任一具體實作方式
- 提到風險（隔離性 / 故障域 / noisy neighbor）

## 反例（應該扣分或標記）

- 只講「升級 RDS」「刪 ALB」等已經做過的優化（cost-summary.json 已記錄）
- 只講「用 Reserved Instance」這種非合併方案
- 講 docker 但用在無關情境（例：建議用 docker 做 CI/CD，不是合併）

## 通過門檻

- 必要關鍵字覆蓋率 ≥ 0.6（5 個中至少 3 個）
- 至少 1 個加分項
- 沒有觸發反例
