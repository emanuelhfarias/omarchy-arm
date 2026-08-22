# Debian ARM port

## Goal

Port the Omarchy 4 desktop experience to Debian 13 so a user can start with a fresh Debian installation, run one bootstrap command, reboot, and enter the same Hyprland, Quickshell, theme, application-launcher, and command environment on arm64 hardware.

The port preserves Arch Linux support while adding Debian as a platform backend. Portable desktop code remains shared. Package management, system configuration, updates, boot integration, and hardware setup become platform-specific where their behavior genuinely differs.

## Initial support boundary

The first supported target is Debian 13 (Trixie) on arm64, using stable packages plus explicitly selected packages from Trixie Backports. The same Debian path should work on amd64 so it can be tested cheaply, but arm64 is the release requirement.

The host must already have:

- A working Debian installation with systemd.
- A non-root user with sudo access.
- Working networking.
- A bootloader and kernel appropriate for the machine.
- A DRM/KMS graphics driver capable of running a Wayland compositor.

The bootstrap does not partition disks, replace the bootloader, create encrypted volumes, or promise support for every board sold as an arm64 machine. Board firmware and boot media remain the responsibility of Debian or the board vendor.

## Experience included in the first release

- Hyprland managed by UWSM and started from SDDM.
- The Omarchy Quickshell bar, panels, menus, notifications, and lock screen.
- Omarchy themes, keybindings, terminal configuration, browser integration, and web applications.
- NetworkManager, PipeWire/WirePlumber, Bluetooth, printing, clipboard, screenshots, and screen sharing.
- Chromium, Nautilus, terminal applications, and the core development command-line environment.
- Debian-aware package installation, removal, update checks, system updates, and migrations.
- A resumable and idempotent fresh-Debian bootstrap.

## Explicitly deferred

- Limine installation and Limine snapshot restore entries.
- mkinitcpio configuration; Debian uses its own initramfs tooling.
- Omarchy factory reset.
- Managed hibernation and Btrfs swap-file creation.
- Automatic repartitioning, disk encryption, or bootloader changes.
- Apple T2, Intel PTL, Surface, ASUS ROG, and other x86-specific hardware setup.
- Applications or games for which no arm64 build exists.

Deferred commands must fail with a short supported-platform explanation or be hidden by a platform guard. They must never partially apply an Arch procedure to Debian.

## Repository shape

### Shared trees

The following trees remain platform-neutral unless an individual file is proven otherwise:

- `shell/`
- `themes/`
- `applications/`
- `config/`
- most of `default/hypr/`
- commands in `bin/` that do not manage packages, the boot process, or distribution-owned system files

### Platform detection

`omarchy-platform` reads `/etc/os-release` and returns a normalized platform name. `omarchy-architecture` normalizes the machine architecture to Debian-style names such as `arm64` and `amd64`. Tests override the os-release and architecture sources rather than modifying the host.

Package and system commands must select behavior from these helpers. The presence of `apt`, `pacman`, or another executable is not sufficient platform detection.

### Package data

Package intent and distribution package names are separate concepts:

- `install/omarchy-base.packages` remains the Arch base set while Arch is supported.
- `install/debian/omarchy-base.packages` is the Debian core set using Debian package names.
- `install/debian/omarchy-backports.packages` contains packages that must be selected explicitly from Trixie Backports.
- `install/debian/package-map.tsv` maps existing Omarchy package identifiers to one or more Debian packages for shared and optional installers.
- `install/debian/unsupported-arm64.packages` records deliberately unavailable package identifiers and their alternatives.

The mapping is data, not a collection of `if Debian` branches spread across installer commands. Tests require every package identifier used by a shared installer to resolve, be marked as an Omarchy-built package, or be explicitly unsupported.

### Package helpers

The existing package-helper interface remains stable:

- `omarchy-pkg-add`
- `omarchy-pkg-drop`
- `omarchy-pkg-present`
- `omarchy-pkg-missing`
- `omarchy-pkg-install`
- `omarchy-pkg-remove`

On Arch these commands retain Pacman behavior. On Debian they resolve identifiers through the Debian map and use `apt-get` and `dpkg-query`. AUR-only commands report that the AUR is unavailable on Debian instead of attempting to invoke Yay.

### System setup

Root-owned setup is divided into common, Arch, and Debian leaves. Common orchestration is allowed to call only behavior that has been verified on both platforms.

The Debian setup must not install the repository's Arch-specific files under:

