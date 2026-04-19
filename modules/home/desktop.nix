{ ... }:
{
  programs.alacritty = {
    enable = true;
  };

  programs.wofi = {
    enable = true;
    settings = {
      allow_markup = true;
      insensitive = true;
    };
  };

  programs.hypr-binds = {
    enable = true;
    settings = {
      launcher = {
        app = "wofi";
      };
    };
  };
}
