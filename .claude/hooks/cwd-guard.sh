#!/usr/bin/env bash
# SessionStart — meta-harness 顧問 cwd guard
expected="meta-harness"
actual="$(basename "$PWD")"
if [[ "$actual" != "$expected" ]]; then
  echo "WARNING: cwd basename = '$actual', expected '$expected'." >&2
  echo "If meta-harness consultant work: abort, re-open session in ~/meta-harness." >&2
  echo "If target repo work: ignore." >&2
fi
