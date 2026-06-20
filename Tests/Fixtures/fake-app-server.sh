#!/bin/bash
set -euo pipefail

cat >/dev/null

case "${FAKE_MODE:-multi}" in
  timeout)
    sleep 2
    ;;
  unauthenticated)
    printf '%s\n' '{"jsonrpc":"2.0","id":1,"result":{}}'
    printf '%s\n' '{"jsonrpc":"2.0","id":2,"error":{"code":-32001,"message":"Not signed in"}}'
    ;;
  fallback)
    printf '%s\n' '{"jsonrpc":"2.0","id":1,"result":{}}'
    printf '%s\n' '{"jsonrpc":"2.0","id":2,"result":{"rateLimits":{"primary":{"usedPercent":31,"windowDurationMins":300,"resetsAt":1750000000},"secondary":{"usedPercent":57,"windowDurationMins":10080,"resetsAt":1750500000}},"rateLimitsByLimitId":null,"rateLimitResetCredits":null}}'
    ;;
  *)
    printf '%s\n' '{"jsonrpc":"2.0","id":1,"result":{}}'
    printf '%s\n' '{"jsonrpc":"2.0","id":2,"result":{"rateLimits":{"primary":{"usedPercent":99,"windowDurationMins":300,"resetsAt":1750000000},"secondary":{"usedPercent":99,"windowDurationMins":10080,"resetsAt":1750500000}},"rateLimitsByLimitId":{"codex":{"primary":{"usedPercent":28,"windowDurationMins":300,"resetsAt":1750000000},"secondary":{"usedPercent":56,"windowDurationMins":10080,"resetsAt":1750500000}}},"rateLimitResetCredits":null}}'
    ;;
esac

