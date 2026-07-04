#!/usr/bin/env bash
# seeded-bad：超過 100 行的 hook 檔本該出 R-3 違規提示，卻永遠靜默 → scorer 的 R-3 斷言必 fail。
cat >/dev/null
exit 0
