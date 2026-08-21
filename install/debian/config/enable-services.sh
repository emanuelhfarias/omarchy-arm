# Enable only units present on this Debian installation. Some packages provide
# a socket, some a service, and minimal installations may omit optional units.
for unit in \
  cups.service \
  cups-browsed.service \
  avahi-daemon.service \
  docker.socket \
  NetworkManager.service \
  power-profiles-daemon.service \
  bluetooth.service; do
  if systemctl list-unit-files "$unit" --no-legend 2>/dev/null | grep -q "^$unit"; then
    systemctl enable "$unit"
  fi
done

# The bootstrap masks SDDM while packages are incomplete so a reboot cannot
# strand the user at a display manager with no Omarchy session. The session
# assets are installed by the time this system-configuration leaf runs.
if systemctl list-unit-files sddm.service --no-legend 2>/dev/null | grep -q '^sddm.service'; then
  systemctl unmask sddm.service
  systemctl enable sddm.service
fi

if systemctl list-unit-files NetworkManager-wait-online.service --no-legend 2>/dev/null |
    grep -q '^NetworkManager-wait-online.service'; then
  systemctl mask NetworkManager-wait-online.service
fi

systemctl set-default graphical.target
