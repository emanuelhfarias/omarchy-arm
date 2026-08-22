# Reconcile defaults that Debian creates before Omarchy is installed. Run this
# once per user so later changes to ~/.bashrc and Hyprland toggles remain theirs.

state_dir="$HOME/.local/state/omarchy/done"
state_file="$state_dir/debian-defaults-v1"

if [[ ! -f $state_file ]]; then
  omarchy_bashrc="$OMARCHY_PATH/default/bashrc"
  user_bashrc="$HOME/.bashrc"
  bashrc_backup="$HOME/.bashrc.before-omarchy"

  if ! cmp -s "$omarchy_bashrc" "$user_bashrc"; then
    if [[ -f $user_bashrc && ! -e $bashrc_backup ]]; then
      cp "$user_bashrc" "$bashrc_backup"
    fi
    cp "$omarchy_bashrc" "$user_bashrc"
  fi

  # Older Debian bootstraps copied the optional toggle implementations into
  # the active state directory, enabling no-gaps and square-window mode by
  # default. Remove only those known accidental flags.
  rm -f \
    "$HOME/.local/state/omarchy/toggles/hypr/window-no-gaps.lua" \
    "$HOME/.local/state/omarchy/toggles/hypr/single-window-aspect-ratio.lua"

  mkdir -p "$state_dir"
  touch "$state_file"
fi
