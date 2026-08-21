#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

base_packages="$ROOT/install/debian/omarchy-base.packages"
bootstrap="$ROOT/bootstrap/debian"
services="$ROOT/install/debian/config/enable-services.sh"

if grep -qxF systemd-resolved "$base_packages"; then
  fail "Debian bootstrap does not replace DNS ownership during package installation"
fi
pass "Debian bootstrap preserves the installed system's DNS ownership"

grep -q 'Acquire::Retries=5' "$bootstrap" ||
  fail "Debian bootstrap retries transient package download failures"
grep -q 'getent ahosts deb.debian.org' "$bootstrap" ||
  fail "Debian bootstrap checks DNS before package operations"
pass "Debian bootstrap checks and retries package network access"

grep -q 'systemctl mask --now sddm.service' "$bootstrap" ||
  fail "Debian bootstrap masks SDDM while package installation is incomplete"
grep -q 'systemctl unmask sddm.service' "$services" ||
  fail "Debian system setup unmasks SDDM after installing the session"
pass "Debian bootstrap cannot expose an incomplete graphical login"

runtime_copy=$(grep '^for entry in ' "$bootstrap")
for required_entry in applications bin config default etc install migrations shell themes version icon.png icon.txt logo.svg logo.txt; do
  if [[ " $runtime_copy " != *" $required_entry "* && " $runtime_copy " != *" $required_entry;"* ]]; then
    fail "Debian runtime copy includes $required_entry"
  fi
done
pass "Debian runtime copy contains every required source tree and branding asset"
