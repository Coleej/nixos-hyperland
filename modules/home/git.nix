{ lib, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user.email = "codyjohnson144@gmail.com";
      user.name = "Cody";
      core.autocrlf = "input";
      pull.rebase = true;
      fetch.prune = true;
      color.ui = "auto";
      init.defaultBranch = "main";
      alias.co = "checkout";
      alias.br = "branch";
      alias.ci = "commit";
      alias.st = "status";
    };
  };
}
