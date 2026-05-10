# sessions/

顧問跟業主的對話歷史。**整個資料夾 gitignored**（除本 README）。

## 為什麼不上 git

含真實 PII（AWS account ID / 員工名 / instance ID）、業主 infra 細節、私密對話。他人 fork 本 repo 不該看到別人的 session。

## 命名

```
sessions/YYYY-MM-DD-<target>-<topic>.md
```

## 顧問不主動 Read

按 `.claude/skills/consultant/SKILL.md` 紀律，新 session 顧問**不**讀 sessions/（除非業主明確指定某份接續）。對話歷史是業主視角紀錄、不是當前 task 上下文。
