# Debian's fonts-jetbrains-mono package contains the unpatched typeface, while
# Omarchy's terminal and shell use Nerd Font glyphs. Install a small, pinned
# subset of the official Nerd Fonts release for both arm64 and amd64.

font_version=v3.4.0
font_archive_sha256=ef552a3e638f25125c6ad4c51176a6adcdce295ab1d2ffacf0db060caf8c1582
font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/$font_version/JetBrainsMono.tar.xz"
font_dir=/usr/local/share/fonts/omarchy/jetbrains-mono-nerd
font_version_file="$font_dir/.version"
font_files=(
  JetBrainsMonoNerdFont-Regular.ttf
  JetBrainsMonoNerdFont-Bold.ttf
  JetBrainsMonoNerdFont-Italic.ttf
  JetBrainsMonoNerdFont-BoldItalic.ttf
)

font_install_required=0
if [[ ! -f $font_version_file ]] || [[ $(<"$font_version_file") != "$font_version" ]]; then
  font_install_required=1
else
  for font_file in "${font_files[@]}"; do
    if [[ ! -f $font_dir/$font_file ]]; then
      font_install_required=1
      break
    fi
  done
fi

if (( font_install_required )); then
  font_temp_dir=$(mktemp -d)
  font_archive="$font_temp_dir/JetBrainsMono.tar.xz"

  cleanup_font_temp_dir() {
    rm -rf "$font_temp_dir"
  }
  trap cleanup_font_temp_dir EXIT

  curl -fL --retry 5 --retry-all-errors -o "$font_archive" "$font_url"
  echo "$font_archive_sha256  $font_archive" | sha256sum --check --status

  mkdir -p "$font_temp_dir/extracted"
  tar -xJf "$font_archive" -C "$font_temp_dir/extracted" "${font_files[@]}"
  install -d -m 0755 "$font_dir"
  for font_file in "${font_files[@]}"; do
    install -m 0644 "$font_temp_dir/extracted/$font_file" "$font_dir/$font_file"
  done
  echo "$font_version" >"$font_version_file"
  fc-cache -f
else
  echo "JetBrains Mono Nerd Font $font_version is already installed."
fi
