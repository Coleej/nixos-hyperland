# Multi-Host Refactor Plan

## Overview

This document tracks the refactor of the NixOS flake config to support multiple hosts
while sharing as much configuration as possible. The changes are organized into 8 phases.
Each phase should be completed and verified before moving to the next.

**Key goals:**
- Support a second host (`desktop`) with an AMD GPU
- Fix AMD GPU env var injection (currently dead code)
- Move per-host monitor configs into host directories
- Break the monolithic `home.nix` into importable `modules/home/` submodules
- Remove plaintext secrets from the repo using `sops-nix`
- Add `hosts/desktop/` with a placeholder hardware config

**Verify after each phase with:**
```bash
sudo nixos-rebuild dry-activate --flake .#default
```

---

## Phase 1 — Add sops-nix to the flake

### Context

`sops-nix` must be added as a flake input before any secret declarations can be made
in later phases. It needs to be wired in both as a NixOS module (for system-level
secret management) and as a Home Manager module (for user-level secret declarations
in `home.nix`).

The age public key for encryption is:
```
age1zca5a56nlxsffsqvunftgkgfu22jfpjryjl7mpzyg3gajvtk7gsst34s3r
```

The private key lives at `~/.config/sops/age/keys.txt` on each machine that needs
to decrypt secrets. This file must be restored from the password manager on new hosts
before running `nixos-rebuild switch`.

### Tasks

- [x] In `flake.nix`, add `sops-nix` to the `inputs` attrset alongside the other
  inputs:
  ```nix
  sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  ```

- [x] In `flake.nix`, add `sops-nix` to the `outputs` function argument destructuring:
  ```nix
  outputs = {
    self,
    nixpkgs,
    home-manager,
    hyprland,
    hypr-binds,
    sops-nix,
    ...
  }:
  ```

- [x] In `flake.nix`, add `sops-nix.nixosModules.sops` to the `modules` list inside
  `makeHostConfig`, alongside the other top-level module entries:
  ```nix
  modules = [
    ./hosts/${hostName}/system.nix
    home-manager.nixosModules.home-manager
    sops-nix.nixosModules.sops        # <-- add this line
    {
      home-manager.useGlobalPkgs = true;
      ...
    }
  ];
  ```

- [x] In `flake.nix`, add `sops-nix.homeManagerModules.default` to the Home Manager
  `imports` list inside the `home-manager.users.<name>` attrset in `makeHostConfig`:
  ```nix
  home-manager.users.${hostData.user.name} = {
    imports = [
      ./home.nix
      hypr-binds.homeManagerModules.x86_64-linux.default
      sops-nix.homeManagerModules.default    # <-- add this line
    ];
    _module.args = {inherit self;};
  };
  ```

- [x] Run `nix flake lock --update-input sops-nix` to fetch and pin sops-nix in
  `flake.lock`.

- [x] Verify: `sudo nixos-rebuild dry-activate --flake .#default` should succeed.
  sops-nix adds new module options but nothing breaks without any secrets declared yet.

---

## Phase 2 — Create sops config and encrypt secrets

### Context

`sops` uses a `.sops.yaml` file at the repo root to determine which encryption keys
to use when creating or editing encrypted files. The `secrets/secrets.yaml` file will
hold the two secrets currently hardcoded in `home.nix`:

1. **`nextcloud_password`** — currently at `home.nix:258`, the Nextcloud password
   in the `.netrc` file entry
2. **`taskchampion_secret`** — currently at `home.nix:90`, the `encryption_secret`
   field in `programs.taskwarrior.config`

The `sops` and `age` binaries are already available system-wide — they are included
in `modules/shared/packages.nix` under `base.enable` (lines 53–54 of that file).

The encrypted `secrets/secrets.yaml` **is safe to commit to git**. The encryption
is precisely what makes it safe. Do not add it to `.gitignore`.

### Tasks

