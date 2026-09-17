{pkgs, ...}: let
  qmlls = pkgs.runCommand "qmlls" {} ''
    mkdir -p $out/bin
    ln -s ${pkgs.qt6.qtdeclarative}/bin/qmlls $out/bin/qmlls
  '';
in {
  home.packages = with pkgs; [
    neovim
    git
    ripgrep
    fd
    fzf
    eza
    bat
    jq
    wget
    curl
    tree
    htop
    btop
    fastfetch
    direnv
    gh
    cups-pk-helper
    uv
    newsboat
    git-lfs
    ranger
    xclip
    firefox
    tree-sitter
    telegram-desktop
    whosthere
    dig
    remmina
    pyright
    lua-language-server
    qmlls
    ruff
    stylua
    nixd
    nixfmt
    taskwarrior3
    tre-command
    imagemagick
    protonmail-bridge-gui
    obsidian
    sparrow
  ];
}
