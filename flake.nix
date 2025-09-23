{
  description = "KooL's NixOS-Hyprland";

  inputs = {
    #nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hyprland.url = "github:hyprwm/Hyprland"; # hyprland development
    # Home Manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    ghostty = {
      type = "github";
      owner = "ghostty-org";
      repo = "ghostty";
    };

    ags = {
      type = "github";
      owner = "aylur";
      repo = "ags";
      ref = "v1";
    };

    wfetch = {
      type = "github";
      owner = "iynaix";
      repo = "wfetch";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Current Warp Terminal - bleeding edge version
    warp-terminal = {
      url = "github:dwilliam62/war-terminal/dev";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix User Repository (NUR)
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      ags,
      ...
    }:
    let
      system = "x86_64-linux";
      host = "ddubs-merge";
      username = "dwilliams";

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
    in
    {
      nixosConfigurations = {
        "${host}" = nixpkgs.lib.nixosSystem rec {
          specialArgs = {
            inherit system;
            inherit inputs;
            inherit username;
            inherit host;
          };
          modules = [
            ./hosts/${host}/config.nix
            ./modules/quickshell.nix # quickshell module
            ./modules/packages.nix # Software packages
            ./modules/fonts.nix # Fonts packages
            ./modules/portals.nix # portal
            ./modules/theme.nix # Set dark theme
            ./modules/ly.nix # Centralized ly display manager config
            ./modules/overlays.nix # Overlay exposing warp-bld wrapper
            inputs.catppuccin.nixosModules.catppuccin

            # Integrate Home Manager as a NixOS module
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.users.${username} = {
                home.username = username;
                home.homeDirectory = "/home/${username}";
                home.stateVersion = "24.05";

                # Import your copied HM modules
                imports = [
                  inputs.catppuccin.homeModules.catppuccin

                  ./modules/home/terminals/tmux.nix
                  ./modules/home/terminals/kitty.nix
                  ./modules/home/terminals/remmina.nix
                  ./modules/home/terminals/wezterm.nix
                  ./modules/home/yazi/yazi-import.nix
                  ./modules/home/editors/doom-emacs-install.nix
                  ./modules/home/editors/doom-emacs.nix
                  ./modules/home/editors/evil-helix.nix
                  ./modules/home/cli/bat.nix
                  ./modules/home/cli/btop.nix
                  ./modules/home/cli/bottom.nix
                  ./modules/home/cli/cava.nix
                  ./modules/home/cli/git.nix
                  ./modules/home/cli/htop.nix
                  ./modules/home/cli/lazygit.nix
                  ./modules/home/cli/tealdeer.nix
                  ./modules/home/fastfetch/fastfetch-import.nix
                  ./modules/home/shells/eza.nix
                  ./modules/home/shells/fish.nix
                  ./modules/home/shells/zoxide.nix
                ];

                # Leave zsh in NixOS; HM will manage user-level tools progressively
              };
            }
          ];
        };
      };
    };
}
