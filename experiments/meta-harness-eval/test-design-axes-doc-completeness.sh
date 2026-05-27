#!/bin/bash
# pattern: A
# 驗 docs/design-axes/*.md 都有最小結構（H1 + 至少 1 個 ## section）
set -u
HUB="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$HUB" || exit 1

CHECKS=0; FAILS=0
pass(){ CHECKS=$((CHECKS+1)); echo "  ✓ $1"; }
fail(){ CHECKS=$((CHECKS+1)); FAILS=$((FAILS+1)); echo "  ✗ $1"; }

echo "▶ design-axes/*.md 結構完整性"
for f in docs/design-axes/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  H1=$(grep -c "^# " "$f")
  H2=$(grep -c "^## " "$f")
  if [ "${H1}" -ge 1 ] && [ "${H2}" -ge 1 ]; then
    pass "${name} → H1=${H1} H2=${H2}"
  else
    fail "${name} → 缺結構（H1=${H1}, H2=${H2}；需各 ≥1）"
  fi
done

echo
[ "${FAILS}" -eq 0 ] && { echo "✅ design-axes 結構齊 ${CHECKS}/${CHECKS}"; exit 0; } || { echo "❌ ${FAILS}/${CHECKS} 失敗"; exit 1; }
