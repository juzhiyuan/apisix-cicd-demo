#!/usr/bin/env bash
set -euo pipefail

ADMIN_API_URL="${APISIX_ADMIN_API:-http://localhost:9180}"
ADMIN_API_KEY="${APISIX_ADMIN_KEY:-edd1c9f034335f136f87ad84b625c8f1}"

echo "Using Admin API: ${ADMIN_API_URL}"

header=( -H "X-API-KEY: ${ADMIN_API_KEY}" -H 'Content-Type: application/json' )

# Create or upsert upstream
echo "Upserting upstream: httpbin_upstream"
curl -fsS -X PUT \
  "${ADMIN_API_URL}/apisix/admin/upstreams/httpbin_upstream" \
  "${header[@]}" \
  -d @apisix/admin_payloads/upstream_httpbin.json

# Create or upsert service
echo "Upserting service: httpbin_service"
curl -fsS -X PUT \
  "${ADMIN_API_URL}/apisix/admin/services/httpbin_service" \
  "${header[@]}" \
  -d @apisix/admin_payloads/service_httpbin.json

# Create/Update routes
for r in httpbin_get httpbin_status httpbin_anything; do
  echo "Upserting route: $r"
  curl -fsS -X PUT \
    "${ADMIN_API_URL}/apisix/admin/routes/${r}" \
    "${header[@]}" \
    -d @apisix/admin_payloads/route_${r}.json
done

echo "Done. Try: curl -i http://localhost:9080/get"
