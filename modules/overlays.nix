{ inputs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      # Expose Warp Terminal (current/bleeding-edge) via overlay so it inherits nixpkgs config (allowUnfree)
      warp-terminal-current = final.callPackage "${inputs.warp-terminal}/warp/package.nix" {
        waylandSupport = true;
      };

      # Create a wrapper binary (warp-bld) that selects Wayland/X11 at runtime and installs a desktop entry
      warp-bld = final.runCommand "warp-bld" {
        buildInputs = [ final.makeWrapper ];
        meta = final.warp-terminal-current.meta // {
          description = "Warp Terminal (bleeding-edge wrapper)";
        };
      } ''
        mkdir -p $out/bin
        
        # Wrapper with backend detection and env setup
        makeWrapper ${final.warp-terminal-current}/bin/warp-terminal $out/bin/warp-bld \
          --run 'if [[ "$XDG_SESSION_TYPE" == "wayland" ]] && [[ "$WARP_ENABLE_WAYLAND" != "0" ]]; then export WARP_ENABLE_WAYLAND=1; unset WINIT_UNIX_BACKEND; unset GDK_BACKEND; else export WINIT_UNIX_BACKEND=x11; export GDK_BACKEND=x11; export WARP_ENABLE_WAYLAND=0; fi'

        # Convenience symlink to the current build binary
        ln -s ${final.warp-terminal-current}/bin/warp-terminal $out/bin/warp-terminal-current

        # Carry over optional assets if present
        if [ -d "${final.warp-terminal-current}/opt" ]; then
          cp -r ${final.warp-terminal-current}/opt $out/
        fi
        if [ -d "${final.warp-terminal-current}/share/icons" ]; then
          mkdir -p $out/share
          cp -r ${final.warp-terminal-current}/share/icons $out/share/
        fi

        # Desktop entry for the bleeding-edge wrapper
        mkdir -p $out/share/applications
        cat > $out/share/applications/dev.warp.Warp-bld.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Warp (Current bld)
GenericName=Terminal Emulator
Comment=Rust-based terminal (current upstream build)
Exec=warp-bld %U
StartupWMClass=dev.warp.Warp
Keywords=shell;prompt;command;commandline;cmd;current;latest;upstream;
Icon=dev.warp.Warp
Categories=System;TerminalEmulator;
Terminal=false
MimeType=x-scheme-handler/warp;
Actions=new-window;

[Desktop Action new-window]
Name=New Window
Exec=warp-bld
EOF
      '';
    })
  ];
}