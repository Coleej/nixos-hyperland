{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;
    dataLocation = "${config.xdg.configHome}/task";
    config = {
      rc.taskrc = "${config.xdg.configHome}/task/taskrc";
      sync.server.url = "https://taskchampion.codyjohnson.xyz";
      sync.server.client_id = "9ddb3dd1-e22e-469c-99c0-9a054fecb6bd";
      sync.encryption_secret = "zuNg0hee";
    };
  };

  home.file.".netrc" = {
    text = ''
      machine nc.codyjohnson.xyz
      login cody
      password 4tCn$u!fQ$tEWR^52SI*
    '';
  };

  home.activation.fixNetrcPermissions = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ -f "$HOME/.netrc" ]; then
      run chmod 600 "$HOME/.netrc"
    fi
  '';

  systemd.user.services.nextcloud-sync = {
    Unit = {
      Description = "Nextcloud sync";
      After = "network-online.target";
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.nextcloud-client}/bin/nextcloudcmd -n /home/cody/Nextcloud https://nc.codyjohnson.xyz/";
    };
    Install.WantedBy = [ "multi-user.target" ];
  };

  systemd.user.timers.nextcloud-sync = {
    Unit.Description = "Auto-sync Nextcloud files hourly";
    Timer = {
      OnBootSec = "5min";
      OnUnitActiveSec = "1h";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
