{inputs, ...}: {
  nixpkgs.overlays = [
    (final: prev: rec {
      # Expose Warp Terminal (current/bleeding-edge) via overlay so it inherits nixpkgs config (allowUnfree)
      warp-terminal-current = final.callPackage "${inputs.warp-terminal}/warp/package.nix" {
        waylandSupport = true;
      };

      # Create a wrapper binary (warp-bld) that selects Wayland/X11 at runtime and installs a desktop entry
      warp-bld =
        final.runCommand "warp-bld" {
          buildInputs = [final.makeWrapper];
          meta =
            final.warp-terminal-current.meta
            // {
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
      # Allow argtable to configure with newer CMake by declaring policy minimum
      argtable = prev.argtable.overrideAttrs (old: {
        cmakeFlags =
          (old.cmakeFlags or [])
          ++ [
            "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
          ];
      });

      # Patch ANTLR C++ runtime: add policy flag and bump minimum + force NEW policies
      antlr4_9 =
        prev.antlr4_9
        // {
          runtime =
            prev.antlr4_9.runtime
            // {
              cpp = prev.antlr4_9.runtime.cpp.overrideAttrs (old: {
                cmakeFlags =
                  (old.cmakeFlags or [])
                  ++ [
                    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
                  ];
                postPatch =
                  (old.postPatch or "")
                  + ''
                    if [ -f runtime/Cpp/runtime/CMakeLists.txt ]; then
                      sed -i -E 's/cmake_minimum_required\(VERSION [0-9.]+\)/cmake_minimum_required(VERSION 3.5)/' runtime/Cpp/runtime/CMakeLists.txt
                      sed -i -E 's/(cmake_policy\(SET CMP[0-9]+ )OLD/\1NEW/g' runtime/Cpp/runtime/CMakeLists.txt || true
                      sed -i -E 's/(CMAKE_POLICY\(SET CMP[0-9]+ )OLD/\1NEW/g' runtime/Cpp/runtime/CMakeLists.txt || true
                    fi
                    if [ -f runtime/Cpp/CMakeLists.txt ]; then
                      sed -i -E 's/cmake_minimum_required\(VERSION [0-9.]+\)/cmake_minimum_required(VERSION 3.5)/' runtime/Cpp/CMakeLists.txt
                      sed -i -E 's/(cmake_policy\(SET CMP[0-9]+ )OLD/\1NEW/g' runtime/Cpp/CMakeLists.txt || true
                      sed -i -E 's/(CMAKE_POLICY\(SET CMP[0-9]+ )OLD/\1NEW/g' runtime/Cpp/CMakeLists.txt || true
                    fi
                  '';
              });
            };
        };

      # Fix libvdpau-va-gl CMake minimum for modern CMake
      libvdpau-va-gl = prev.libvdpau-va-gl.overrideAttrs (old: {
        cmakeFlags =
          (old.cmakeFlags or [])
          ++ [
            "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
          ];
        postPatch =
          (old.postPatch or "")
          + ''
            if [ -f CMakeLists.txt ]; then
              sed -i -E 's/cmake_minimum_required\(VERSION [0-9.]+\)/cmake_minimum_required(VERSION 3.5)/' CMakeLists.txt || true
            fi
          '';
      });

      # Provide a clean cxxopts pkg-config shim and force pamixer to use it
      cxxoptsPcShim = final.runCommand "cxxopts-pc-shim" {} ''
                mkdir -p $out/lib/pkgconfig
                cat > $out/lib/pkgconfig/cxxopts.pc <<'EOF'
        Name: cxxopts
        Description: C++ command line parser headers
        Version: ${final.cxxopts.version}
        Cflags: -I${final.cxxopts}/include
        Libs:
        Requires:
        EOF
      '';

      pamixer = prev.pamixer.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or []) ++ [final."pkg-config" cxxoptsPcShim];
        preConfigure =
          (old.preConfigure or "")
          + ''
            export PKG_CONFIG_PATH=${cxxoptsPcShim}/lib/pkgconfig:"$PKG_CONFIG_PATH"
          '';
      });
    })
  ];
}
