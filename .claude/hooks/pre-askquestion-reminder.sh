#!/usr/bin/env bash
# PreToolUse on AskUserQuestion — R-5 / R-6 自查提醒（不擋）
jq -n '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "allow",
    additionalContext: "⚠️ 自查 R-5（提問要錨到具體的檔案或東西）+ R-6（不用沒解釋過的術語和縮寫）：題目和選項裡，有沒有對方沒看過的 Part X / G-N / R-N 編號沒展開？有沒有英文動名詞或縮寫沒解釋？有的話取消送出，改用中文功能名、或對方講過的詞重寫。"
  }
}'
