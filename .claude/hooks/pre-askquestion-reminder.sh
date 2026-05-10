#!/usr/bin/env bash
# PreToolUse on AskUserQuestion — R-5 / R-6 自查提醒（不擋）
jq -n '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "allow",
    additionalContext: "⚠️ 自查 R-5（提問必錨具體 artifact）+ R-6（不用未解釋專有名詞 / 縮寫）：題目 / 選項中是否有業主沒看過的 Part X / G-N / R-N 編號未展開？英文動名詞 / 縮寫未解釋？若有 → 取消送出、用中文功能名 / 業主講過的詞重寫。"
  }
}'