- [x] Create `.sops.yaml` at the repo root with the following content:
  ```yaml
  keys:
    - &main age1zca5a56nlxsffsqvunftgkgfu22jfpjryjl7mpzyg3gajvtk7gsst34s3r
  creation_rules:
    - path_regex: secrets/.*\.yaml$
      key_groups:
        - age:
          - *main
  ```

- [x] Create the `secrets/` directory:
  ```bash
  mkdir -p secrets
  ```

- [x] Run `sops secrets/secrets.yaml` to open the file in `$EDITOR`. Enter the
  following YAML content, then save and close the editor. sops will encrypt the file
  automatically on exit:
  ```yaml
  nextcloud_password: "4tCn$u!fQ$tEWR^52SI*"
  taskchampion_secret: "zuNg0hee"
  ```
  The resulting file will look very different from the above — sops wraps values in
  its own metadata envelope. This is expected.

- [x] Verify encryption worked: `sops --decrypt secrets/secrets.yaml` should print
  the plaintext key-value pairs back to stdout without error.

- [x] Stage both new files:
  ```bash
  git add .sops.yaml secrets/secrets.yaml
  ```

---

## Phase 3 — Fix AMD env vars in `modules/shared/hyprland.nix`

### Context

The current AMD code in `modules/shared/hyprland.nix` (lines 186–189) is guarded by
the condition `cfg.amd.enable && !cfg.useHomeManager`. Because all hosts currently
set `useHomeManager = true` in `hosts/default/system.nix` (line 31), this block
**never executes** — it is dead code. Setting `amd.enable = true` on any host today
has zero effect.

The correct fix is to move the AMD env vars out of the shell setup script entirely
and into `environment.sessionVariables`, which is the proper NixOS mechanism for
session-wide environment variables. This approach works regardless of whether Home
Manager manages dotfiles and is how the upstream hyprvibe project handles it.

In addition to the two Hyprland env vars already present (`AMD_VULKAN_ICD` and
`MESA_LOADER_DRIVER_OVERRIDE`), the upstream project also sets `LIBVA_DRIVER_NAME =
"radeonsi"` for VA-API hardware video decoding, and enables
`hardware.graphics.enable32Bit = true` for 32-bit Vulkan support (required for Steam
and Wine on AMD). Both should be added here.

The dead shell script block should be removed entirely from the `hyperland-setup`
oneshot service.

### Tasks

- [x] In `modules/shared/hyprland.nix`, inside the top-level `config = lib.mkIf
  cfg.enable { }` block (after the closing brace of `programs.hyprland`), add:
  ```nix
  environment.sessionVariables = lib.mkIf cfg.amd.enable {
    AMD_VULKAN_ICD = "RADV";
    MESA_LOADER_DRIVER_OVERRIDE = "radeonsi";
    LIBVA_DRIVER_NAME = "radeonsi";
  };

  hardware.graphics.enable32Bit = lib.mkIf cfg.amd.enable true;
  ```

- [x] In `modules/shared/hyprland.nix`, inside the `ExecStart` shell script of
  `systemd.user.services.hyperland-setup`, remove the following block entirely
  (currently lines 186–189):
  ```nix
  ${lib.optionalString (cfg.amd.enable && !cfg.useHomeManager) ''
    printf '"'"'%s\n'"'"' "env = AMD_VULKAN_ICD,RADV" "env = MESA_LOADER_DRIVER_OVERRIDE,radeonsi" > ${userHome}/.config/hypr/hyprland-local.conf
    printf '"'"'%s\n'"'"' "source=~/.config/hypr/hyprland-local.conf" >> ${userHome}/.config/hypr/hyprland.conf
  ''}
  ```

- [x] Verify: `sudo nixos-rebuild dry-activate --flake .#default` should succeed.
  The `default` host does not set `amd.enable = true`, so no AMD vars will appear
  for it — this is correct.

---

## Phase 4 — Move monitor config into host directory

### Context

