#!/usr/bin/env bash

set -euo pipefail

ansible_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
env_file="${ANSIBLE_ENV_FILE:-$ansible_dir/.env}"
ansible_playbook="${ANSIBLE_PLAYBOOK_BIN:-$ansible_dir/.venv/bin/ansible-playbook}"

cd "$ansible_dir"

if [[ -f "$env_file" ]]; then
  set -a
  # The ignored .env is trusted controller-local configuration.
  # shellcheck disable=SC1090
  source "$env_file"
  set +a
fi

if [[ ! -x "$ansible_playbook" ]]; then
  echo "Ansible is not installed at $ansible_playbook." >&2
  echo "Follow the controller setup in README.md first." >&2
  exit 1
fi

if [[ $# -eq 0 ]]; then
  set -- site.yml
fi

exec "$ansible_playbook" "$@"
