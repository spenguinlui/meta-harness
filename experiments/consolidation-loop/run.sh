#!/usr/bin/env bash
# 跑一輪：在 ai-infra-management 內呼叫 claude -p，輸出存到 runs/NNN.json
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TARGET="${TARGET:-$HOME/ai-infra-management}"
PROMPT_FILE="${1:-$HERE/prompts/v1.md}"
# 轉絕對路徑（cd 進 TARGET 後仍可讀）
case "$PROMPT_FILE" in
  /*) ;;
  *) PROMPT_FILE="$(cd "$(dirname "$PROMPT_FILE")" && pwd)/$(basename "$PROMPT_FILE")" ;;
esac

if [[ ! -d "$TARGET" ]]; then
  echo "TARGET not found: $TARGET" >&2
  exit 1
fi
if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "prompt not found: $PROMPT_FILE" >&2
  exit 1
fi

# 下一個流水號
next=$(ls "$HERE/runs"/*.json 2>/dev/null | sed -E 's/.*\/0*([0-9]+)\.json/\1/' | sort -n | tail -1 || true)
next=$((${next:-0} + 1))
out=$(printf "%s/runs/%03d.json" "$HERE" "$next")
meta=$(printf "%s/runs/%03d.meta.json" "$HERE" "$next")

prompt_version=$(basename "$PROMPT_FILE" .md)
started_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo "→ run #$next  prompt=$prompt_version  target=$TARGET"
echo "→ output: $out"

# 在 TARGET cwd 跑，這樣 claude 預設工作目錄就是 ai-infra-management
( cd "$TARGET" && claude -p "$(cat "$PROMPT_FILE")" --output-format json --permission-mode bypassPermissions ) > "$out"

ended_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
cat > "$meta" <<EOF
{
  "run_id": $next,
  "prompt_version": "$prompt_version",
  "prompt_file": "$PROMPT_FILE",
  "target": "$TARGET",
  "started_at": "$started_at",
  "ended_at": "$ended_at"
}
EOF

echo "✓ done. meta: $meta"
echo "  next: ./eval.sh $out"
