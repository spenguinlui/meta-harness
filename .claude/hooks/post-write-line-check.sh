#!/usr/bin/env bash
# PostToolUse on Write/Edit — R-1 / R-3 行數檢查（不擋、給模型 feedback）
# R-1: CLAUDE.md ≤ 50 行（不含 fenced code block）
# R-3: .claude/hooks/*.sh ≤ 100 行

input=$(cat)
filepath=$(jq -r '.tool_input.file_path // .tool_input.path // ""' <<< "$input")

[[ -z "$filepath" || ! -f "$filepath" ]] && exit 0

basename=$(basename "$filepath")
threshold=0; rule=""; lines=0

if [[ "$basename" == "CLAUDE.md" ]]; then
  lines=$(grep -v '^```' "$filepath" | wc -l | tr -d ' ')
  threshold=50
  rule="R-1（CLAUDE.md ≤ 50 行不含 fenced code block）"
elif [[ "$filepath" == *".claude/hooks/"*".sh" ]]; then
  lines=$(wc -l < "$filepath" | tr -d ' ')
  threshold=100
  rule="R-3（每個 hook ≤ 100 行）"
else
  exit 0
fi

if (( lines > threshold )); then
  jq -n --arg p "$filepath" --arg l "$lines" --arg t "$threshold" --arg r "$rule" '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: ("⚠️ " + $r + " 違規：" + $p + " = " + $l + " 行 > " + $t + " 門檻。請拆分。")
    }
  }'
fi

exit 0
