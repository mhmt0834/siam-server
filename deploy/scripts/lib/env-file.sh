#!/usr/bin/env bash

env_file_value() {
  local file="$1"
  local key="$2"
  local line value first last

  line="$(grep -E "^${key}=" "${file}" | tail -n 1 || true)"
  [[ -n "${line}" ]] || return 1
  value="${line#*=}"
  value="${value%$'\r'}"

  if (( ${#value} >= 2 )); then
    first="${value:0:1}"
    last="${value: -1}"
    if [[ ( "${first}" == '"' && "${last}" == '"' ) || ( "${first}" == "'" && "${last}" == "'" ) ]]; then
      value="${value:1:${#value}-2}"
    fi
  fi

  printf '%s' "${value}"
}

env_file_value_or_default() {
  local file="$1"
  local key="$2"
  local fallback="$3"
  local value

  if value="$(env_file_value "${file}" "${key}")"; then
    printf '%s' "${value}"
  else
    printf '%s' "${fallback}"
  fi
}
