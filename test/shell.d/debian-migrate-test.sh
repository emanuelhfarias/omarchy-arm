#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

mkdir -p "$test_tmp/omarchy/migrations" "$test_tmp/home" "$test_tmp/bin"

cat >"$test_tmp/omarchy/migrations/100-arch.sh" <<'MIGRATION'
echo arch >>"$MIGRATION_LOG"
MIGRATION

cat >"$test_tmp/omarchy/migrations/200-common.sh" <<'MIGRATION'
# omarchy:platforms=arch,debian
echo common >>"$MIGRATION_LOG"
MIGRATION

cat >"$test_tmp/bin/omarchy-notification-dismiss" <<'STUB'
#!/bin/bash
exit 0
STUB
chmod +x "$test_tmp/bin/omarchy-notification-dismiss"

export HOME="$test_tmp/home"
export MIGRATION_LOG="$test_tmp/migrations.log"
export OMARCHY_MIGRATION_STATE="$test_tmp/state"
export OMARCHY_PATH="$test_tmp/omarchy"
export OMARCHY_PLATFORM=debian
export PATH="$test_tmp/bin:$ROOT/bin:$PATH"

pending=$("$ROOT/bin/omarchy-migrate" --pending)
[[ $pending == "200-common.sh" ]] ||
  fail "Debian pending migrations include only explicitly compatible migrations" "$pending"
pass "Debian pending migrations include only explicitly compatible migrations"

"$ROOT/bin/omarchy-migrate" >/dev/null

[[ $(<"$MIGRATION_LOG") == "common" ]] || fail "Debian skips historical Arch-only migrations"
[[ -f $OMARCHY_MIGRATION_STATE/100-arch.sh && -f $OMARCHY_MIGRATION_STATE/200-common.sh ]] ||
  fail "Debian records both skipped and applied migration decisions"
pass "Debian skips historical Arch-only migrations and records the decision"
