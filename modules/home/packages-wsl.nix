{
  pkgs,
  claudeCodePackage,
  ...
}: {
  # Headless CLI/dev toolchain for the WSL host — no GUI apps.
  # git is provided by git.nix, taskwarrior by taskwarrior.nix.
  # claudeCodePackage comes from the claude-code-nix flake input (hourly-updated
  # native binary) rather than nixpkgs, which lags upstream Claude Code releases.
  home.packages = with pkgs;
    [
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
    ]
    ++ [claudeCodePackage];
}
