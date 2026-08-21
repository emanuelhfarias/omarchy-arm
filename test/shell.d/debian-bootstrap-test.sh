#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

base_packages="$ROOT/install/debian/omarchy-base.packages"
bootstrap="$ROOT/bootstrap/debian"
services="$ROOT/install/debian/config/enable-services.sh"
install_assets="$ROOT/install/debian/install-assets.sh"
sddm_config="$ROOT/etc/sddm.conf.d/10-wayland.conf"
sddm_theme="$ROOT/default/sddm/omarchy/Main.qml"

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

grep -qxF 'CompositorCommand=start-hyprland -- --config /usr/share/sddm/hyprland.lua' "$sddm_config" ||
  fail "SDDM starts its Hyprland greeter through start-hyprland"
if grep -q 'sddm-wayland.conf' "$install_assets"; then
  fail "Debian assets do not overwrite the shared SDDM configuration"
fi
pass "Debian installs the supported Hyprland launcher for the SDDM greeter"

grep -q 'userModel.lastUser.length > 0' "$sddm_theme" ||
  fail "SDDM uses the remembered user after a successful login"
grep -q 'userModel.data(userModel.index(0, 0), Qt.UserRole + 1)' "$sddm_theme" ||
  fail "SDDM selects the first visible user before the first successful login"
pass "SDDM can authenticate a user on a fresh installation"

asset_install_line=$(grep -n '^echo "==> Install Omarchy system assets"' "$bootstrap" | cut -d: -f1)
system_config_guard_line=$(grep -n '^if ! phase_done system-config; then' "$bootstrap" | cut -d: -f1)
if [[ -z $asset_install_line || -z $system_config_guard_line ]] || (( asset_install_line >= system_config_guard_line )); then
  fail "Debian bootstrap refreshes system assets on every rerun"
fi
pass "Debian bootstrap refreshes system assets after runtime updates"
