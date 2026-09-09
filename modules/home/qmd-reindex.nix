{config, ...}: {
  # Keeps a host's local qmd collection(s) fresh, independent of whether the
  # host also runs qmd-mcp.nix's HTTP server. qmd has no filesystem watcher
  # of its own; `update` (rescan) and `embed` (vectorize new/changed content)
  # only run when invoked. Poll on a timer instead of a systemd.path watch:
  # Obsidian autosaves constantly and touches nested subfolders that a
  # non-recursive path unit wouldn't see anyway.
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
