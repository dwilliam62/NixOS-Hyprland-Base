{ ... }:

{
  imports = [
    ./terminals/tmux.nix
    #./terminals/kitty.nix   # Will set catppuccin theme
    ./terminals/remmina.nix
    #./terminals/wezterm.nix
    ./yazi/yazi-import.nix
    ./editors/doom-emacs-install.nix
    ./editors/doom-emacs.nix
    ./editors/nixvim.nix
    ./editors/evil-helix.nix
    ./cli/bat.nix
    ./cli/btop.nix
    ./cli/bottom.nix
    ./cli/cava.nix
    ./cli/fzf.nix
    ./cli/git.nix
    ./cli/htop.nix
    ./cli/lazygit.nix
    ./cli/tealdeer.nix
    ./fastfetch/fastfetch-import.nix
    ./shells/eza.nix
    ./shells/fish.nix
    ./shells/zoxide.nix
  ];

}

