if [[ ${OMARCHY_PLATFORM:-$(omarchy-platform 2>/dev/null || echo arch)} == "arch" ]]; then
  run_logged "$OMARCHY_INSTALL/post-install/pacman.sh"
fi
run_logged "$OMARCHY_INSTALL/post-install/udev.sh"
run_logged "$OMARCHY_INSTALL/post-install/localdb.sh"
