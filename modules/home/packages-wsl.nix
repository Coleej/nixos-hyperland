{pkgs, ...}: {
  # Headless CLI/dev toolchain for the WSL host — no GUI apps.
  # git is provided by git.nix, taskwarrior by taskwarrior.nix.
  home.packages = with pkgs; [
    neovim
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
    uv
    git-lfs
    ranger
    tree-sitter
    dig
    pyright
    lua-language-server
    ruff
    stylua
    nixd
    nixfmt
    tre-command
  ];
}
