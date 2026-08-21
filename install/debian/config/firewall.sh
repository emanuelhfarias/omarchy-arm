# Configure the same default policy as Omarchy without the Arch-only ufw-docker
# helper. Docker-specific forwarding policy remains managed by Debian's Docker
# integration until a Debian-native equivalent is adopted.
ufw default deny incoming
ufw default allow outgoing
ufw allow 53317/udp
ufw allow 53317/tcp

if [[ -f /etc/ufw/ufw.conf ]]; then
  sed -i 's/^ENABLED=.*/ENABLED=yes/' /etc/ufw/ufw.conf
fi

systemctl enable ufw.service
