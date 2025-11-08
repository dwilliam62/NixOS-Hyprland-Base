{ lib, ... }:
{
  # 1. Main Git Configuration
  programs.git = {
    enable = true;

    # userEmail and userName comments remain...

    settings = {
      push.default = "simple"; # Match modern push behavior
      credential.helper = "cache --timeout=7200";
      init.defaultBranch = "main"; # Set default new branches to 'main'
      log.decorate = "full"; # Show branch/tag info in git log
      log.date = "iso"; # ISO 8601 date format
      # Conflict resolution style for readable diffs
      merge.conflictStyle = "diff3";
      core.editor = "nvim";
      diff.colorMoved = "default";
      merge.stat = "true";
      core.whitespace = "fix,-indent-with-non-tab,trailing-space,cr-at-eol";
      alias = {
        br = "branch --sort=-committerdate";
        co = "checkout";
        af = "!git add $(git ls-files -m -o --exclude-standard | fzf -m)";
        com = "commit -a";
        ca = "commit -a";
        df = "diff";
        gs = "stash";
        gp = "pull";
        st = "status";
        lg = "log --graph --pretty=format:'%Cred%h%Creset - %C(yellow)%d%Creset %s %C(green)(%cr)%C(bold blue) <%an>%Creset' --abbrev-commit";
        edit-unmerged = "!f() { git ls-files --unmerged | cut -f2 | sort -u ; }; hx `f`";
      };
    };
    # The old `aliases` block is now inside `settings = { alias = { ... }; };`
  };

  # 2. Delta Configuration (moved from `programs.git.delta`)
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;
      true-color = "never";

      # Combine Catppuccin delta theme with our local feature set
      features = lib.mkForce "catppuccin-mocha unobtrusive-line-numbers decorations";
      unobtrusive-line-numbers = {
        line-numbers = true;
        line-numbers-left-format = "{nm:>4}│";
        line-numbers-right-format = "{np:>4}│";
        line-numbers-left-style = "grey";
        line-numbers-right-style = "grey";
      };
      decorations = {
        commit-decoration-style = "bold grey box ul";
        file-style = "bold blue";
        file-decoration-style = "ul";
        hunk-header-decoration-style = "box";
      };
    };
  };
}
