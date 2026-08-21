if [[ ${OMARCHY_PLATFORM:-$(omarchy-platform 2>/dev/null || echo arch)} == "arch" ]]; then
  run_logged "$OMARCHY_INSTALL/login/sddm.sh"
fi
