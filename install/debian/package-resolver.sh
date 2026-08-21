# Debian package-name resolution shared by package helpers and the bootstrap.

debian_package_map=${OMARCHY_DEBIAN_PACKAGE_MAP:-${OMARCHY_PATH:-/usr/share/omarchy}/install/debian/package-map.tsv}

debian_package_record() {
  local requested=$1
  local architecture=${2:-${OMARCHY_ARCHITECTURE:-}}
  local package_id packages suite architectures description

  if [[ -z $architecture ]]; then
    if command -v omarchy-architecture >/dev/null; then
      architecture=$(omarchy-architecture)
    else
      case "$(uname -m)" in
        aarch64|arm64) architecture=arm64 ;;
        x86_64|amd64) architecture=amd64 ;;
        armv7l|armhf) architecture=armhf ;;
        *) architecture=$(uname -m) ;;
      esac
    fi
  else
    case "$architecture" in
      aarch64) architecture=arm64 ;;
      x86_64) architecture=amd64 ;;
      armv7l) architecture=armhf ;;
    esac
  fi

  [[ -r $debian_package_map ]] || {
    echo "Error: Debian package map is missing: $debian_package_map" >&2
    return 1
  }

  while IFS=$'\t' read -r package_id packages suite architectures description; do
    [[ -n $package_id && $package_id != \#* ]] || continue
    [[ $package_id == "$requested" ]] || continue

    if [[ $architectures != "all" && " $architectures " != *" $architecture "* ]]; then
      echo "Error: '$requested' is not available on $architecture${description:+ ($description)}" >&2
      return 2
    fi

    if [[ $suite == "unsupported" || $packages == "-" ]]; then
      echo "Error: '$requested' is not supported on Debian${description:+ ($description)}" >&2
      return 2
    fi

    printf '%s\t%s\t%s\n' "$requested" "$packages" "$suite"
    return 0
  done <"$debian_package_map"

  # Native Debian package names need no explicit mapping. This escape hatch is
  # also what keeps `omarchy pkg add foo` useful for packages outside Omarchy's
  # curated application list.
  printf '%s\t%s\tstable\n' "$requested" "$requested"
}

debian_packages_installed() {
  local package

  for package in "$@"; do
    dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii ' || return 1
  done
}
