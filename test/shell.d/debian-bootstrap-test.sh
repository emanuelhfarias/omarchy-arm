#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

base_packages="$ROOT/install/debian/omarchy-base.packages"
bootstrap="$ROOT/bootstrap/debian"
services="$ROOT/install/debian/config/enable-services.sh"
debian_config="$ROOT/install/debian/config/all.sh"
lua_config="$ROOT/install/debian/config/lua.sh"
install_assets="$ROOT/install/debian/install-assets.sh"
debian_monitors="$ROOT/install/debian/defaults/hypr/monitors.lua"
sddm_config="$ROOT/etc/sddm.conf.d/10-wayland.conf"
sddm_theme="$ROOT/default/sddm/omarchy/Main.qml"
font_installer="$ROOT/install/debian/install-fonts.sh"
foot_template="$ROOT/default/themed/foot.ini.tpl"
user_defaults="$ROOT/install/user/debian-defaults.sh"
test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

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

grep -qxF gawk "$base_packages" ||
  fail "Debian installs GNU awk for the keybindings parser"
grep -q '^  gawk ' "$ROOT/bin/omarchy-menu-keybindings" ||
  fail "Keybindings parser explicitly uses GNU awk"
pass "Debian installs the parser required by the keybindings menu"

grep -qxF lua5.4 "$base_packages" ||
  fail "Debian installs modern Lua for the current Hyprland helpers"
if grep -qxF lua5.1 "$base_packages"; then
  fail "Debian no longer selects Lua 5.1 as its default interpreter"
fi
grep -qxF libxkbcommon-tools "$base_packages" ||
  fail "Debian installs xkbcli for keyboard-layout discovery"
grep -q 'debian/config/lua.sh' "$debian_config" ||
  fail "Debian system setup reconciles the default Lua interpreter"
grep -q 'update-alternatives --set lua-interpreter /usr/bin/lua5.4' "$lua_config" ||
  fail "Debian selects Lua 5.4 for the unversioned lua command"
pass "Debian installs the current Hyprland and keyboard-layout runtimes"

for docker_package in docker.io docker-cli docker-buildx docker-compose; do
  grep -qxF "$docker_package" "$base_packages" ||
    fail "Debian installs the complete Docker toolchain: $docker_package"
done
pass "Debian installs the Docker daemon, client, Buildx, and Compose"

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

grep -q 'output = "Virtual-1"' "$debian_monitors" ||
  fail "Debian fresh installs target the Parallels virtual display"
grep -q 'mode = "2560x1600@59.99"' "$debian_monitors" ||
  fail "Debian fresh installs use the tested Parallels Retina mode"
grep -q 'local omarchy_monitor_scale = 2' "$debian_monitors" ||
  fail "Debian fresh installs use the tested Parallels Retina scale"
grep -q 'install/debian/defaults/hypr/monitors.lua' "$install_assets" ||
  fail "Debian assets install the Parallels monitor defaults into the skeleton"
pass "Debian fresh installs include the tested Parallels display configuration"

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

if grep -q 'cp -an "$OMARCHY_PATH/default/hypr/toggles/."' "$install_assets"; then
  fail "Debian skeleton does not enable optional Hyprland toggles"
fi
grep -q 'default/hypr/toggles/flags.lua' "$install_assets" ||
  fail "Debian skeleton retains the inert Hyprland toggle placeholder"
pass "Debian skeleton starts with window gaps and borders enabled"

defaults_home="$test_tmp/defaults-home"
mkdir -p "$defaults_home/.local/state/omarchy/toggles/hypr"
printf 'debian bashrc\n' >"$defaults_home/.bashrc"
cp "$ROOT/default/hypr/toggles/window-no-gaps.lua" "$defaults_home/.local/state/omarchy/toggles/hypr/"
cp "$ROOT/default/hypr/toggles/single-window-aspect-ratio.lua" "$defaults_home/.local/state/omarchy/toggles/hypr/"
touch "$defaults_home/.local/state/omarchy/toggles/hypr/custom.lua"

HOME="$defaults_home" OMARCHY_PATH="$ROOT" bash -eE -c 'source "$1"' bash "$user_defaults"

cmp -s "$ROOT/default/bashrc" "$defaults_home/.bashrc" ||
  fail "Debian reconciliation installs the Omarchy bashrc"
grep -qxF 'debian bashrc' "$defaults_home/.bashrc.before-omarchy" ||
  fail "Debian reconciliation backs up the previous bashrc"
[[ ! -e $defaults_home/.local/state/omarchy/toggles/hypr/window-no-gaps.lua ]] ||
  fail "Debian reconciliation removes the accidental no-gaps toggle"
[[ ! -e $defaults_home/.local/state/omarchy/toggles/hypr/single-window-aspect-ratio.lua ]] ||
  fail "Debian reconciliation removes the accidental single-window toggle"
[[ -e $defaults_home/.local/state/omarchy/toggles/hypr/custom.lua ]] ||
  fail "Debian reconciliation preserves unrelated user toggles"

printf '# user customization\n' >>"$defaults_home/.bashrc"
HOME="$defaults_home" OMARCHY_PATH="$ROOT" bash -eE -c 'source "$1"' bash "$user_defaults"
grep -qxF '# user customization' "$defaults_home/.bashrc" ||
  fail "Debian reconciliation runs only once per user"
grep -q 'user/debian-defaults.sh' "$bootstrap" ||
  fail "Debian bootstrap reconciles defaults for existing installations"
pass "Debian bootstrap repairs prior user defaults without overwriting later changes"

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
