{ hostUser, ... }:
{
  imports = [ ./modules/home ];

  home.username = hostUser.name;
  home.homeDirectory = hostUser.home;
  home.stateVersion = "25.11";
}
