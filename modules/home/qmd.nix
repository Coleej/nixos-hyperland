{...}: {
  # qmd (github:tobi/qmd) - on-device search engine for markdown notes.
  # Package comes from qmd's own homeModules.default (imported in flake.nix).
  # CLI binary only, on every host (including wsl) for ad-hoc `qmd query`/`qmd
  # status` use. The MCP HTTP server + reindex timer live in qmd-server.nix,
  # imported only where the host should actually run one (see that file for
  # why wsl doesn't: it points at a GPU-accelerated server on the Windows
  # host instead of running its own CPU-only one).
  programs.qmd.enable = true;
}
