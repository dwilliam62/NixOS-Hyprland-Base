{ pkgs, ... }:

let
  doom-icon = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/jeetelongname/doom-banners/master/splashes/doom/doom-emacs-color2.svg";
    sha256 = "1xxi5ra1z8njsqaqiaq96wyn1sc967l42kvjzbji1zrjj8za6bgq";
  };
in
{
  # Provide a convenience installer script if Doom isn't present yet
  home.packages = [
    (pkgs.writeShellScriptBin "get-doom" ''
      #!/usr/bin/env bash
      set -e

      ICON_CHECK="✔"
      ICON_INFO="ℹ"
      ICON_ROCKET="🚀"

      print_status() { echo; echo "--- $ICON_INFO $1 ---"; }
      print_success() { echo "--- $ICON_CHECK $1 ---"; }
      print_banner() {
        echo "==============================="
        echo " Doom Emacs Installer $ICON_ROCKET"
        echo "==============================="
      }

      print_banner
      EMACSDIR="$HOME/.emacs.d"

      if [ -d "$EMACSDIR" ]; then
        print_success "Doom Emacs is already installed."
        exit 0
      fi

      print_status "Cloning Doom Emacs..."
      git clone --depth 1 https://github.com/doomemacs/doomemacs "$EMACSDIR"
      print_success "Doom Emacs cloned."

      print_status "Running Doom install..."
      "$EMACSDIR/bin/doom" install
      print_success "Doom install complete."

      print_status "Running doom sync..."
      "$EMACSDIR/bin/doom" sync
      print_success "Doom sync complete."

      echo
      print_success "All done! Doom Emacs is ready to use."
    '')
  ];

  # Add Doom's bin dir to PATH
  home.sessionPath = [ "$HOME/.emacs.d/bin" ];

  # Desktop entry
  xdg.desktopEntries.doom-emacs = {
    name = "Doom Emacs";
    comment = "A configuration framework for GNU Emacs";
    exec = "emacs";
    icon = doom-icon;
    terminal = false;
    type = "Application";
    categories = [ "Development" "TextEditor" ];
  };
}
