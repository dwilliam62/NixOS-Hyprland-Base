{ pkgs }:
pkgs.writeTextFile {
  name = "ff1";
  executable = true;
  destination = "/bin/ff1";
  text = ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    cfg="$HOME/.config/fastfetch/fastfetch1.config.jsonc"

    parent_pid=$PPID
    parent_name=""
    if [[ -r "/proc/$parent_pid/comm" ]]; then
      parent_name="$(tr -d '\0' < "/proc/$parent_pid/comm")"
    else
      parent_name="$(ps -o comm= -p "$parent_pid" 2>/dev/null || true)"
    fi
    if [[ -z "$parent_name" && -n "${SHELL:-}" ]]; then
      parent_name="$(basename -- "$SHELL")"
    fi

    case "$parent_name" in
      *zsh*) shell="${pkgs.zsh}/bin/zsh" ;;
      *bash*) shell="${pkgs.bash}/bin/bash" ;;
      *fish*) shell="${pkgs.fish}/bin/fish" ;;
      *) shell="$(command -v "$parent_name" 2>/dev/null || true)" ;;
    esac

    if [[ -z "${shell:-}" ]]; then
      shell="${pkgs.zsh}/bin/zsh"
    fi

    exec "$shell" -c "fastfetch -c \"$cfg\""
  '';
}
