{
  programs.fastfetch = {
    enable = true;

    settings = {
      display = {
        color = {
          keys = "35";
          output = "95";
        };
        separator = " ➜  ";
      };

      logo = {
        source = ./nixos.png;
        type = "kitty";
        height = 7;
        width = 16;
        padding = {
          top = 2;
          left = 2;
        };
      };

      modules = [
        "break"
        {
          type = "os";
          key = "OS";
          keyColor = "31";
        }
        {
          type = "command";
          key = " ├  ddubsOS ";
          keyColor = "31";
          text = "echo v$" + "{DDUBSOS_VERSION}";
        }
        {
          type = "kernel";
          key = " ├  ";
          keyColor = "31";
        }
        {
          type = "packages";
          key = " ├ 󰏖 ";
          keyColor = "31";
        }
        {
          type = "shell";
          key = " └  ";
          keyColor = "31";
        }
        "break"
        {
          type = "wm";
          key = "WM   ";
          keyColor = "32";
        }
        {
          type = "wmtheme";
          key = " ├ 󰉼 ";
          keyColor = "32";
        }
        {
          type = "icons";
          key = " ├ 󰀻 ";
          keyColor = "32";
        }
        {
          type = "cursor";
          key = " ├  ";
          keyColor = "32";
        }
        {
          type = "terminal";
          key = " ├  ";
          keyColor = "32";
        }
        {
          type = "terminalfont";
          key = " └  ";
          keyColor = "32";
        }
        "break"
        {
          type = "host";
          format = "{5} {1} Type {2}";
          key = "PC   ";
          keyColor = "33";
        }
        {
          type = "cpu";
          format = "{1} ({3}) @ {7} GHz";
          key = " ├  ";
          keyColor = "33";
        }
        {
          type = "gpu";
          format = "{1} {2} @ {12} GHz";
          key = " ├ 󰢮 ";
          keyColor = "33";
        }
        {
          type = "memory";
          key = " ├  ";
          keyColor = "33";
        }
        {
          type = "disk";
          key = " ├ 󰋊 ";
          keyColor = "33";
        }
        {
          type = "monitor";
          key = " ├  ";
          keyColor = "33";
        }
        {
          type = "player";
          key = " ├ 󰥠 ";
          keyColor = "33";
        }
        {
          type = "media";
          key = " └ 󰝚 ";
          keyColor = "33";
        }
        "break"
        {
          type = "uptime";
          key = "   Uptime   ";
        }
      ];
    };
  };

  home.file = {
    ".config/fastfetch/fastfetch-system-times.config.jsonc" = {
      source = ./fastfetch-system-times.config.jsonc;
    };
  };

  home.file = {
    ".config/fastfetch/fastfetch1.config.jsonc" = {
      source = ./fastfetch1.config.jsonc;
    };
  };

  home.file = {
    ".config/fastfetch/fastfetch2.config.jsonc" = {
      source = ./fastfetch2.config.jsonc;
    };
  };

  home.file = {
    ".config/fastfetch/images" = {
      recursive = true;
      source = ./images;
    };
  };

  home.file = {
    ".config/fastfetch/nixos.png" = {
      source = ./nixos.png;
    };
  };
}
