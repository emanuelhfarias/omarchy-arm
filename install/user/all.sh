if [[ ${OMARCHY_PLATFORM:-$(omarchy-platform 2>/dev/null || echo arch)} == "debian" ]]; then
  source "$OMARCHY_INSTALL/debian/user/all.sh"
else
  run_logged "$OMARCHY_INSTALL/user/theme.sh"
  run_logged "$OMARCHY_INSTALL/user/chromium.sh"
  run_logged "$OMARCHY_INSTALL/user/git.sh"
  run_logged "$OMARCHY_INSTALL/user/xcompose.sh"
  run_logged "$OMARCHY_INSTALL/user/mise-work.sh"

  run_logged "$OMARCHY_INSTALL/user/hardware/asus/fix-audio-mixer.sh"
  run_logged "$OMARCHY_INSTALL/user/hardware/asus/fix-mic.sh"
  run_logged "$OMARCHY_INSTALL/user/hardware/framework/fix-f13-amd-audio-input.sh"
  run_logged "$OMARCHY_INSTALL/user/hardware/dell/xps13-text-scaling.sh"
  run_logged "$OMARCHY_INSTALL/user/hardware/fix-nouveau-cursor.sh"

  run_logged "$OMARCHY_INSTALL/user/default-keyring.sh"
  run_logged "$OMARCHY_INSTALL/user/mise.sh"
fi