- `/etc/pacman*`
- `/usr/share/libalpm/`
- `/etc/mkinitcpio.conf.d/`
- `/etc/limine-entry-tool.d/`
- `/boot/limine.conf`

Package-owned Debian files such as PAM configuration and `nsswitch.conf` are not overwritten wholesale. Debian-specific drop-ins or narrowly targeted, backed-up edits are used instead.

### Debian packaging

The production distribution consists of two architecture-independent Debian binary packages:

- `omarchy` contains runtime commands, shell code, themes, migrations, and reusable install leaves.
- `omarchy-settings` contains `/etc/skel` defaults, systemd units, session definitions, fonts, launchers, and system assets.

Custom compiled applications are separate multi-architecture packages. Their build pipeline must publish arm64 artifacts before they become required by the Debian base set.

During early development the bootstrap may install a source checkout at `/usr/share/omarchy`, but a release is not complete until files under `/usr` are owned by Debian packages and updates can be authenticated.

## Fresh-Debian bootstrap

The public bootstrap is a standalone script because Omarchy commands are not installed yet. It performs these phases:

1. Validate Debian 13, systemd, the architecture, sudo access, networking, and free space.
2. Acquire the source or signed release artifacts into a staging directory.
3. Enable Debian components and Trixie Backports without using `apt-key`.
4. Install the Debian stable and backports package sets.
5. Install Omarchy runtime and settings files.
6. Seed the already-existing Debian user's home without overwriting existing files.
7. Apply Debian system configuration.
8. Run `omarchy-provision-user --first-install` as the target user.
9. Enable SDDM and the Omarchy Wayland session.
10. Run health checks and offer a reboot.

The bootstrap writes `/var/log/omarchy-install.log` and records completed phases under `/var/lib/omarchy/install/`. Re-running it resumes incomplete work. Each phase is independently safe to repeat.

The bootstrap never pipes downloaded package data directly into a privileged shell without verification. Release documentation provides a checksum/signature-verifying invocation as the preferred installation route.

During development, run the checked-out bootstrap directly:

```bash
git clone https://github.com/emanuelhfarias/omarchy-arm.git
cd omarchy-arm
./bootstrap/debian --source .
```

The source bootstrap installs the checkout into `/usr/share/omarchy`. It is suitable for port development and test machines; the signed Debian packages remain the production release gate.

### Parallels Desktop keyboard shortcuts

When running the Debian arm64 VM in Parallels Desktop on macOS, open **Parallels Desktop Preferences → Shortcuts → macOS System Shortcuts** and set **Send macOS system shortcuts** to **Always**. Omarchy treats the Mac Command key as Super, and the **Always** setting is required for combinations such as Command+Space to reach the VM as Super+Space instead of being handled by macOS. Super+Space opens the Omarchy menu, while other Super-based Omarchy keybindings depend on the same forwarding behavior.

## Existing-user configuration

Debian Installer normally creates the user before Omarchy is installed, so installing files into `/etc/skel` is not enough. The bootstrap copies missing defaults only, then runs `omarchy-provision-user --first-install` as the target user.

Existing files are preserved. The destructive `omarchy-reinstall-configs` command remains an explicit user action and is never invoked by the bootstrap.

## Update pipeline

The high-level update order remains shared:

1. Confirm and acquire the update lock.
2. Create a snapshot when a supported snapshot backend is configured.
3. Update system and Omarchy packages.
4. Run applicable migrations.
5. Run post-update hooks and user-managed tool updates.
6. Analyze status and recommend a restart when needed.

The Debian backend uses `apt-get update` followed by `apt-get full-upgrade`. Pacman keyring, ALPM conflict handling, Pacman cache pruning, and AUR update stages do not run on Debian. Orphan review uses a simulated APT autoremove before asking the user to remove anything.

## Migration compatibility

Historical migrations were written for an Arch system. Migration files gain platform metadata when they are intended for more than one platform. Existing migrations without platform metadata are treated as Arch-only on Debian.

A fresh Debian installation marks all migrations shipped at install time complete. Future common or Debian migrations explicitly declare their supported platforms and remain idempotent.

`omarchy-migrate` waits for the active package manager: `/var/lib/pacman/db.lck` on Arch and the dpkg/APT locks on Debian.

## Boot, snapshots, and hibernation

The initial Debian port leaves the Debian bootloader and initramfs configuration unchanged. Commands that require Limine or mkinitcpio report that the feature is unavailable on Debian.

