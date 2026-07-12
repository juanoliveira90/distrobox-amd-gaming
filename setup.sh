#!/usr/bin/env bash
# Full setup: run all steps in order. Each step is idempotent, so re-running
# this after a failure (or to pick up config changes) is safe.
set -euo pipefail
cd "$(dirname "$0")"
source lib/common.sh

# Printed on every exit path so failed packages are never silently lost.
report_failed_packages() {
  [ -s "$FAILED_PACKAGES_FILE" ] || return 0
  echo
  warn "the following packages were NOT installed:"
  sed 's/^/    - /' "$FAILED_PACKAGES_FILE" >&2
  warn "re-run ./setup.sh to retry, or install them manually inside the box"
}
trap report_failed_packages EXIT

for script in scripts/00-check-host.sh \
              scripts/01-create-box.sh \
              scripts/02-install-packages.sh \
              scripts/03-link-storage.sh \
              scripts/04-export-apps.sh \
              scripts/05-verify.sh \
              scripts/06-setup-srm.sh \
              scripts/07-setup-shell-hook.sh; do
  echo
  echo "==> $script"
  if ! bash "$script"; then
    # Verification failures (e.g. a package that could not be installed)
    # should not block the remaining steps; anything else is fatal.
    [ "$script" = scripts/05-verify.sh ] \
      || die "$script failed — fix the error above and re-run ./setup.sh"
    warn "verification reported failures — continuing with remaining steps"
  fi
done

echo
echo "Setup complete. Enter the box with: distrobox enter $BOX_NAME"
