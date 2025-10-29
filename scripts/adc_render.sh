#!/usr/bin/env bash
set -euo pipefail

# Render APISIX config from OpenAPI using ADC CLI (v0.21.2).

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INPUT_OPENAPI="${1:-${ROOT_DIR}/openapi/httpbin.yaml}"
OUT_DIR="${ROOT_DIR}/dist"
OUT_FILE="${OUT_DIR}/apisix.yaml"

mkdir -p "${OUT_DIR}"

if ! command -v adc >/dev/null 2>&1; then
  echo "[ERROR] 'adc' not found in PATH. Install ADC CLI first." 1>&2
  echo "        See: https://github.com/api7/adc" 1>&2
  exit 127
fi

echo "Using ADC: $(adc --version 2>/dev/null || echo unknown)"
echo "Input OpenAPI: ${INPUT_OPENAPI}"
echo "Output: ${OUT_FILE}"

echo "Running: adc convert openapi -f ${INPUT_OPENAPI} -o ${OUT_FILE}"
adc convert openapi -f "${INPUT_OPENAPI}" -o "${OUT_FILE}"

echo "Render OK -> ${OUT_FILE}"
