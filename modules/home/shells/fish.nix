{ profile
, lib
, ...
}: {
  programs.fish = {
    enable = true;
    shellAliases = {
      fr = "nh os switch --hostname ${profile}";
      fu = "nh os switch --hostname ${profile} --update";
      ncg = "nix-collect-garbage --delete-old && sudo nix-collect-garbage -d && sudo /run/current-system/bin/switch-to-configuration boot";
      #zu = "sh <(curl -L https://gitlab.com/Zaney/zaneyos/-/raw/main/install-zaneyos.sh)";
      grep = "ugrep --color=auto";
      fgrep = "ugrep -F --color=auto";
      upd = "source ~/fish-up";
    };
  };

  # Explicitly set Fish config with Dracula colors and 'up' function
  xdg.configFile."fish/config.fish".text = lib.mkForce ''
    PATH="$HOME/.local/bin:$PATH"
    # Enable Vi keybindings
    fish_vi_key_bindings

    # Goes up a specified number of directories. Defaults to 1.
    function up
      set -l count $argv[1]
      if test -z "$count"
        set count 1
      end

      set str ""
      for i in (seq $count)
        set str "../$str"
      end

      cd $str
    end

    # Set Dracula theme colors
    set fish_color_normal 6272a4
    set fish_color_command 50fa7b
    set fish_color_error ff5555
    set fish_color_param f1fa8c
    set fish_color_comment 6272a4
    set fish_color_operator bd93f9
    set fish_color_escape ff79c6
    set fish_color_red ff5555
    set fish_color_green 50fa7b
    set fish_color_yellow f1fa8c
    set fish_color_blue 8be9fd
    set fish_color_purple bd93f9
    set fish_color_cyan 8be9fd
    set fish_color_white f8f8f2
    set -gx EDITOR "nvim"
    set -gx VISUAL "nvim"
  '';

  # Create fish_prompt.fish file
  xdg.configFile."fish/functions/fish_prompt.fish".text = ''
    function fish_prompt
        set -l last_status $status
        set -l normal (set_color normal)
        set -l status_color (set_color brgreen)
        set -l cwd_color (set_color $fish_color_cwd)
        set -l vcs_color (set_color brpurple)
        set -l prompt_status ""

        set -q fish_prompt_pwd_dir_length
        or set -lx fish_prompt_pwd_dir_length 0

        set -l suffix "❯"
        if functions -q fish_is_root_user; and fish_is_root_user
            if set -q fish_color_cwd_root
                set cwd_color (set_color $fish_color_cwd_root)
            end
            set suffix "#"
        end

        if test $last_status -ne 0
            set status_color (set_color $fish_color_error)
            set prompt_status $status_color "[" $last_status "]" $normal
        end

        echo -s (prompt_login) " " $cwd_color (prompt_pwd) $vcs_color (fish_vcs_prompt) $normal " " $prompt_status
        echo -n -s $status_color $suffix " " $normal
    end
  '';
}
