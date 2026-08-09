#!/usr/bin/env bash
set -Eeuo pipefail

BACKEND_CONTAINER="${BACKEND_CONTAINER:-yuking-restaurant-saas-backend-1}"
RESULT_DIR="$(mktemp -d /tmp/restaurant-api-load.XXXXXX)"

cleanup() {
  rm -rf -- "${RESULT_DIR}"
}
trap cleanup EXIT

BACKEND_IP="$(docker inspect "${BACKEND_CONTAINER}" --format '{{range .NetworkSettings.Networks}}{{if eq .NetworkID ""}}{{else}}{{.IPAddress}} {{end}}{{end}}' | awk '{print $1}')"
if [[ -z "${BACKEND_IP}" ]]; then
  echo "Unable to resolve backend container IP." >&2
  exit 1
fi
BASE_URL="http://${BACKEND_IP}:9200/siam-server"

run_load() {
  local label="$1"
  local count="$2"
  local concurrency="$3"
  local path="$4"
  local method="$5"
  local output="${RESULT_DIR}/${label}.result"
  : > "${output}"
  local started ended elapsed rps
  started="$(date +%s%N)"
  for i in $(seq 1 "${count}"); do
    if [[ "${method}" == "POST" ]]; then
      curl -sS -o /dev/null -w '%{http_code} %{time_total}\n' --max-time 15 \
        -H 'Content-Type: application/json' -d '{"sceneToken":"phase643-invalid"}' \
        "${BASE_URL}${path}" >> "${output}" &
    else
      curl -sS -o /dev/null -w '%{http_code} %{time_total}\n' --max-time 15 \
        "${BASE_URL}${path}" >> "${output}" &
    fi
    if (( i % concurrency == 0 )); then
      wait
    fi
  done
  wait
  ended="$(date +%s%N)"
  elapsed="$(awk -v start="${started}" -v end="${ended}" 'BEGIN {print (end-start)/1000000000}')"
  rps="$(awk -v count="${count}" -v elapsed="${elapsed}" 'BEGIN {printf "%.1f", count/elapsed}')"
  local success errors p95_index p99_index p95 p99
  success="$(awk '$1 == 200 {count++} END {print count+0}' "${output}")"
  errors=$((count - success))
  p95_index=$(( (count * 95 + 99) / 100 ))
  p99_index=$(( (count * 99 + 99) / 100 ))
  p95="$(awk '{print $2}' "${output}" | sort -n | sed -n "${p95_index}p")"
  p99="$(awk '{print $2}' "${output}" | sort -n | sed -n "${p99_index}p")"
  awk -v label="${label}" -v success="${success}" -v errors="${errors}" \
      -v rps="${rps}" -v p95="${p95}" -v p99="${p99}" \
      'BEGIN {printf "%s=success:%d,errors:%d,rps:%s,p95_ms:%.1f,p99_ms:%.1f\n", label, success, errors, rps, p95*1000, p99*1000}'
  (( errors == 0 ))
}

run_load backend_health 2000 50 /actuator/health GET
run_load invalid_scan 1000 50 /rest/scan/resolve POST
free -m | awk '/^Mem:/ {print "host_memory_available_mb=" $7}'
echo "production_api_load_acceptance=OK"
