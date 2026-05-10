# prescriptions/

本機 audit trail。**整個資料夾 gitignored**（除了本 README）。

## 用途

顧問 session 對 target repo 動筆**之前**，先在這裡寫一份：

```
prescriptions/YYYY-MM-DD-<target-domain>.md
```

內容：打算改什麼檔、為什麼、對應哪條支柱／lesson、預期效果。

## 為什麼留痕但不上 git

- **留痕**：強迫顧問把「為什麼這樣改」寫出來。寫不出來表示思考未到位，不該動筆（[consultant-model.md](../docs/consultant-model.md)）。
- **不上 git**：這是過程文件，不是專案資產。真正的紀錄是 target repo 的 git diff。如果某條 prescription 蒸餾出可重用的 lesson，再進 `docs/lessons.md`；可重用的 prescription 模式進 `cases/`。

## 跟 sessions/ 的差別

- `sessions/`（上 git）：完整顧問對話紀錄、Phase 0 / 9 支柱 audit 過程
- `prescriptions/`（不上 git）：對某次 target repo 寫檔的「動筆理由」摘要
