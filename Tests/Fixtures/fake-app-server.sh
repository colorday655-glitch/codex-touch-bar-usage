#!/bin/bash
set -euo pipefail

IFS= read -r initialize_request
if IFS= read -r -t 1 early_request; then
  # Real app-server drops requests queued before initialize has completed.
  printf '%s\n' '{"jsonrpc":"2.0","id":1,"result":{}}'
  exit 0
fi
printf '%s\n' '{"jsonrpc":"2.0","id":1,"result":{}}'
IFS= read -r rate_limit_request

case "${FAKE_MODE:-multi}" in
  timeout)
    sleep 2
    ;;
  unauthenticated)
    printf '%s\n' '{"jsonrpc":"2.0","id":2,"error":{"code":-32001,"message":"Not signed in"}}'
    ;;
  fallback)
    printf '%s\n' '{"jsonrpc":"2.0","id":2,"result":{"rateLimits":{"primary":{"usedPercent":31,"windowDurationMins":300,"resetsAt":1750000000},"secondary":{"usedPercent":57,"windowDurationMins":10080,"resetsAt":1750500000}},"rateLimitsByLimitId":null,"rateLimitResetCredits":{"availableCount":2,"credits":null}}}'
    ;;
  *)
    printf '%s\n' '{"jsonrpc":"2.0","id":2,"result":{"rateLimits":{"primary":{"usedPercent":99,"windowDurationMins":300,"resetsAt":1750000000},"secondary":{"usedPercent":99,"windowDurationMins":10080,"resetsAt":1750500000}},"rateLimitsByLimitId":{"codex":{"primary":{"usedPercent":28,"windowDurationMins":300,"resetsAt":1750000000},"secondary":{"usedPercent":56,"windowDurationMins":10080,"resetsAt":1750500000}}},"rateLimitResetCredits":{"availableCount":2,"credits":[{"id":"RateLimitResetCredit_1","resetType":"codexRateLimits","status":"available","grantedAt":1781654400,"expiresAt":1784246400,"title":"Full reset (Weekly + 5 hr)","description":"Ready to redeem"}]}}}'
    ;;
esac
