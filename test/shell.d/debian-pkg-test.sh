#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

stub_bin="$test_tmp/bin"
mkdir -p "$stub_bin"

cat >"$stub_bin/sudo" <<'STUB'
#!/bin/bash
printf 'sudo\t%s\n' "$*" >>"$TEST_LOG"
"$@"
STUB

cat >"$stub_bin/apt-get" <<'STUB'
#!/bin/bash
printf 'apt-get\t%s\n' "$*" >>"$TEST_LOG"
STUB

cat >"$stub_bin/dpkg-query" <<'STUB'
#!/bin/bash
printf 'ii  '
STUB

chmod +x "$stub_bin/sudo" "$stub_bin/apt-get" "$stub_bin/dpkg-query"

export TEST_LOG="$test_tmp/calls.log"
export PATH="$stub_bin:$PATH"
export OMARCHY_PATH="$ROOT"
export OMARCHY_PLATFORM=debian
export OMARCHY_ARCHITECTURE=arm64

"$ROOT/bin/omarchy-pkg-add" libreoffice-fresh cups-pdf pinta hyprland

grep -q $'^apt-get\tinstall -y --no-install-recommends libreoffice printer-driver-cups-pdf drawing$' "$TEST_LOG" ||
  fail "Debian package add resolves stable package names"
grep -q $'^apt-get\tinstall -y --no-install-recommends -t trixie-backports hyprland$' "$TEST_LOG" ||
  fail "Debian package add selects Backports explicitly"
pass "Debian package add resolves stable and Backports packages"

: >"$TEST_LOG"
"$ROOT/bin/omarchy-pkg-add" docker
grep -q $'^apt-get\tinstall -y --no-install-recommends docker.io docker-cli docker-buildx$' "$TEST_LOG" ||
  fail "Debian Docker mapping installs the daemon, client, and Buildx"
pass "Debian Docker package mapping includes the complete command-line toolchain"

: >"$TEST_LOG"
"$ROOT/bin/omarchy-pkg-add" mise-bin
grep -q $'^apt-get\tinstall -y --no-install-recommends mise$' "$TEST_LOG" ||
  fail "Debian mise mapping installs the vendor package"
pass "Debian maps the upstream mise package identifier"

"$ROOT/bin/omarchy-pkg-present" libreoffice-fresh hyprland ||
  fail "Debian package presence checks resolved package names"
pass "Debian package presence checks resolved package names"

: >"$TEST_LOG"
if "$ROOT/bin/omarchy-pkg-add" steam >/dev/null 2>&1; then
  fail "Debian package add rejects unsupported arm64 applications"
fi
[[ ! -s $TEST_LOG ]] || fail "unsupported packages do not invoke APT"
pass "Debian package add rejects unsupported arm64 applications before APT"

duplicate_ids=$(awk -F '\t' '
  $1 !~ /^#/ && NF { count[$1]++ }
  END { for (id in count) if (count[id] > 1) print id }
' "$ROOT/install/debian/package-map.tsv")
[[ -z $duplicate_ids ]] || fail "Debian package map contains duplicate identifiers" "$duplicate_ids"
pass "Debian package map identifiers are unique"

sed '/^#/d; /^[[:space:]]*$/d' "$ROOT/install/debian/unsupported-arm64.packages" | sort >"$test_tmp/unsupported-list"
awk -F '\t' '$3 == "unsupported" { print $1 }' "$ROOT/install/debian/package-map.tsv" | sort >"$test_tmp/unsupported-map"
diff -u "$test_tmp/unsupported-list" "$test_tmp/unsupported-map" >/dev/null ||
  fail "Debian unsupported manifest matches package-map decisions"
pass "Debian unsupported manifest matches package-map decisions"