Snapper create and cleanup may be enabled later on Btrfs because Snapper itself is available on Debian. Snapshot restoration from the boot menu, factory reset, and managed hibernation are separate projects because their current implementations depend on the Arch filesystem and Limine layout.

## Hardware policy

Generic setup includes input devices, NetworkManager, Bluetooth, PipeWire, brightness controls, firmware packages, and architecture-neutral udev rules.

Hardware leaves declare supported architectures and platforms. x86-specific scripts are skipped on arm64. ARM board work is added as named profiles rather than inferred from the architecture alone; Raspberry Pi, generic UEFI ARM, Apple Silicon, and vendor laptops have different kernels, boot chains, and GPU requirements.

## Application parity

Every application is classified as one of:

- Debian stable arm64 package.
- Trixie Backports arm64 package.
- Signed vendor arm64 package or repository.
- Omarchy-built arm64 package.
- Web application replacement.
- Unsupported on arm64.

Required packages may not depend on an amd64-only artifact. Optional installers check architecture before changing the system and explain the available alternative. The completed installer prints an application parity report instead of failing because an optional proprietary application is unavailable.

## Test strategy

### Static and shell tests

- Platform and architecture normalization with fixture files.
- Package-map resolution, including one-to-many mappings and unsupported packages.
- Pacman behavior remains unchanged when the platform is Arch.
- APT command construction uses resolved Debian package names and explicit backports selection.
- The bootstrap's validation and phase resumption run against stubbed system commands.
- Platform-incompatible migrations are skipped and marked complete.
- Arch-only system paths are never installed by the Debian setup.

### Packaging tests

- Build both Debian binary packages on amd64 and arm64.
- Install, upgrade, and remove them in clean Debian 13 virtual machines.
- Verify that every installed `/usr` and `/etc` path is owned by a package or intentionally generated by a package maintainer script.

### Graphical acceptance

A disposable Debian arm64 VM or native ARM test machine must verify:

- SDDM starts the Omarchy session.
- Hyprland, UWSM, Quickshell, and portals start without failed user units.
- Bar, menus, lock screen, notifications, clipboard, screenshots, and screen sharing work.
- Network, Bluetooth, audio, suspend/resume, display hotplug, and Chromium work.
- A second installer run is a no-op and a normal update preserves the session.

At least one release candidate must be tested on real ARM graphics hardware; QEMU without accelerated graphics is insufficient visual verification.

## Rollout

### Current repository status

The platform helpers, Debian package resolver and manifests, source bootstrap, common desktop asset installation, Debian system setup, APT update path, migration filtering, and focused shell tests are implemented in this repository. This is the development milestone described by phases 1 and 2 plus the source-based portion of phase 3.

The source bootstrap is ready for testing on a disposable Debian 13 arm64 installation. It is not yet a production release: native Debian packages, a signed APT repository, arm64 builds of Omarchy-specific applications, and graphical acceptance on real ARM hardware remain required. The unsupported manifest makes those application gaps explicit instead of allowing APT to fail halfway through an optional installer.

### Phase 1: platform foundation

- Platform and architecture helpers.
- Debian package map and base package lists.
- Debian implementations of the package helpers.
- Tests protecting the existing Arch behavior.

### Phase 2: installable core desktop

- Debian system setup leaves.
- Development bootstrap using the source checkout.
- Hyprland, Quickshell, UWSM, SDDM, portals, PipeWire, NetworkManager, and core user configuration.

### Phase 3: production packaging and updates

- `omarchy` and `omarchy-settings` Debian packages.
- Signed release artifacts and APT repository.
- Debian update, availability, cache, orphan, and migration behavior.

### Phase 4: application and hardware parity

- arm64 builds for required Omarchy applications.
- Vendor repositories and web alternatives for optional applications.
- Named ARM hardware profiles and real-device acceptance coverage.

### Phase 5: deferred operating-system features

- Optional Btrfs/Snapper setup.
- Debian-native hibernation.
- A separate decision on bootloader snapshot restoration and factory reset.

## First-release acceptance criteria

A fresh Debian 13 arm64 user can run the documented bootstrap, reboot, and reach a working Omarchy session. Running the bootstrap again is safe. `omarchy update` uses APT and runs only compatible migrations. All required desktop components have arm64 packages. Optional unavailable applications are reported clearly. No Debian install path writes Pacman, mkinitcpio, or Limine configuration, and no bootloader or partition is changed.
