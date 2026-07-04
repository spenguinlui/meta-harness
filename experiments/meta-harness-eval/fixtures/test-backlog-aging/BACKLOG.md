# Backlog（seeded-bad fixture — 軸 3 / --negative）

只放一條**缺入庫日期**的待消化條目，斷言 test-backlog-aging.sh 必須 fail
（機器算不了齡 → 登記簿無法維生）。

---

## 待消化

### 這條故意沒有入庫日期，機器算不了齡（seeded-bad）
失敗：條目標題不含「（YYYY-MM-DD 入庫」或「≤YYYY-MM-DD 入庫」，test-backlog-aging.sh 必須抓到並 exit 1。
