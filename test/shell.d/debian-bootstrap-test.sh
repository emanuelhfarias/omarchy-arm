#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

base_packages="$ROOT/install/debian/omarchy-base.packages"
bootstrap="$ROOT/bootstrap/debian"
services="$ROOT/install/debian/config/enable-services.sh"
install_assets="$ROOT/install/debian/install-assets.sh"
sddm_config="$ROOT/etc/sddm.conf.d/10-wayland.conf"
sddm_theme="$ROOT/default/sddm/omarchy/Main.qml"
font_installer="$ROOT/install/debian/install-fonts.sh"
foot_template="$ROOT/default/themed/foot.ini.tpl"

if grep -qxF systemd-resolved "$base_packages"; then
  fail "Debian bootstrap does not replace DNS ownership during package installation"
fi
pass "Debian bootstrap preserves the installed system's DNS ownership"

grep -q 'Acquire::Retries=5' "$bootstrap" ||
  fail "Debian bootstrap retries transient package download failures"
grep -q 'getent ahosts deb.debian.org' "$bootstrap" ||
  fail "Debian bootstrap checks DNS before package operations"
pass "Debian bootstrap checks and retries package network access"

packages_guard_end=$(awk '/^if ! phase_done packages; then$/ { in_guard=1; next } in_guard && /^fi$/ { print NR; exit }' "$bootstrap")
first_package_install=$(grep -n 'apt_get install -y --no-install-recommends "${stable_packages\[@\]}"' "$bootstrap" | cut -d: -f1)
if [[ -z $packages_guard_end || -z $first_package_install ]] || (( first_package_install <= packages_guard_end )); then
  fail "Debian bootstrap reconciles package-list changes after the first install"
fi
pass "Debian bootstrap installs newly added packages on rerun"

grep -qxF qml6-module-qtquick-effects "$base_packages" ||
  fail "Debian installs the Qt Quick effects required by Omarchy shell plugins"
pass "Debian installs the Omarchy shell QML effects module"

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

grep -qxF xz-utils "$base_packages" ||
  fail "Debian installs support for the pinned Nerd Font archive"
grep -q 'install/debian/install-fonts.sh' "$bootstrap" ||
  fail "Debian bootstrap installs the Omarchy Nerd Font"
grep -q '^font_version=v3\.4\.0$' "$font_installer" ||
  fail "Debian Nerd Font download is version-pinned"
grep -q '^font_archive_sha256=[0-9a-f]\{64\}$' "$font_installer" ||
  fail "Debian Nerd Font download is checksum-pinned"
pass "Debian installs the required JetBrains Mono Nerd Font safely"

grep -qxF '[colors]' "$foot_template" ||
  fail "Foot theme uses Debian 13's supported colors section"
if grep -q '^\[colors-dark\]$' "$foot_template"; then
  fail "Foot theme does not use an unsupported Debian section"
fi
grep -qxF '[cursor]' "$foot_template" ||
  fail "Foot theme uses Debian 13's cursor section"
grep -q '^color={{ background_strip }} {{ bright_foreground_strip }}$' "$foot_template" ||
  fail "Foot theme places its cursor colors under the supported key"
if grep -q '^cursor=' "$foot_template"; then
  fail "Foot theme does not place cursor configuration in the colors section"
fi
grep -q 'echo "==> Refresh the current Omarchy theme"' "$bootstrap" ||
  fail "Debian bootstrap regenerates existing rendered theme files"
pass "Debian bootstrap repairs rendered Foot themes on rerun"
