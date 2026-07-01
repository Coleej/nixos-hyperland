# AGENTS.md — NixOS Hyperland Configuration

## Overview

Flake-based NixOS configuration with Hyprland (Wayland compositor), Home Manager, and sops-nix
secrets. Three hosts are defined in `flake.nix`'s `hosts` attrset: `default` and `amd-workstation`
(Hyprland desktops) and `wsl` (headless NixOS-WSL, terminal-only) — more can be added the same way.

`makeHostConfig` supports two optional per-host flags in the `hosts` attrset: `wsl = true` adds
`nixos-wsl.nixosModules.default` and omits the `hypr-binds` HM module; `homeModule` selects the
Home Manager entrypoint (default `./home.nix`; WSL uses `./home-wsl.nix`).

**Repo structure:**
```
nixos-hyperland/
├── flake.nix                  # Flake inputs (nixpkgs, home-manager, hyprland, hypr-binds, sops-nix) + hosts attrset
├── hosts/
│   ├── default/
│   │   ├── system.nix          # Host NixOS config (imports modules/shared)
│   │   ├── hardware-configuration.nix
│   │   └── hyprland-monitors.conf  # Per-host monitor layout
│   ├── amd-workstation/
│   │   ├── system.nix          # Same as default, plus hyperland.hyprland.amd.enable + hyperland.gaming.enable
│   │   ├── hardware-configuration.nix
│   │   └── hyprland-monitors.conf
│   └── wsl/
│       └── system.nix          # Headless NixOS-WSL host (no hardware-configuration.nix, no bootloader/kernel)
├── modules/
│   ├── shared/                # NixOS modules, options under hyperland.<name>
│   │   ├── default.nix         # hyperland.enable gate + default sub-option wiring
│   │   ├── user.nix            # User creation (hyperland.user.*)
│   │   ├── desktop.nix         # GDM, portals, fonts, Wayland session vars
│   │   ├── hyprland.nix        # Hyprland + hyprpaper/hyprlock/hypridle systemd services
│   │   ├── waybar.nix          # Waybar systemd service + config install
│   │   ├── services.nix        # openssh, tlp
│   │   ├── system.nix          # Kernel, zram, fstrim, Nix GC, power management
│   │   ├── packages.nix        # base/desktop/dev package groups
│   │   └── gaming.nix          # Steam, Gamescope, gamemode (amd-workstation only)
│   └── home/                  # Home Manager modules, plain HM options (no hyperland.* namespace)
│       ├── default.nix         # Desktop HM entrypoint (imports below) + session vars/path
│       ├── packages.nix        # home.packages (CLI + GUI apps: firefox, obsidian, etc.)
│       ├── shell.nix           # Fish + Starship prompt + fzf + direnv (shared by desktop + WSL)
│       ├── desktop.nix         # GTK theme, alacritty, wofi, hypr-binds, installs configs/* via home.file
│       ├── services.nix        # taskwarrior (taskchampion sync), netrc activation script
│       ├── secrets.nix         # sops age key + secret declarations (desktop)
│       ├── git.nix, email.nix  # git config (shared), Proton Mail Bridge
│       ├── wsl.nix             # Headless WSL HM entrypoint — imports packages-wsl/shell/git/secrets-wsl/taskwarrior
│       ├── packages-wsl.nix    # Curated headless CLI/dev packages (no GUI)
│       ├── secrets-wsl.nix     # sops wiring for WSL — only taskchampion_secret
│       └── taskwarrior.nix     # Taskwarrior 3 + taskchampion sync (secret injected at activation)
├── configs/                   # Dotfiles installed by modules/home/desktop.nix or the hyperland-setup service
│   ├── hyprland-base.conf      # Base Hyprland config + keybindings
│   ├── hyprland-default.conf
│   ├── hyprpaper-default.conf  # Template, __WALLPAPER__ substituted at activation
│   ├── hyprlock-default.conf   # Template, __WALLPAPER__ substituted at activation
│   ├── hypridle-default.conf
│   ├── wofi-style.css
│   └── waybar/
│       ├── config.json
│       ├── style.css           # Active theme (currently cyberpunk)
│       └── base.css, cyberpunk.css, catppuccin-*.css  # Selectable theme variants
├── scripts/
│   ├── hyprland/               # brightness.sh, show-keybindings.sh
│   ├── waybar/                 # waybar-dunst.sh, waybar-mpris.sh, waybar-public-ip.sh
│   └── rofi-brightness.sh
├── secrets/secrets.yaml       # sops-encrypted secrets (edit with `sops secrets/secrets.yaml`)
├── .sops.yaml                 # age recipient key used to encrypt secrets/secrets.yaml
├── wallpapers/default.jpg     # Placeholder — replace with your wallpaper
├── .githooks/pre-commit       # Auto-formats staged .nix files with alejandra
├── home.nix                   # Desktop HM entrypoint → modules/home/default.nix (username/homeDirectory/stateVersion)
├── home-wsl.nix               # WSL HM entrypoint → modules/home/wsl.nix
└── flake.lock
```

## Build / Eval Commands

### Evaluate the full configuration
```bash
# System config
nix eval .#nixosConfigurations.default.config.system.build.toplevel --json

# Home Manager user config
nix eval .#nixosConfigurations.default.config.home-manager.users.cody --json
```

### Build and apply
```bash
# Dry-run / type-check
sudo nixos-rebuild dry-activate --flake .#default        # or .#amd-workstation

# Apply (system + Home Manager - use this!)
sudo nixos-rebuild switch --flake .#default

# Build only (no switch)
nixos-rebuild build --flake .#default

# Home Manager only (faster iteration, no system rebuild)
home-manager switch --flake .#default
```

