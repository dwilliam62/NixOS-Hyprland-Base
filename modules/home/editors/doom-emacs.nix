{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    emacs-pgtk
    git
    lazygit
    ripgrep
    libtool
    cmake
    pkg-config
    # Spell checking
    hunspell
    hunspellDicts.en_US
    hunspellDicts.en_AU
    hunspellDicts.es_ES
    # Nix tooling
    nixfmt-rfc-style
    # LSP servers
    clang-tools # C/C++ LSP
    nixd # Nix LSP

    # TTY wrapper: prefer truecolor by using xterm-direct / tmux-direct when available
    (writeShellScriptBin "et" ''
      #!/usr/bin/env bash
      set -euo pipefail
      # Ensure we hint truecolor
      export COLORTERM="truecolor"

      # Prefer direct-color terminfo when available
      choose_term() {
        local t="$1"
        if command -v infocmp >/dev/null 2>&1 && infocmp "$t" >/dev/null 2>&1; then
          echo "$t"
          return 0
        fi
        return 1
      }

      if [ -n "''${TMUX-}" ]; then
        if choose_term tmux-direct >/dev/null; then
          export TERM=tmux-direct
        fi
      else
        if choose_term xterm-direct >/dev/null; then
          export TERM=xterm-direct
        fi
      fi

      exec emacsclient -t -a "" "$@"
    '')

    # Doom updater script (replacement for zcli-based updates)
    (writeShellScriptBin "doom-update" ''
      #!/usr/bin/env bash
      set -euo pipefail
      EMACSDIR="$HOME/.emacs.d"
      if [ ! -x "$EMACSDIR/bin/doom" ]; then
        echo "doom-update: doom binary not found at $EMACSDIR/bin/doom"
        echo "Run 'get-doom' first to install Doom Emacs."
        exit 1
      fi

      # Update Doom repo non-interactively, then sync packages
      if command -v git >/dev/null 2>&1; then
        git -C "$EMACSDIR" fetch --all -p || true
        git -C "$EMACSDIR" pull --ff-only || true
      fi
      "$EMACSDIR/bin/doom" sync -u || true
      echo "doom-update: complete"
    '')
  ];

  # Run Emacs as a user daemon and set emacsclient as default editor
  services.emacs = {
    enable = true;
    defaultEditor = false; # nixvim is the default editor; avoid EDITOR conflicts
    package = pkgs.emacs-pgtk;
  };

  # Ensure Doom Emacs is installed and synchronized on each Home Manager activation
  home.activation.doomSync = lib.hm.dag.entryAfter ["writeBoundary"] ''
    set -eu
    EMACSDIR="$HOME/.emacs.d"
    if [ ! -x "$EMACSDIR/bin/doom" ]; then
      if [ -d "$EMACSDIR" ] && [ -n "$(ls -A "$EMACSDIR" 2>/dev/null || true)" ]; then
        echo "Doom bootstrap: Found non-empty $EMACSDIR without doom; skipping clone."
      else
        echo "Doom bootstrap: Cloning Doom Emacs into $EMACSDIR ..."
        ${pkgs.git}/bin/git clone --depth 1 https://github.com/doomemacs/doomemacs "$EMACSDIR" || echo "Doom bootstrap: git clone failed (offline?); will retry next activation."
      fi
    fi

    if [ -x "$EMACSDIR/bin/doom" ]; then
      echo "Doom: syncing packages (doom sync -u) ..."
      "$EMACSDIR/bin/doom" sync -u || echo "Doom: sync failed; try running manually after networking is available."
    fi
  '';

  home.file.".doom.d/init.el".text = ''
    ;;; init.el -*- lexical-binding: t; -*-

    (doom!
     :completion
     (company +auto)
     (vertico +icons)

     :ui
     doom
     doom-dashboard
     doom-quit
     hl-todo
     modeline
     nav-flash
     ophints
     (popup +defaults)
     (ligatures +extra)
     smooth-scroll
     tabs
     treemacs
     vi-tilde-fringe
     window-select

     :editor
     (evil +everywhere)
     file-templates
     fold
     multiple-cursors
     snippets
     word-wrap

     :emacs
     (dired +icons)
     electric
     (ibuffer +icons)
     (undo +tree)
     vc

     :term
     vterm

     :checkers
     (syntax +flymake)
     (spell +flyspell)
     grammar

     :tools
     (eval +overlay)
     (lookup +docsets)
     lsp
     (magit +forge)
     pdf
     tree-sitter

     :lang
     bash
     (c +lsp)
     css
     docker
     html
     (json +lsp)
     markdown
     (nix +tree-sitter +lsp)
     toml
     yaml

     :config
     (default +bindings +smartparens))
  '';

  home.file.".doom.d/config.el".text = ''
    ;;; config.el -*- lexical-binding: t; -*-

    (setq doom-theme 'doom-one)
    (setq display-line-numbers-type 'relative)
    (setq nerd-icons-font-family "JetBrainsMono Nerd Font")

    (defun my/apply-tty-theme (&optional frame)
      (let ((frame (or frame (selected-frame))))
        (when (not (display-graphic-p frame))
          (with-selected-frame frame
            (setenv "COLORTERM" "truecolor")
            (modify-frame-parameters frame '((background-mode . dark)))
            (load-theme doom-theme t)
            (set-face-attribute 'default frame :background "#0a0a0a" :foreground "#c8c8c8")
            (set-face-attribute 'bold    frame :weight 'normal)))))

    (add-hook 'tty-setup-hook #'my/apply-tty-theme)
    (add-hook 'after-make-frame-functions #'my/apply-tty-theme)

    (after! magit
      (setq with-editor-emacsclient-executable "emacsclient")
      (setq magit-diff-refine-hunk t)
      (setq magit-refresh-status-buffer t))

    (defun my/lazygit ()
      "Open lazygit in a terminal."
      (interactive)
      (if (fboundp 'vterm)
          (let ((default-directory (magit-toplevel)))
            (vterm "*lazygit*")
            (vterm-send-string "lazygit")
            (vterm-send-return))
        (async-shell-command "lazygit" "*lazygit*")))

    (after! lsp-mode
      (setq lsp-signature-auto-activate t
            lsp-signature-render-documentation t
            lsp-completion-provider :company-capf
            lsp-idle-delay 0.1)
      ;; Prefer nixd over nil
      (add-to-list 'lsp-disabled-clients 'nil))

    (after! company
      (setq company-idle-delay 0.2
            company-minimum-prefix-length 1
            company-tooltip-align-annotations t
            company-require-match 'never))

    (after! ispell
      (setq ispell-program-name "hunspell")
      (setq ispell-local-dictionary "en_US")
      (setq ispell-local-dictionary-alist
            '(("en_US" "[[:alpha:]]" "[^[:alpha:]]" "[']" nil ("-d" "en_US") nil utf-8))))

    (map! :leader
          (:prefix-map ("g" . "git")
           :desc "Magit status" "g" #'magit-status
           :desc "Magit dispatch" "d" #'magit-dispatch
           :desc "Magit file dispatch" "f" #'magit-file-dispatch
           :desc "Magit blame" "b" #'magit-blame-addition
           :desc "Git time machine" "t" #'git-timemachine-toggle
           :desc "Lazygit" "l" #'my/lazygit
           :desc "Git stage file" "s" #'magit-stage-file
           :desc "Git unstage file" "u" #'magit-unstage-file))

    (after! nix-mode
      (setq nix-nixfmt-bin "nixfmt")
      (map! :leader
            (:prefix ("m" . "major mode")
             :desc "Nix: format buffer" "f" #'nix-format-buffer)))

    (with-eval-after-load 'nix
      (map! :leader
            (:prefix ("m" . "major mode")
             :desc "Nix: build"         "b" #'nix-build
             :desc "Nix: shell"         "s" #'nix-shell
             :desc "Nix: unpack"        "u" #'nix-unpack
             :desc "Nix: REPL show"     "r" #'nix-repl-show)))

    (with-eval-after-load 'nix-update
      (map! :leader
            (:prefix ("m" . "major mode")
             :desc "Nix: update fetch"  "U" #'nix-update-fetch)))

    (when (fboundp '+nix/lookup-option)
      (map! :leader
            (:prefix ("m" . "major mode")
             :desc "Nix: lookup option" "o" #'+nix/lookup-option)))
  '';

  # Put doom's bin on PATH for convenience
  home.sessionPath = ["$HOME/.emacs.d/bin"];

  # Ensure truecolor is advertised to Emacs (improves TTY theme fidelity)
  home.sessionVariables = {COLORTERM = "truecolor";};

  home.file.".doom.d/packages.el".text = ''
    ;;; packages.el -*- lexical-binding: t; -*-

    (package! git-timemachine)

    (package! nix-update)

    (package! nixos-options)
  '';
}
