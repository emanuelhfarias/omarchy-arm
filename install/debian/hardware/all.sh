# The initial Debian ARM release intentionally limits hardware setup to generic,
# architecture-neutral behavior. Board-specific profiles belong here once they
# have real-device acceptance coverage.
run_logged "$OMARCHY_INSTALL/hardware/input-group.sh"
run_logged "$OMARCHY_INSTALL/hardware/bluetooth.sh"
