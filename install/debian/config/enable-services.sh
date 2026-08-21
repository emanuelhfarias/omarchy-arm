# Enable only units present on this Debian installation. Some packages provide
# a socket, some a service, and minimal installations may omit optional units.
for unit in \
  cups.service \
  cups-browsed.service \
  avahi-daemon.service \
  docker.socket \
  NetworkManager.service \
  power-profiles-daemon.service \
  sddm.service \
  bluetooth.service; do
  if systemctl list-unit-files "$unit" --no-legend 2>/dev/null | grep -q "^$unit"; then
    systemctl enable "$unit"
  fi
done

if systemctl list-unit-files NetworkManager-wait-online.service --no-legend 2>/dev/null |
    grep -q '^NetworkManager-wait-online.service'; then
  systemctl mask NetworkManager-wait-online.service
fi

systemctl set-default graphical.target
