{ pkgs
, inputs
, host
, ...
}:
{

  programs = {
    hyprland = {
      enable = true;
      withUWSM = false;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland; # hyprland from source
      portalPackage =
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland; # xdph from source
      xwayland.enable = true;
    };
    zsh.enable = true;
    firefox.enable = false;
    waybar.enable = false; # disable systemd user autostart; Hyprland will start Waybar
    hyprlock.enable = true;
    dconf.enable = true;
    seahorse.enable = true;
    fuse.userAllowOther = true;
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    git.enable = true;
    tmux.enable = true;
    nm-applet.indicator = true;
    neovim = {
      enable = false;
      defaultEditor = false;
    };

    thunar.enable = true;
    thunar.plugins = with pkgs.xfce; [
      exo
      mousepad
      thunar-archive-plugin
      thunar-volman
      tumbler
    ];

  };
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    waybar

    # Update flkake script
    (pkgs.writeShellScriptBin "update" ''
      cd ~/NixOS-Hyprland
      nh os switch -u -H ${host} .
    '')

    # Rebuild flkake script
    (pkgs.writeShellScriptBin "rebuild" ''
      cd ~/NixOS-Hyprland
      nh os switch -H ${host} .
    '')

    # clean up old generations
    (writeShellScriptBin "ncg" ''
      nix-collect-garbage --delete-old && sudo nix-collect-garbage -d && sudo /run/current-system/bin/switch-to-configuration boot
    '')

    # zcli: NixOS management helper
    (pkgs.writeShellScriptBin "zcli" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      PROJECT="NixOS-Hyprland"
      FLAKE_DIR="$HOME/$PROJECT"
      FLAKE_NIX="$FLAKE_DIR/flake.nix"
      HOST="${host}"

      GREP="${pkgs.gnugrep}/bin/grep"
      SED="${pkgs.gnused}/bin/sed"
      INXI="${pkgs.inxi}/bin/inxi"
      FSTRIM="${pkgs.util-linux}/bin/fstrim"
      GIT="${pkgs.git}/bin/git"
      DATE="${pkgs.coreutils}/bin/date"

      print_help() {
        echo "zcli - NixOS management"
        echo ""
        echo "Usage: zcli <command> [options]"
        echo ""
        echo "Commands:"
        echo "  rebuild [opts]       Rebuild and switch (nh os switch)"
        echo "  rebuild-boot [opts]  Build for next boot (nh os boot)"
        echo "  update|upgrade       Flake update + switch"
        echo "  cleanup              Interactive cleanup of old generations"
        echo "  diag                 Write system report to ~/diag.txt"
        echo "  trim                 Run fstrim -v / (sudo)"
        echo "  update-host [host]   Set 'host' in flake.nix"
        echo "  stage [--all]        Stage changes in repo before rebuild"
        echo "  doom <sub>           Manage Doom Emacs (upgrade/status/start/stop/restart/logs)"
        echo ""
        echo "Options (rebuild/update): --dry, --ask, --no-stage, --stage-all"
      }

      confirm() { read -p "Continue (y/N)? " -r; [[ "${REPLY:-}" =~ ^[Yy]$ ]]; }

      stage_changes() {
        local mode="${1:-}"
        if [[ "$mode" == "--no-stage" ]]; then return 0; fi
        if [[ "$mode" == "--stage-all" ]]; then
          (cd "$FLAKE_DIR" && "$GIT" add -A && "$GIT" status --short)
          return 0
        fi
        read -p "Stage all untracked/unstaged changes in $FLAKE_DIR before proceeding? (y/N) " -r
        if [[ "${REPLY:-}" =~ ^[Yy]$ ]]; then
          (cd "$FLAKE_DIR" && "$GIT" add -A && "$GIT" status --short)
        fi
      }

      run_rebuild() {
        local mode="$1"; shift || true
        local dry=0 ask=0 stage_flag=""
        while [[ $# -gt 0 ]]; do
          case "$1" in
            -n|--dry) dry=1 ;;
            -a|--ask) ask=1 ;;
            --no-stage) stage_flag="--no-stage" ;;
            --stage-all) stage_flag="--stage-all" ;;
            --cores|*-j|--no-nom|-v|--verbose) shift; continue ;; # ignored
          esac
          shift || true
        done
        stage_changes "$stage_flag"
        local cmd=(nh os switch -H "$HOST" .)
        if [[ "$mode" == "boot" ]]; then cmd=(nh os boot -H "$HOST" .); fi
        if [[ "$mode" == "update" ]]; then cmd=(nh os switch -u -H "$HOST" .); fi
        if (( dry )); then echo "(dry-run) in $FLAKE_DIR: ${cmd[*]}"; exit 0; fi
        if (( ask )); then confirm || { echo "Aborted."; exit 1; }; fi
        (cd "$FLAKE_DIR" && "${cmd[@]}")
      }

      case "${1:-help}" in
        help|-h|--help)
          print_help ;;

        rebuild)
          shift || true; run_rebuild switch "$@" ;;

        rebuild-boot)
          shift || true; run_rebuild boot "$@" ;;

        update|upgrade)
          shift || true; run_rebuild update "$@" ;;

        cleanup)
          echo "Warning! This will remove old generations."
          read -p "How many generations to keep (empty = keep all but current)? " keep
          LOG_DIR="$HOME/zcli-cleanup-logs"; mkdir -p "$LOG_DIR"
          LOG_FILE="$LOG_DIR/zcli-cleanup-$($DATE +%F_%H-%M-%S).log"
          if [[ -z "${keep:-}" ]]; then
            read -p "Remove all but current generation. Continue (y/N)? " -r; echo
            if [[ "${REPLY:-}" =~ ^[Yy]$ ]]; then nh clean all -v | tee -a "$LOG_FILE"; else echo "Cancelled."; fi
          else
            read -p "Keep last $keep generations. Continue (y/N)? " -r; echo
            if [[ "${REPLY:-}" =~ ^[Yy]$ ]]; then nh clean all -k "$keep" -v | tee -a "$LOG_FILE"; else echo "Cancelled."; fi
          fi
          find "$LOG_DIR" -type f -mtime +3 -name "*.log" -delete >/dev/null 2>&1 || true ;;

        diag)
          OUT="$HOME/diag.txt"
          "$INXI" --full --color 0 --filter --no-host > "$OUT" || true
          echo "Wrote $OUT" ;;

        trim)
          sudo "$FSTRIM" -v / ;;

        update-host)
          target="${2-}"
          if [[ -z "$target" ]]; then read -p "Enter hostname to set in flake.nix: " target; fi
          if [[ -z "$target" ]]; then echo "No hostname provided."; exit 1; fi
          if [[ ! -f "$FLAKE_NIX" ]]; then echo "flake.nix not found at $FLAKE_NIX"; exit 1; fi
          if "$SED" -i "s/^[[:space:]]*host[[:space:]]*=[[:space:]]*\\\".*\\\"/      host = \\\"$target\\\"/" "$FLAKE_NIX"; then
            echo "Updated host to $target in $FLAKE_NIX"
          else
            echo "Failed to update host in $FLAKE_NIX"; exit 1
          fi ;;

        stage)
          shift || true
          if [[ "${1-}" == "--all" || "${1-}" == "--stage-all" ]]; then
            (cd "$FLAKE_DIR" && "$GIT" add -A && "$GIT" status)
          else
            stage_changes ""
          fi ;;

        doom)
          sub="${2-status}"
          case "$sub" in
            upgrade)
              if [[ -x "$HOME/.emacs.d/bin/doom" ]]; then
                systemctl --user stop emacs.service || true
                "$HOME/.emacs.d/bin/doom" upgrade
                systemctl --user start emacs.service || true
              else
                echo "Doom not found at ~/.emacs.d/bin/doom"
              fi ;;
            status)
              systemctl --user status --no-pager emacs.service || true ;;
            start) systemctl --user start emacs.service ;;
            stop) systemctl --user stop emacs.service ;;
            restart) systemctl --user restart emacs.service ;;
            logs)
              n="${3-200}"; follow="${4-}"
              if [[ "$follow" == "-f" || "$follow" == "--follow" ]]; then
                journalctl --user -u emacs.service -f
              else
                journalctl --user -u emacs.service -n "$n"
              fi ;;
            *) echo "Usage: zcli doom [upgrade|status|start|stop|restart|logs]"; exit 1 ;;
          esac ;;

        *)
          print_help; exit 1 ;;
      esac
    '')

    # Wfetch Randomizer script
    (pkgs.writeShellScriptBin "wf" ''
      # Wfetch Randomizer
      # Choose between multiple command options randomly
      # Author: Don Williams
      # Revision History
      #==============================================================
      v0.1      5-15-2025        Initial release

      # Generate a random number (0 to 4)
      choice=$((RANDOM % 5))

      # Execute one of the five commands based on the random number
      case "$choice" in
          0) wfetch --waifu2 --challenge --challenge-years=3 --image-size 300 ;;
          1) wfetch --waifu --challenge --challenge-years=3 --image-size 300 ;;
          2) wfetch --challenge --challenge-years=3 --hollow ;;
          3) wfetch --challenge --challenge-years=3 --wallpaper ;;
          4) wfetch --challenge --challenge-years=3 --smooth ;;
      esac
    '')

    # Hyprland Stuff
    hypridle
    hyprpolkitagent
    pyprland
    #uwsm
    hyprlang
    hyprshot
    hyprcursor
    mesa
    nwg-displays
    nwg-look
    nwg-menu
    nwg-dock-hyprland
    waypaper
    hyprland-qt-support # for hyprland-qt-support

    #  Apps
    loupe
    appimage-run
    bc
    brightnessctl
    (btop.override {
      cudaSupport = true;
      rocmSupport = true;
    })
    bottom
    baobab
    btrfs-progs
    cmatrix
    dua
    duf
    cava
    cargo
    clang
    cmake
    cliphist
    cpufrequtils
    curl
    dysk
    eog
    eza
    findutils
    figlet
    ffmpeg
    fd
    feh
    file-roller
    glib # for gsettings to work
    gsettings-qt
    git
    google-chrome
    gnome-system-monitor
    fastfetch
    jq
    gcc
    git
    gnumake
    grim
    grimblast
    gtk-engine-murrine # for gtk themes
    inxi
    imagemagick
    killall
    kdePackages.qt6ct
    kdePackages.qtwayland
    kdePackages.qtstyleplugin-kvantum # kvantum
    lazydocker
    libappindicator
    libnotify
    libsForQt5.qtstyleplugin-kvantum # kvantum
    libsForQt5.qt5ct
    (mpv.override { scripts = [ mpvScripts.mpris ]; }) # with tray
    nvtopPackages.full
    openssl # required by Rainbow borders
    pciutils
    networkmanagerapplet
    nitrogen
    pamixer
    pavucontrol
    playerctl
    #polkit
    # polkit_gnome
    kdePackages.polkit-kde-agent-1
    qt6ct
    qt6.qtwayland
    qt6Packages.qtstyleplugin-kvantum # kvantum
    gsettings-qt
    rofi
    slurp
    swappy
    swaynotificationcenter
    swww
    unzip
    wallust
    wdisplays
    wl-clipboard
    wlr-randr
    wlogout
    wget
    xarchiver
    yad
    yazi
    yt-dlp
    zellij

    (inputs.quickshell.packages.${pkgs.system}.default)
    (inputs.ags.packages.${pkgs.system}.default)
    (inputs.ghostty.packages.${pkgs.system}.default)
    (inputs.wfetch.packages.${pkgs.system}.default)

    # Utils
    caligula # burn ISOs at cli FAST
    atop
    gdu
    glances
    gping
    htop
    hyfetch
    ipfetch
    lolcat
    lsd
    oh-my-posh
    pfetch
    ncdu
    ncftp
    ripgrep
    socat
    starship
    tldr
    ugrep
    unrar
    v4l-utils
    obs-studio
    zoxide

    # Hardware related
    cpufetch
    cpuid
    cpu-x
    #gsmartcontrol
    smartmontools
    light
    lm_sensors
    mission-center
    neofetch

    # AI
    warp-terminal
    warp-bld
    gemini-cli
    #opencode

    # Development related
    luarocks
    nh
    lunarvim
    nixd

    # Internet
    discord
    discord-canary

    # Virtuaizaiton
    virt-viewer
    libvirt

    # Video
    vlc
    #jellyfin-media-player   #Causes failed builds

    # Terminals
    kitty
    wezterm
    ptyxis
    remmina

  ];

  environment.variables = {
    NIXOS_OZONE_WL = "1";
    DDUBSOS_VERSION = "JAK-v0.4";
    DDUBSOS = "true";
  };
}
