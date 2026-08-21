#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

printf '%s\n' 'ID=debian' 'VERSION_ID="13"' >"$test_tmp/debian-release"
[[ $(OMARCHY_OS_RELEASE_FILE="$test_tmp/debian-release" "$ROOT/bin/omarchy-platform") == "debian" ]] ||
  fail "platform helper detects Debian"
pass "platform helper detects Debian"

printf '%s\n' 'ID=endeavouros' 'ID_LIKE="arch"' >"$test_tmp/arch-release"
[[ $(OMARCHY_OS_RELEASE_FILE="$test_tmp/arch-release" "$ROOT/bin/omarchy-platform") == "arch" ]] ||
  fail "platform helper detects Arch derivatives"
pass "platform helper detects Arch derivatives"

printf '%s\n' 'ID=fedora' >"$test_tmp/unknown-release"
if OMARCHY_OS_RELEASE_FILE="$test_tmp/unknown-release" "$ROOT/bin/omarchy-platform" >/dev/null 2>&1; then
  fail "platform helper rejects unsupported distributions"
fi
pass "platform helper rejects unsupported distributions"

[[ $(OMARCHY_ARCHITECTURE=aarch64 "$ROOT/bin/omarchy-architecture") == "arm64" ]] ||
  fail "architecture helper normalizes aarch64"
[[ $(OMARCHY_ARCHITECTURE=x86_64 "$ROOT/bin/omarchy-architecture") == "amd64" ]] ||
  fail "architecture helper normalizes x86_64"
pass "architecture helper normalizes kernel architecture names"