`configs/hyprland-monitors.conf` currently holds the monitor config for the `default`
host (a single 1920x1080 eDP-1 display). It is referenced from
`hosts/default/system.nix` line 26 as `../../configs/hyprland-monitors.conf`.

Keeping monitor configs in the shared `configs/` directory does not scale to multiple
hosts — different machines have completely different display hardware. Each host should
own its monitor config alongside its other host-specific files in `hosts/<name>/`.

### Tasks

- [x] Copy `configs/hyprland-monitors.conf` to `hosts/default/hyprland-monitors.conf`.
  The file content is identical:
  ```bash
  cp configs/hyprland-monitors.conf hosts/default/hyprland-monitors.conf
  ```

- [x] In `hosts/default/system.nix`, update the `monitorsFile` option (currently line
  26) to reference the new host-local path:
  ```nix
  # Before:
  monitorsFile = ../../configs/hyprland-monitors.conf;
  # After:
  monitorsFile = ./hyprland-monitors.conf;
  ```

- [x] Delete `configs/hyprland-monitors.conf` from the shared configs directory:
  ```bash
  git rm configs/hyprland-monitors.conf
  ```

- [x] Verify: `sudo nixos-rebuild dry-activate --flake .#default` should succeed,
  and the monitor file path in the Nix store derivation should now resolve into the
  `hosts/default/` directory rather than `configs/`.

---

## Phase 5 — Split `home.nix` into `modules/home/`

### Context

The current `home.nix` (301 lines) is monolithic — everything lives in one file.
This makes it impossible for a second host to selectively include or exclude features
(e.g., a desktop machine might not need the Nextcloud sync timer, or a laptop might
need battery tools not relevant to a desktop).

The goal is to split `home.nix` into focused submodules under `modules/home/` and
make the root `home.nix` a thin entry point that just sets username, home directory,
and state version.

**Current `home.nix` section map (for reference during splitting):**
- Lines 1–14: function signature + `configFiles` let binding (fileset for configs/)
- Lines 16–19: `home.username`, `home.homeDirectory`, `home.stateVersion`
- Lines 21–42: `home.file` entries for hypr and waybar config files
- Lines 44–80: `home.packages`
- Lines 82–92: `programs.taskwarrior`
- Lines 94–131: `programs.fish`
- Lines 133–144: `programs.starship`
- Lines 146–149: `programs.fzf`
- Lines 151–153: `programs.alacritty`
- Lines 155–234: `programs.wofi`
- Lines 237–244: `programs.hypr-binds`
- Lines 246–252: `home.file.".config/alacritty/alacritty.toml"`
- Lines 254–266: `home.file.".netrc"` + `home.activation.fixNetrcPermissions`
- Lines 268–287: `systemd.user.services/timers.nextcloud-sync`
- Lines 289–300: `nixpkgs.config`, `home.sessionVariables`, `home.sessionPath`

**Important:** Do not fix the plaintext secrets in this phase. Keep them as-is in
`modules/home/services.nix`. Secrets are replaced in Phase 6. Doing both changes
at once makes debugging harder if something goes wrong.

### Tasks

- [ ] Create the directory `modules/home/`.

- [ ] Create `modules/home/packages.nix` containing the `home.packages` list from
  `home.nix` lines 44–80. File signature: `{ pkgs, ... }:`.

- [ ] Create `modules/home/shell.nix` containing:
  - `programs.fish` (lines 96–131 of current `home.nix`)
  - `programs.starship` (lines 133–144)
  - `programs.fzf` (lines 146–149)
  File signature: `{ pkgs, ... }:`.

- [ ] Create `modules/home/desktop.nix` containing:
  - The `configFiles` let binding (lines 8–14 of current `home.nix`) — this is the
    `lib.fileset.toSource` expression that filters `configs/` for `.conf`, `.json`,
    and `.css` files. It requires `self` in scope.
  - `home.file` entries for hypr and waybar config files (lines 21–42)
  - `programs.alacritty` (lines 151–153)
  - `home.file.".config/alacritty/alacritty.toml"` (lines 246–252)
  - `programs.wofi` (lines 155–234)
  - `programs.hypr-binds` (lines 237–244)
  File signature: `{ config, pkgs, lib, self, ... }:`. The `self` arg is already
  passed via `_module.args` in `flake.nix` so no flake changes are needed.

