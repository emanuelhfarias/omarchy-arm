# Install the platform-neutral Omarchy settings used by the source bootstrap.
# Production releases move these operations into the omarchy-settings package.

install -d -m 0755 \
  /etc/skel/.config \
  /etc/skel/.local/share/applications \
  /etc/skel/.local/state/omarchy/toggles/hypr \
  /etc/skel/.local/share/nautilus-python/extensions \
  /etc/profile.d \
  /etc/fonts/conf.d \
  /usr/lib/environment.d \
  /usr/lib/systemd/user/app.slice.d \
  /usr/lib/systemd/user \
  /usr/lib/systemd/zram-generator.conf.d \
  /usr/local/bin \
  /usr/local/share/wayland-sessions \
  /usr/share/applications \
  /usr/share/fonts/omarchy \
  /usr/share/fontconfig/conf.avail \
  /usr/share/icons/hicolor/512x512/apps \
  /usr/share/plymouth/themes/omarchy \
  /usr/share/sddm/themes \
  /usr/share/uwsm/env.d \
  /usr/share/wireplumber/wireplumber.conf.d \
  /usr/share/xdg-terminal-exec

cp -an "$OMARCHY_PATH/config/." /etc/skel/.config/
cp -an "$OMARCHY_PATH/applications/." /etc/skel/.local/share/applications/
cp -an "$OMARCHY_PATH/default/hypr/toggles/." /etc/skel/.local/state/omarchy/toggles/hypr/
cp -an "$OMARCHY_PATH/default/nautilus-python/extensions/." /etc/skel/.local/share/nautilus-python/extensions/
cp -n "$OMARCHY_PATH/default/bashrc" /etc/skel/.bashrc

install -Dm0644 "$OMARCHY_PATH/etc/profile.d/omarchy.sh" /etc/profile.d/omarchy.sh
install -Dm0644 "$OMARCHY_PATH/default/environment.d/10-omarchy-fcitx.conf" /usr/lib/environment.d/10-omarchy-fcitx.conf
install -Dm0644 "$OMARCHY_PATH/default/fontconfig/conf.avail/50-omarchy.conf" /usr/share/fontconfig/conf.avail/50-omarchy.conf
ln -sfn /usr/share/fontconfig/conf.avail/50-omarchy.conf /etc/fonts/conf.d/50-omarchy.conf
install -Dm0644 "$OMARCHY_PATH/default/uwsm/env.d/10-omarchy" /usr/share/uwsm/env.d/10-omarchy
install -Dm0644 "$OMARCHY_PATH/default/uwsm/default" /usr/share/uwsm/default
install -Dm0644 "$OMARCHY_PATH/default/wayland-sessions/omarchy.desktop" /usr/local/share/wayland-sessions/omarchy.desktop
install -Dm0644 "$OMARCHY_PATH/default/xdg-terminal-exec/hyprland-xdg-terminals.list" /usr/share/xdg-terminal-exec/hyprland-xdg-terminals.list
install -Dm0644 "$OMARCHY_PATH/default/applications/mimeapps.list" /usr/share/applications/mimeapps.list
install -Dm0644 "$OMARCHY_PATH/default/fonts/omarchy/omarchy.ttf" /usr/share/fonts/omarchy/omarchy.ttf
install -Dm0644 "$OMARCHY_PATH/default/systemd/user/app.slice.d/10-oomd.conf" /usr/lib/systemd/user/app.slice.d/10-oomd.conf
install -Dm0644 "$OMARCHY_PATH/default/systemd/zram-generator.conf.d/90-omarchy.conf" /usr/lib/systemd/zram-generator.conf.d/90-omarchy.conf
cp -a "$OMARCHY_PATH/default/sddm/omarchy" /usr/share/sddm/themes/
install -Dm0644 "$OMARCHY_PATH/default/sddm/hyprland.lua" /usr/share/sddm/hyprland.lua
cp -a "$OMARCHY_PATH/default/plymouth/omarchy.plymouth" "$OMARCHY_PATH/default/plymouth/omarchy.script" "$OMARCHY_PATH/default/plymouth"/*.png /usr/share/plymouth/themes/omarchy/
cp -a "$OMARCHY_PATH/default/wireplumber/wireplumber.conf.d/." /usr/share/wireplumber/wireplumber.conf.d/

for icon in "$OMARCHY_PATH"/applications/icons/*.png; do
  [[ -f $icon ]] || continue
  icon_name=$(basename "${icon%.png}" | tr '[:upper:] ' '[:lower:]-')
  install -m 0644 "$icon" "/usr/share/icons/hicolor/512x512/apps/$icon_name.png"
done

for unit in "$OMARCHY_PATH"/default/systemd/user/*.service; do
  [[ -f $unit ]] || continue
  install -m 0644 "$unit" /usr/lib/systemd/user/
done

for config_dir in NetworkManager docker fastfetch gnupg sysctl.d systemd tmpfiles.d; do
  [[ -d $OMARCHY_PATH/etc/$config_dir ]] || continue
  cp -a "$OMARCHY_PATH/etc/$config_dir" /etc/
done

if [[ -d $OMARCHY_PATH/etc/sddm.conf.d ]]; then
  cp -a "$OMARCHY_PATH/etc/sddm.conf.d" /etc/
  install -m 0644 "$OMARCHY_INSTALL/debian/assets/sddm-wayland.conf" /etc/sddm.conf.d/10-wayland.conf
fi

for sudoers_file in "$OMARCHY_PATH"/etc/sudoers.d/*; do
  [[ -f $sudoers_file ]] || continue
  install -Dm0440 "$sudoers_file" "/etc/sudoers.d/$(basename "$sudoers_file")"
done

for command in "$OMARCHY_PATH"/bin/omarchy "$OMARCHY_PATH"/bin/omarchy-*; do
  [[ -f $command ]] || continue
  ln -sfn "$command" "/usr/local/bin/$(basename "$command")"
done

if command -v fdfind >/dev/null && ! command -v fd >/dev/null; then
  ln -sfn /usr/bin/fdfind /usr/local/bin/fd
fi

if command -v hyprland-share-picker >/dev/null && ! command -v hyprland-preview-share-picker >/dev/null; then
  ln -sfn /usr/bin/hyprland-share-picker /usr/local/bin/hyprland-preview-share-picker
fi

fc-cache -f
gtk-update-icon-cache /usr/share/icons/hicolor >/dev/null 2>&1 || true
systemctl daemon-reload
