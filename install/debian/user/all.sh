run_logged "$OMARCHY_INSTALL/user/theme.sh"
run_logged "$OMARCHY_INSTALL/user/chromium.sh"
run_logged "$OMARCHY_INSTALL/user/git.sh"
run_logged "$OMARCHY_INSTALL/user/xcompose.sh"
run_logged "$OMARCHY_INSTALL/user/default-keyring.sh"

# Mise is not in Debian 13. It will become part of this path after Omarchy
# publishes a signed arm64 package. The core desktop must not depend on an
# unauthenticated installer fetched during privileged setup.
if omarchy-cmd-missing mise; then
  echo "Mise-backed development tools are deferred until the Debian package is installed." >&2
else
  run_logged "$OMARCHY_INSTALL/user/mise-work.sh"
  run_logged "$OMARCHY_INSTALL/user/mise.sh"
fi