- [ ] Create `modules/home/services.nix` containing:
  - `programs.taskwarrior` (lines 82–92) — keep plaintext `encryption_secret` for now
  - `home.file.".netrc"` (lines 254–259) — keep plaintext password for now
  - `home.activation.fixNetrcPermissions` (lines 262–266) — keep as-is for now
  - `systemd.user.services.nextcloud-sync` (lines 268–278)
  - `systemd.user.timers.nextcloud-sync` (lines 280–287)
  File signature: `{ config, pkgs, lib, ... }:`.

- [ ] Create `modules/home/secrets.nix` as a stub (will be filled in Phase 6):
  ```nix
  # Secrets wired in Phase 6 via sops-nix
  { ... }: { }
  ```

- [ ] Create `modules/home/default.nix` that imports all submodules and holds the
  remaining shared settings from `home.nix` lines 289–300:
  ```nix
  { ... }: {
    imports = [
      ./packages.nix
      ./shell.nix
      ./desktop.nix
      ./services.nix
      ./secrets.nix
    ];

    programs.home-manager.enable = true;
    nixpkgs.config.allowUnfree = true;

    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      XDG_CONFIG_HOME = "\${HOME}/.config";
    };

    home.sessionPath = [
      "\${HOME}/.local/bin"
      "\${HOME}/.cargo/bin"
    ];
  }
  ```
  Note the escaped `\${HOME}` — this prevents Nix from trying to interpolate `HOME`
  as a Nix variable at build time. The literal string `${HOME}` must appear in the
  final file.

- [ ] Rewrite the root `home.nix` to be a thin entry point:
  ```nix
  { ... }: {
    imports = [ ./modules/home ];

    home.username = "cody";
    home.homeDirectory = "/home/cody";
    home.stateVersion = "25.11";
  }
  ```
  All other content should be removed. Everything now lives in `modules/home/`.

- [x] Verify: `sudo nixos-rebuild dry-activate --flake .#default` should succeed
  with no functional changes from the user's perspective. The plaintext secrets are
  still present in `modules/home/services.nix` at this point — that is intentional.

---

## Phase 6 — Wire sops secrets into `modules/home/secrets.nix`

### Context

Two plaintext secrets must be removed from the Nix source:

1. **Nextcloud password** — currently in `modules/home/services.nix` inside
   `home.file.".netrc".text`
2. **TaskChampion encryption secret** — currently in `modules/home/services.nix`
   inside `programs.taskwarrior.config`

Both were encrypted into `secrets/secrets.yaml` in Phase 2 as `nextcloud_password`
and `taskchampion_secret`.

**How sops-nix works in the Home Manager context:**
- `sops.secrets.<name>` declarations cause sops-nix to decrypt the named secret at
  activation time and write the plaintext value to a file at a path like
  `/run/user/<uid>/secrets/<name>` (the exact path is available at build time as
  `config.sops.secrets.<name>.path`)
- Secret files are owned by the user and readable only by them (mode 0400 by default)
- Activation scripts can read these paths at runtime to inject values into config files

**Approach for `.netrc`:**
The `home.file` approach writes files at link-generation time before sops secrets are
available. Replace the static `home.file.".netrc"` entry with a `home.activation`
script that reads the sops secret path and writes `.netrc` with correct permissions.
Remove the now-redundant `fixNetrcPermissions` activation script.

**Approach for TaskChampion:**
The `programs.taskwarrior.config` attrset is evaluated at build time, so it cannot
reference a runtime secret path. Instead, remove `encryption_secret` from the
taskwarrior config attrset and add a `home.activation` script that appends the line
to the taskrc file after the sops secret is decrypted. The activation script must
run after `linkGeneration` (when taskwarrior writes its initial taskrc).

