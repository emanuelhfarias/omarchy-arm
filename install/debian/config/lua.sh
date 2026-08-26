# Debian keeps the previously selected Lua alternative when a newer interpreter
# is installed alongside it. Omarchy's Hyprland helpers require Lua 5.2+
# features such as package.searchpath, so pin the unversioned commands to 5.4.
update-alternatives --set lua-interpreter /usr/bin/lua5.4
