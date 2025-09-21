{
  description = "KooL's NixOS-Hyprland";

  inputs = {
    #nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    #hyprland.url = "github:hyprwm/Hyprland"; # hyprland development
    #distro-grub-themes.url = "github:AdisonCavani/distro-grub-themes";

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
            # inputs.distro-grub-themes.nixosModules.${system}.default
            ./modules/quickshell.nix # quickshell module
            ./modules/packages.nix # Software packages
            ./modules/fonts.nix # Fonts packages
            ./modules/portals.nix # portal
            ./modules/theme.nix # Set dark theme

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
                  ./modules/home/tmux.nix
                  ./modules/home/kitty.nix
                  ./modules/home/wezterm.nix
                  ./modules/home/evil-helix.nix
                ];

                # Leave zsh in NixOS; HM will manage user-level tools progressively
              };
            }
          ];
        };
      };
    };
}