### Tasks

- [ ] In `modules/home/secrets.nix`, replace the stub with real sops declarations:
  ```nix
  { config, ... }: {
    sops = {
      age.keyFile = "/home/cody/.config/sops/age/keys.txt";
      defaultSopsFile = ../../secrets/secrets.yaml;
      secrets = {
        nextcloud_password = { };
        taskchampion_secret = { };
      };
    };
  }
  ```

- [ ] In `modules/home/services.nix`, remove the `home.file.".netrc"` static entry
  and the `home.activation.fixNetrcPermissions` block. Replace both with a single
  activation script:
  ```nix
  home.activation.writeNetrc = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    secret_path="${config.sops.secrets.nextcloud_password.path}"
    if [ -f "$secret_path" ]; then
      password=$(cat "$secret_path")
      printf 'machine nc.codyjohnson.xyz\nlogin cody\npassword %s\n' "$password" \
        > "$HOME/.netrc"
      chmod 600 "$HOME/.netrc"
    fi
  '';
  ```
  Note: The `${config.sops.secrets.nextcloud_password.path}` interpolation is a Nix
  string interpolation that resolves to the runtime path at build time (e.g.,
  `/run/user/1000/secrets/nextcloud_password`). This is correct and intentional.

- [ ] In `modules/home/services.nix`, remove `sync.encryption_secret = "zuNg0hee";`
  from `programs.taskwarrior.config`. Then add an activation script that writes the
  secret into the taskrc at runtime:
  ```nix
  home.activation.writeTaskchampionSecret = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    secret_path="${config.sops.secrets.taskchampion_secret.path}"
    taskrc="${config.xdg.configHome}/task/taskrc"
    if [ -f "$secret_path" ] && [ -f "$taskrc" ]; then
      secret=$(cat "$secret_path")
      ${pkgs.gnused}/bin/sed -i '/^sync\.encryption_secret=/d' "$taskrc"
      echo "sync.encryption_secret=$secret" >> "$taskrc"
    fi
  '';
  ```
  Ensure `pkgs` is in the file signature of `services.nix` (`{ config, pkgs, lib, ... }:`).

- [ ] Verify: `sudo nixos-rebuild dry-activate --flake .#default` should succeed.

- [ ] Do a full switch to confirm sops decryption works at runtime:
  ```bash
  sudo nixos-rebuild switch --flake .#default
  ```
  After logging in, verify:
  - `/run/user/1000/secrets/nextcloud_password` exists and contains the password
  - `/run/user/1000/secrets/taskchampion_secret` exists and contains the secret
  - `~/.netrc` exists, is mode 600, and contains the correct machine/login/password
  - `~/.config/task/taskrc` contains a `sync.encryption_secret=` line

- [ ] Confirm no plaintext secrets remain in any `.nix` file:
  ```bash
  grep -r "zuNg0hee" .
  grep -r "4tCn" .
  ```
  Both commands should return no results.

---

## Phase 7 — Add `hosts/desktop/`

### Context

The desktop host has an AMD GPU. Setting `hyperland.hyprland.amd.enable = true` in
its `system.nix` will (after Phase 3) cause the following to be set automatically:
- `environment.sessionVariables`: `AMD_VULKAN_ICD`, `MESA_LOADER_DRIVER_OVERRIDE`,
  `LIBVA_DRIVER_NAME`
- `hardware.graphics.enable32Bit = true`

The `hardware-configuration.nix` for the desktop is not yet available — it must be
generated on the actual hardware with `nixos-generate-config --root /mnt`. A
placeholder is created here so the flake evaluates correctly in the meantime. The
placeholder uses `kvm-amd` as the kernel module (appropriate for AMD hosts) and
disk labels as device references (update these with real values when deploying).

The desktop monitor config is also unknown. A placeholder single-monitor entry is
used; update it by running `hyprctl monitors` on the live system.

