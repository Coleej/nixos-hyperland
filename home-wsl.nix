{hostUser, ...}: {
  imports = [./modules/home/wsl.nix];

  home.username = hostUser.name;
  home.homeDirectory = hostUser.home;
  home.stateVersion = "25.11";
}
