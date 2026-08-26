{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.hyperland.android;

  # Declarative SDK for CLI Gradle builds. Wear OS AVD system images are NOT
  # provisioned here — install those through Android Studio's SDK Manager
  # (this module only needs platforms/build-tools/platform-tools/emulator).
  # Requires nixpkgs.config.android_sdk.accept_license in each host.
  androidSdk = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [
      "33"
      "34"
      "35"
    ];
    includeEmulator = true;
  };
in {
  options.hyperland.android = {
    enable = lib.mkEnableOption "Android/Wear OS development tooling (adb, KVM access)";
    studio.enable = lib.mkEnableOption "Android Studio (AVD/SDK manager GUI)";
    sdk.enable = lib.mkEnableOption "Declarative Android SDK via androidenv";
  };

  config = lib.mkIf cfg.enable {
    # programs.adb was removed upstream (systemd 258 handles Android uaccess
    # rules automatically); pkgs.android-tools below provides adb itself.
    users.users."${config.hyperland.user.name}".extraGroups = ["kvm"];

    environment.systemPackages =
      [
        pkgs.android-tools
        pkgs.jdk17_headless
      ]
      ++ lib.optional cfg.studio.enable pkgs.android-studio
      ++ lib.optional cfg.sdk.enable androidSdk.androidsdk;

    environment.sessionVariables = lib.mkIf cfg.sdk.enable {
      ANDROID_HOME = "${androidSdk.androidsdk}/libexec/android-sdk";
    };
  };
}
