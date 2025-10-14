# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

Project overview
- Purpose: NixOS flake to provision a Hyprland-based desktop with optional GPU profiles, theming, and convenience tooling. Installs packages and pulls Hyprland dotfiles from an external repo during install; this repo itself does not contain Hyprland dotfiles.
- Key technologies: Nix flakes, NixOS modules, Hyprland, wayland tooling, optional quickshell and ags.

Common commands
- Pick or create a host
  - Duplicate the default host and generate hardware config:
    - cp -r hosts/default hosts/<host>
    - sudo nixos-generate-config --show-hardware-config > hosts/<host>/hardware.nix
  - Option A: Use the interactive installer to set host/username and GPU profile: ./install.sh
  - Option B: Edit flake.nix directly (host and username) and toggle drivers in hosts/<host>/config.nix

- Build and switch the system
  - Switch to the flake config for a given host (run from repo root with flakes enabled):
    - sudo nixos-rebuild switch --flake .#<host>
  - Build without switching (for validation):
    - sudo nixos-rebuild build --flake .#<host>
    - or: nix build .#nixosConfigurations.<host>.config.system.build.toplevel

- Flake operations
  - Show outputs: nix flake show
  - Update inputs: nix flake update

- Convenience wrappers (installed by modules/packages.nix after first build)
  - frebuild: nh os switch -H <host> . (from ~/NixOS-Hyprland)
  - fupdate: nh os switch -u -H <host> . (updates flake inputs and switches)
  - ncg: cleans old generations and prepares for next boot

High-level architecture
- Flake entry (flake.nix)
  - inputs: nixpkgs (currently nixos-unstable), ags (v1), quickshell. Optional commented inputs for hyprland and distro-grub-themes.
  - outputs.nixosConfigurations: one configuration keyed by the host variable defined at the top of flake.nix. Special args (system, inputs, username, host) are passed into modules.
  - Module stack assembled here:
    - ./hosts/${host}/config.nix (per-host system configuration)
    - ./modules/quickshell.nix, ./modules/packages.nix, ./modules/fonts.nix, ./modules/portals.nix, ./modules/theme.nix

- Per-host configuration (hosts/<host>/*.nix)
  - config.nix imports: hardware.nix, users.nix, packages-fonts.nix, plus togglable hardware/service modules (amd/intel/nvidia/nvidia-prime, vm guest services, local-hardware-clock).
  - variables.nix provides editable knobs (keyboardLayout, default apps, waybar/monitor options, git identity used by external installers).
  - config.nix also sets core system settings: bootloader, kernel, networking, locales, services (greetd with Hyprland via tuigreet, pipewire, bluetooth, flatpak, etc.), nix settings (flakes enabled, hyprland cachix), and system.stateVersion.
  - GPU/VM toggles are expressed as booleans under drivers.* and vm.guest-services.enable and are expected to be flipped per host.

- Shared modules (modules/*.nix)
  - packages.nix: Enables core programs (hyprland, waybar, hyprlock, firefox, zsh, thunar, etc.), and defines convenience scripts:
    - frebuild, fupdate (nh wrappers binding to the current host)
    - ncg (garbage collection + switch-to-configuration boot)
    - Adds a broad set of systemPackages for Hyprland + Wayland workflows and utilities.
  - theme.nix: Installs common themes/cursors; sets GNOME dconf defaults for dark theme and cursor; exports minimal env and session variables (GTK2 rc, QT platform theme, XCURSOR_*); runs dconf update on activation.
  - Other modules: drivers (amd/intel/nvidia/nvidia-prime), portals, fonts, vm-guest-services, local-hardware-clock; these are pulled into each host config and toggled via the host config.

- Install entrypoints and helpers
  - ./install.sh and ./auto-install.sh: interactive flows that (a) verify NixOS context and prerequisites, (b) set host/username in flake.nix, (c) detect GPU or VM and toggle per-host booleans, (d) generate hosts/<host>/hardware.nix, and (e) trigger a system rebuild. They also optionally fetch GTK themes/icons and clone external Hyprland-Dots into ~/Hyprland-Dots and copy assets.
  - scripts/lib/install-common.sh: helper functions used by installers:
    - nhl_detect_gpu_and_toggle(host): inspects lspci/hostnamectl to select amd/intel/nvidia/nvidia-prime/vm and updates hosts/<host>/config.nix booleans in-place.
    - nhl_prompt_timezone_console(host, defaultKeymap): interactively sets automatic time zone or explicit time.timeZone and console.keyMap in the host config.
  - assets/: seed files for user env (e.g., .zshrc) and configs for gtk-3.0, Thunar, xfce helpers, fastfetch; installers copy these to the user’s home if not present.

Important repo-specific notes
- This repo is focused on NixOS system provisioning. Hyprland dotfiles are fetched at install time from an external repository (Hyprland-Dots) and are not maintained here.
- The flake currently tracks nixos-unstable (flake.nix). If you switch channels (e.g., nixos-25.05), adjust inputs in flake.nix and any host files that pin packages per the README guidance.
- greetd is configured to start Hyprland via tuigreet for the specified username; ensure the username in flake.nix matches your actual user.
- For first-time flake usage on a fresh system, you may need to set NIX_CONFIG="experimental-features = nix-command flakes" in your shell for commands like nixos-rebuild and nix flake update before your system config enables them globally.
