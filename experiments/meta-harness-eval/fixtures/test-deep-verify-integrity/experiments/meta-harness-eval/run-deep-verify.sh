#!/bin/bash
# seeded-bad runner：違反合約——未知參數不擋（應 exit 2）、CLI 缺席不誠實（應 exit 2 + ⚠️）、
# 永遠 exit 0。用來證明 test-deep-verify-integrity.sh 驗的是行為不是檔案存在。
exit 0
