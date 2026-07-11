#!/usr/bin/env bash
# Full setup: run all steps in order. Each step is idempotent, so re-running
# this after a failure (or to pick up config changes) is safe.
set -euo pipefail
cd "$(dirname "$0")"

for script in scripts/00-check-host.sh \
              scripts/01-create-box.sh \
              scripts/02-install-packages.sh \
              scripts/03-link-storage.sh \
              scripts/04-export-apps.sh \
              scripts/05-verify.sh \
              scripts/06-setup-srm.sh \
              scripts/07-setup-shell-hook.sh \
              scripts/08-setup-esde.sh; do
  echo
  echo "==> $script"
  bash "$script"
done

echo
echo "Setup complete. Enter the box with: distrobox enter gaming"
