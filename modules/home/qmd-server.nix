{config, ...}: {
  # Runs qmd's own MCP server as a long-lived HTTP daemon (instead of
  # stdio-per-launch) so the embedding/reranking models stay warm across
  # Claude Code sessions. Point Claude Code's mcpServers config at
  # http://localhost:8181/mcp.
  #
  # Imported only on hosts with real GPU access (thinkpad, amd-workstation).
  # wsl is excluded: WSL2 has no real GPU passthrough (node-llama-cpp falls
  # back to slow CPU inference there), so that Claude Code instance instead
  # points at a GPU-accelerated qmd server running natively on the Windows
  # host it runs under (~3x faster on the same RX 6700 XT via native Vulkan,
  # vs. WSL's fake/absent DRM device). See project notes for that setup.
  systemd.user.services.qmd-mcp = {
    Unit.Description = "qmd MCP HTTP server";
    Service = {
      ExecStart = "${config.programs.qmd.package}/bin/qmd mcp --http";
      Restart = "on-failure";
    };
    Install.WantedBy = ["default.target"];
  };

  # qmd has no filesystem watcher of its own; `update` (rescan) and `embed`
  # (vectorize new/changed content) only run when invoked. Poll on a timer
  # instead of a systemd.path watch: Obsidian autosaves constantly and touches
  # nested subfolders that a non-recursive path unit wouldn't see anyway.
  systemd.user.services.qmd-reindex = {
    Unit.Description = "Reindex and embed qmd collections";
    Service = {
      Type = "oneshot";
      ExecStart = [
        "${config.programs.qmd.package}/bin/qmd update"
        "${config.programs.qmd.package}/bin/qmd embed"
      ];
    };
  };

  systemd.user.timers.qmd-reindex = {
    Unit.Description = "Periodic qmd reindex/embed";
    Timer = {
      OnCalendar = "hourly";
      Persistent = true;
    };
    Install.WantedBy = ["timers.target"];
  };
}
