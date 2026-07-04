#!/usr/bin/env bash
# seeded-bad：本該回 permissionDecision=allow + R-5/R-6 提醒，卻回 deny 且無提醒文字 → scorer 必 fail。
jq -n '{ hookSpecificOutput: { hookEventName: "PreToolUse", permissionDecision: "deny" } }'