The desktop host uses the same user (`cody`) and the same root `home.nix` as the
`default` host. No changes to `home.nix` or `modules/home/` are required.

### Tasks

- [ ] Create the directory `hosts/desktop/`:
  ```bash
  mkdir -p hosts/desktop
  ```

- [ ] Create `hosts/desktop/hyprland-monitors.conf` as a placeholder:
  ```
  # PLACEHOLDER — replace with actual monitor config for the desktop host.
  # Run `hyprctl monitors` on the live system to find monitor names and modes.
  #
  # Example single monitor:
  #   monitor=DP-1,2560x1440@144,0x0,1
  #
  # Example dual monitor:
  #   monitor=DP-1,2560x1440@144,0x0,1
  #   monitor=HDMI-A-1,1920x1080@60,2560x0,1
  monitor=DP-1,preferred,0x0,1
  ```

- [ ] Create `hosts/desktop/hardware-configuration.nix` as a placeholder:
  ```nix
  # PLACEHOLDER — replace with the real output of:
  #   nixos-generate-config --root /mnt --dir /mnt/etc/nixos
  # on the actual desktop hardware before deploying to this host.
  # Update fileSystems, boot devices, and kernel modules to match the real hardware.
  {
    lib,
    modulesPath,
    ...
  }: {
    imports = [(modulesPath + "/installer/scan/not-detected.nix")];

    boot.initrd.availableKernelModules = ["ahci" "xhci_pci" "nvme" "usb_storage" "usbhid" "sd_mod"];
    boot.initrd.kernelModules = [];
    boot.kernelModules = ["kvm-amd"];
    boot.extraModulePackages = [];

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
      options = ["fmask=0077" "dmask=0077"];
    };

    swapDevices = [];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = lib.mkDefault true;
  }
  ```

- [ ] Create `hosts/desktop/system.nix` modeled after `hosts/default/system.nix`
  with AMD-specific changes:
  ```nix
  {
    config,
    pkgs,
    lib,
    hyprland,
    self ? null,
    ...
  }: {
    imports = [
      ./hardware-configuration.nix
      ../../modules/shared
    ];

    hyperland.enable = true;

    hyperland.user = {
      name = "cody";
      group = "users";
      home = "/home/cody";
      description = "Cody";
      linger = true;
      extraGroups = [];
    };

    hyperland.hyprland = {
      monitorsFile = ./hyprland-monitors.conf;
      hyprpaperTemplate = ../../configs/hyprpaper-default.conf;
      hyprlockTemplate = ../../configs/hyprlock-default.conf;
      hypridleConfig = ../../configs/hypridle-default.conf;
      scriptsDir = ../../scripts/hyprland;
      useHomeManager = true;
      amd.enable = true;
    };

    hyperland.waybar = {
      enable = true;
      configPath = ../../configs/waybar/config.json;
      stylePath = ../../configs/waybar/style.css;
      scriptsDir = ../../scripts/waybar;
      useHomeManager = true;
    };

    hyperland.services = {
      enable = true;
      openssh.enable = true;
    };

    services.tailscale.enable = true;

    hyperland.packages = {
      enable = true;
      base.enable = true;
      desktop.enable = true;
      dev.enable = true;
    };

    boot.loader.grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
    boot.loader.efi.efiSysMountPoint = "/boot";

    networking.hostName = "desktop";
    networking.networkmanager.enable = true;

    i18n.defaultLocale = "en_US.UTF-8";
    time.timeZone = "America/Chicago";

    hardware.graphics.enable = true;
    hardware.graphics.enable32Bit = true;
    hardware.bluetooth.enable = true;

    fonts.packages = with pkgs; [
      tokyonight-gtk-theme
      papirus-icon-theme
      bibata-cursors
    ];

    xdg.portal.enable = true;
    xdg.portal.wlr.enable = true;

    nix.settings.experimental-features = ["nix-command" "flakes"];
    nixpkgs.config.allowUnfree = true;

    programs.fish.enable = true;

    system.stateVersion = "25.11";
  }
  ```

