#!/usr/bin/env bash
set -Eeuo pipefail

PUBLIC_DOMAIN="${PUBLIC_DOMAIN:-api.yukingai.cn}"
BASE_URL="${BASE_URL:-http://127.0.0.1}"
RESULT_DIR="$(mktemp -d /tmp/restaurant-gateway-qa.XXXXXX)"

cleanup() {
  rm -rf -- "${RESULT_DIR}"
}
trap cleanup EXIT

run_parallel() {
  local label="$1"
  local count="$2"
  local concurrency="$3"
  local request_kind="$4"
  local output="${RESULT_DIR}/${label}.status"
  : > "${output}"

  for i in $(seq 1 "${count}"); do
    case "${request_kind}" in
      login_spoofed_xff)
        curl -sS -o /dev/null -w '%{http_code} %{time_total}\n' --max-time 10 \
          -H "Host: ${PUBLIC_DOMAIN}" -H 'Content-Type: application/json' \
          -H "X-Forwarded-For: 198.51.100.${i}" \
          -d '{}' "${BASE_URL}/rest/member/login" >> "${output}" &
        ;;
      public_scan)
        curl -sS -o /dev/null -w '%{http_code} %{time_total}\n' --max-time 10 \
          -H "Host: ${PUBLIC_DOMAIN}" -H 'Content-Type: application/json' \
          -d '{"sceneToken":"phase643-invalid"}' \
          "${BASE_URL}/rest/scan/resolve" >> "${output}" &
        ;;
      same_member_token)
        curl -sS -o /dev/null -w '%{http_code} %{time_total}\n' --max-time 10 \
          -H "Host: ${PUBLIC_DOMAIN}" -H 'Content-Type: application/json' \
          -H 'token: phase643-same-member-token' -d '{}' \
          "${BASE_URL}/rest/member/order/insert" >> "${output}" &
        ;;
      distinct_member_token)
        curl -sS -o /dev/null -w '%{http_code} %{time_total}\n' --max-time 10 \
          -H "Host: ${PUBLIC_DOMAIN}" -H 'Content-Type: application/json' \
          -H "token: phase643-member-token-${i}" -d '{}' \
          "${BASE_URL}/rest/member/order/insert" >> "${output}" &
        ;;
      websocket)
        curl -sS -o /dev/null -w '%{http_code} %{time_total}\n' --max-time 10 \
          -H "Host: ${PUBLIC_DOMAIN}" -H 'Connection: Upgrade' \
          -H 'Upgrade: websocket' -H 'Sec-WebSocket-Version: 13' \
          -H 'Sec-WebSocket-Key: cGhhc2U2NDMtdGVzdA==' \
          "${BASE_URL}/rest/merchant/order/realtime?token=invalid-${i}" >> "${output}" &
        ;;
      *)
        echo "Unknown request kind: ${request_kind}" >&2
        return 2
        ;;
    esac
    if (( i % concurrency == 0 )); then
      wait
    fi
  done
  wait
  echo "${label}_status_counts=$(awk '{print $1}' "${output}" | sort | uniq -c | awk '{printf "%s:%s,", $2, $1}' | sed 's/,$//')"
  local p95_index=$(( (count * 95 + 99) / 100 ))
  local p99_index=$(( (count * 99 + 99) / 100 ))
  local p95_seconds p99_seconds
  p95_seconds="$(awk '{print $2}' "${output}" | sort -n | sed -n "${p95_index}p")"
  p99_seconds="$(awk '{print $2}' "${output}" | sort -n | sed -n "${p99_index}p")"
  awk -v label="${label}" -v p95="${p95_seconds}" -v p99="${p99_seconds}" \
    'BEGIN {printf "%s_latency_ms=p95:%.1f,p99:%.1f\n", label, p95*1000, p99*1000}'
}

status_count() {
  local label="$1"
  local status="$2"
  awk -v expected="${status}" '$1 == expected {count++} END {print count+0}' "${RESULT_DIR}/${label}.status"
}

run_parallel login 12 12 login_spoofed_xff
run_parallel public_scan 200 50 public_scan
run_parallel same_token_order 12 12 same_member_token
run_parallel distinct_token_order 12 12 distinct_member_token
run_parallel websocket 40 20 websocket

(( $(status_count login 429) > 0 ))
(( $(status_count public_scan 429) == 0 ))
(( $(status_count same_token_order 429) > 0 ))
(( $(status_count distinct_token_order 429) == 0 ))
(( $(status_count websocket 429) == 0 ))

echo "gateway_rate_limit_acceptance=OK"
