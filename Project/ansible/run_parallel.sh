#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYBOOK="${PLAYBOOK:-site.yml}"
INVENTORY="${INVENTORY:-inventory.ini}"
declare -a EXTRA_ARGS=()
if [ "$#" -gt 0 ]; then
  EXTRA_ARGS=("$@")
fi

run_job() {
  local name="$1"
  shift

  echo "==> ${name}"
  (
    cd "${ROOT_DIR}"
    local cmd=(ansible-playbook -i "${INVENTORY}" "${PLAYBOOK}" "$@")
    if [ "${#EXTRA_ARGS[@]}" -gt 0 ]; then
      cmd+=("${EXTRA_ARGS[@]}")
    fi
    "${cmd[@]}"
  )
}

wait_for_jobs() {
  local failed=0

  for pid in "$@"; do
    if ! wait "${pid}"; then
      failed=1
    fi
  done

  return "${failed}"
}

echo "Phase 1/3: services + postgres-primary"
run_job "services" --limit services &
services_pid=$!
run_job "postgres-primary" --limit postgres_primary &
postgres_primary_pid=$!
wait_for_jobs "${services_pid}" "${postgres_primary_pid}"

echo "Phase 2/3: postgres-replica"
run_job "postgres-replica" --limit postgres_replica

echo "Phase 3/3: nextcloud"
run_job "nextcloud" --limit nextcloud

echo "Parallel deployment finished successfully."
