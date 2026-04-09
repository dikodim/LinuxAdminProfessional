#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

usage() {
  cat <<'EOF'
Usage:
  bash rebuild-node.sh <node> [spare_profile]

Nodes:
  firewall
  nextcloud-1
  nextcloud-2
  postgres-1
  postgres-2
  monitor
  spare

Examples:
  bash rebuild-node.sh postgres-1
  bash rebuild-node.sh postgres-2
  bash rebuild-node.sh nextcloud-1
  bash rebuild-node.sh spare nextcloud
EOF
}

node="${1:-}"
spare_profile="${2:-none}"

if [[ -z "$node" ]]; then
  usage
  exit 1
fi

case "$node" in
  firewall|nextcloud-1|nextcloud-2|postgres-1|postgres-2|monitor|spare)
    ;;
  *)
    echo "Unknown node: $node" >&2
    usage
    exit 1
    ;;
esac

if [[ ! -f ".venv/bin/activate" ]]; then
  echo "Python venv not found: .venv/bin/activate" >&2
  exit 1
fi

echo "Destroying VM: $node"
vagrant destroy -f "$node"

echo "Starting VM without provisioning: $node"
vagrant up "$node" --no-provision

echo "Activating local Python venv"
# shellcheck disable=SC1091
source .venv/bin/activate

if [[ "$node" == "spare" ]]; then
  echo "Applying spare profile: $spare_profile"
  ansible-playbook -i ansible/inventory.ini ansible/spare.yml \
    -e "spare_profile=$spare_profile"
  exit 0
fi

extra_args=()
if [[ "$node" == "postgres-2" ]]; then
  extra_args+=(-e "postgres_force_resync=true")
fi

echo "Applying playbook to: $node"
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml \
  --limit "$node" "${extra_args[@]}"
