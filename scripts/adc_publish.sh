#!/usr/bin/env bash
set -euo pipefail

# Publish APISIX config via ADC (v0.21.2) or fallback seed.

ADMIN_API_URL="${APISIX_ADMIN_API:-http://localhost:9180}"
ADMIN_API_KEY="${APISIX_ADMIN_KEY:-edd1c9f034335f136f87ad84b625c8f1}"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INPUT_FILE="${1:-${ROOT_DIR}/dist/apisix.yaml}"

echo "APISIX Admin: ${ADMIN_API_URL}"
echo "Config file : ${INPUT_FILE}"

if ! command -v adc >/dev/null 2>&1; then
  echo "[WARN] 'adc' not found. Falling back to Admin API seed script (demo path)." 1>&2
  exec bash "${ROOT_DIR}/scripts/bootstrap_routes_via_admin.sh"
fi

if [ ! -f "${INPUT_FILE}" ]; then
  echo "[ERROR] Config file not found: ${INPUT_FILE}. Run scripts/adc_render.sh first." 1>&2
  exit 3
fi

echo "Using ADC: $(adc --version 2>/dev/null || echo unknown)"

echo "Running: adc sync -f ${INPUT_FILE} --server ${ADMIN_API_URL}"
adc sync -f "${INPUT_FILE}" \
  --server "${ADMIN_API_URL}" \
  --token "${ADMIN_API_KEY}"

echo "Publish OK"