- [x] Verify the `desktop` config evaluates without error (do not switch — this is
  not the current machine):
  ```bash
  nixos-rebuild build --flake .#desktop
  ```

---

## Phase 8 — Add `desktop` host to `flake.nix`

### Context

The `hosts` attrset in `flake.nix` currently only contains `default`. The `desktop`
entry must be added so that `nixos-rebuild --flake .#desktop` resolves to
`hosts/desktop/system.nix`. The existing `makeHostConfig` function handles any host
generically using `hostName` and `hostData.user.name` — no changes to that function
are needed.

### Tasks

- [x] In `flake.nix`, add `desktop` to the `hosts` attrset. The full attrset after
  the change should look like:
  ```nix
  hosts = {
    default = {
      user = {
        name = "cody";
        group = "users";
        home = "/home/cody";
        description = "Cody";
        extraGroups = [];
      };
    };
    desktop = {
      user = {
        name = "cody";
        group = "users";
        home = "/home/cody";
        description = "Cody";
        extraGroups = [];
      };
    };
  };
  ```

- [x] Run `nix flake check` to verify both configurations evaluate without errors:
  ```bash
  nix flake check
  ```

- [x] Run a final dry-activate on the `default` host to confirm it is unaffected:
  ```bash
  sudo nixos-rebuild dry-activate --flake .#default
  ```

---

## Post-implementation checklist

- [ ] `sudo nixos-rebuild switch --flake .#default` completes successfully
- [ ] `nixos-rebuild build --flake .#desktop` completes successfully (build only, no switch)
- [ ] `sops --decrypt secrets/secrets.yaml` prints plaintext without error
- [ ] After switching `default`: `/run/user/1000/secrets/nextcloud_password` exists
- [ ] After switching `default`: `/run/user/1000/secrets/taskchampion_secret` exists
- [ ] After login on `default`: `~/.netrc` exists, mode is 600, content is correct
- [ ] After login on `default`: `~/.config/task/taskrc` contains `sync.encryption_secret=`
- [ ] `configs/hyprland-monitors.conf` has been deleted (moved to `hosts/default/`)
- [ ] No plaintext secrets remain in any `.nix` file:
  ```bash
  grep -r "zuNg0hee" . --include="*.nix"
  grep -r "4tCn" . --include="*.nix"
  ```
  Both must return no results.
- [ ] `nix fmt` reports no formatting changes (all new files formatted with alejandra)

---

## File map — what changes where

| File | Action |
|---|---|
| `flake.nix` | Add sops-nix input + modules; add `desktop` host to `hosts` attrset |
| `.sops.yaml` | Create new |
| `secrets/secrets.yaml` | Create new (sops-encrypted) |
| `modules/shared/hyprland.nix` | Replace dead AMD shell block with `environment.sessionVariables` |
| `configs/hyprland-monitors.conf` | Delete (content moved to `hosts/default/`) |
| `hosts/default/hyprland-monitors.conf` | Create new (moved from `configs/`) |
| `hosts/default/system.nix` | Update `monitorsFile` path from `../../configs/` to `./` |
| `home.nix` | Replace with thin entry point (3 options + `imports`) |
| `modules/home/default.nix` | Create new — imports all submodules, shared HM baseline |
| `modules/home/packages.nix` | Create new — `home.packages` list |
| `modules/home/shell.nix` | Create new — fish, starship, fzf |
| `modules/home/desktop.nix` | Create new — wofi, alacritty, hypr-binds, config file links |
| `modules/home/services.nix` | Create new — taskwarrior, nextcloud sync, .netrc |
| `modules/home/secrets.nix` | Create new — sops secret declarations |
| `hosts/desktop/system.nix` | Create new — AMD host config |
| `hosts/desktop/hardware-configuration.nix` | Create placeholder |
| `hosts/desktop/hyprland-monitors.conf` | Create placeholder |
