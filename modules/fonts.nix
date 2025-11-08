{ pkgs, ... }:
{
  fonts = {
    packages = with pkgs; [
      dejavu_fonts
      fira-code
      fira-code-symbols
      fira-sans
      font-awesome
      hackgen-nf-font
      ibm-plex
      inter
      jetbrains-mono
      material-icons
      maple-mono.NF
      minecraftia
      noto-fonts
      nerd-fonts.blex-mono
      nerd-fonts.caskaydia-cove
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      nerd-fonts.im-writing
      lilex
      nerd-fonts.lilex
      noto-fonts-monochrome-emoji
      powerline-fonts
      roboto
      roboto-mono
      symbola
      terminus_font
      nerd-fonts.jetbrains-mono
      victor-mono
    ];
  };
}