### Formatting / Linting
```bash
# Format all .nix files (alejandra — idempotent, no-conflict formatting)
nix run nixpkgs#alejandra -- .

# Lint with statix (static analysis for Nix)
nix run nixpkgs#statix -- fix --mode=clippy ./modules/shared/*.nix

# Check formatting
nix run nixpkgs#alejandra -- --check .
```

### Single-file eval (useful for debugging a specific Nix expression)
```bash
nix eval --file ./modules/shared/hyprland.nix --apply 'x: x.options.hyperland.hyprland' 2>/dev/null
```

## Code Style Guidelines

### General Conventions
- **Flakes-first**: Always use flakes. No `niv` or channel-based approaches.
- **Modular structure**: System config in `hosts/<name>/system.nix`, reusable NixOS logic in
  `modules/shared/` (under the `hyperland.*` option namespace), reusable Home Manager logic in
  `modules/home/` (plain HM options, imported via `home.nix`), shared dotfile configs in `configs/`.
- **Multi-host**: Host-specific data (username, groups, hostname, monitor config) lives in
  `flake.nix` (`hosts` attr) and `hosts/<name>/system.nix` + `hosts/<name>/hyprland-monitors.conf`.
  Shared modules have no host-specific values baked in.
- **State version**: Always set `stateVersion` to the NixOS release actually in use (currently `"25.11"` for both `system.stateVersion` and `home.stateVersion`); don't bump casually.

### Nix Language Style
- **Formatter**: `alejandra` (idempotent). Run before committing.
- **Indentation**: 2 spaces.
- **Attribute ordering**: Alphabetical within attribute sets, or logical (imports first).
- **Imports**: Single `imports = []` at top of each module.
- **Package references**: Always `pkgs.<name>`. Avoid `with pkgs;` at top level.
- **Quotes**: Double quotes for strings; single quotes only where needed.
- **Error handling**: No `|| true` or silent failures. Nix is declarative — fail loudly.

### Naming Conventions
- **Module prefix**: `hyperland.<submodule>` for NixOS modules only (e.g., `hyperland.hyprland`,
  `hyperland.waybar`, `hyperland.gaming`). Home Manager modules under `modules/home/` use plain
  `programs.*`/`home.*`/`services.*` — no namespace indirection.
- **Option names**: `lowerCamelCase` (matches NixOS convention).
- **File names**: `kebab-case.nix` for modules.
- **Host names**: `default`, `amd-workstation`, `wsl`. Add more the same way in `flake.nix`.

### Nixpkgs Usage
- **Package sets**: Always `pkgs.<name>`. No bare package names.
- **Unfree packages**: Set `nixpkgs.config.allowUnfree = true` only in `hosts/<name>/system.nix`.
- **Overlays**: Define in `flake.nix` if you need custom packages.

### Module System
- **Module args**: Prefer `{ config, pkgs, lib, ... }` as the function signature.
- **Enable toggles**: Every `modules/shared/` submodule has a `hyperland.<name>.enable` option.
- **User info**: Shared via `hyperland.user.<field>` options (defined in `modules/shared/user.nix`).
  Host-specific values set in `flake.nix` (hosts attr) and passed to `hosts/<name>/system.nix`.

### Home Manager
- **User packages**: Add to `home.packages` in `modules/home/packages.nix`, not `environment.systemPackages`.
- **Shell integration**: Fish config lives in `modules/home/shell.nix` (`programs.fish.interactiveShellInit`); prompt via `programs.starship`, fuzzy search via `programs.fzf`.
- **Secrets**: Never hardcode secrets. Declare them in `modules/home/secrets.nix` and encrypt values
  in `secrets/secrets.yaml` with `sops` (age key at `~/.config/sops/age/keys.txt`); reference the
  decrypted path via `config.sops.secrets.<name>.path`.

## Adding a New Host

1. Add entry to `flake.nix` `hosts` attr:
   ```nix
   workstation = {
     user = {
       name = "alice";
       group = "users";
       home = "/home/alice";
       description = "Alice";
       extraGroups = [ "libvirtd" ];
     };
   };
   ```

2. Create directory and copy hardware config:
   ```bash
   mkdir -p hosts/workstation
   cp hosts/default/hardware-configuration.nix hosts/workstation/
   cp hosts/default/hyprland-monitors.conf hosts/workstation/
   ```

3. Edit `hosts/workstation/system.nix` (copy from `hosts/default/system.nix` as a starting point):
   - `hyperland.hyprland.monitorsFile` should point at `./hyprland-monitors.conf`
   - Update `networking.hostName`

4. Edit `hosts/workstation/hyprland-monitors.conf` with your monitor setup.

5. Add the new host to the `monitorsFile` attrset in `modules/home/desktop.nix` (keyed by
   `hostName`) — it throws if a host isn't listed there.

6. Rebuild: `sudo nixos-rebuild switch --flake .#workstation`

## Workflow Tips

- **Pre-commit hook**: Installed via `.githooks/pre-commit`. Run `git config core.hooksPath .githooks` on new clones to enable it. Auto-formats staged `.nix` files with alejandra before each commit.
- **Debugging**: Use `nix eval .#nixosConfigurations.default.config.hyperland.hyprland.enable`
- **flake.lock**: Commit it for reproducible builds. Update with `nix flake update`
- **Secrets**: Edit `secrets/secrets.yaml` with `sops secrets/secrets.yaml` — never hand-edit the
  encrypted file directly.
