# AGENTS.md — NixOS Hyperland Configuration

## Overview

Flake-based NixOS configuration with Hyprland (Wayland compositor) and Home Manager.
Structured for easy multi-host support — one host defined now, others can be added to `flake.nix`.

**Repo structure:**
```
nixos-hyperland/
├── flake.nix              # Flake inputs + nixosSystem output builder
├── hosts/
│   └── default/
│       ├── system.nix      # Host NixOS config (imports shared modules)
│       └── hardware-configuration.nix
├── modules/shared/        # Reusable NixOS modules
│   ├── default.nix        # hyperland.enable + submodule defaults
│   ├── user.nix           # User creation + hyperland.user options
│   ├── desktop.nix        # GDM, portals, fonts, session vars
│   ├── hyprland.nix       # Hyprland + hyprpaper/hyprlock/hypridle
│   ├── waybar.nix         # Waybar + scripts install
│   ├── shell.nix          # Fish + Oh My Posh + Atuin
│   ├── services.nix        # PipeWire, flatpak, polkit, blueman
│   ├── system.nix         # Kernel, zram, fstrim, Nix GC
│   └── packages.nix       # Shared package groups
├── configs/               # Shared config files
│   ├── hyprland-base.conf  # Base Hyprland config + keybindings
│   ├── hyprland-default.conf
│   ├── hyprland-monitors.conf  # Per-host monitor config (edit this!)
│   ├── hyprpaper-default.conf
│   ├── hyprlock-default.conf
│   ├── hypridle-default.conf
│   └── waybar/
│       ├── config.json     # Waybar module config
│       └── style.css       # Waybar CSS (cyberpunk theme)
├── scripts/
│   ├── hyprland/          # Hyprland helper scripts
│   │   └── brightness.sh
│   ├── waybar/            # Waybar custom module scripts
│   │   ├── waybar-dunst.sh
│   │   ├── waybar-mpris.sh
│   │   └── waybar-public-ip.sh
│   └── rofi-brightness.sh
├── wallpapers/
│   └── default.jpg         # Placeholder — replace with your wallpaper
├── home.nix               # Home Manager user config
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
sudo nixos-rebuild dry-activate --flake .#default

# Apply
sudo nixos-rebuild switch --flake .#default

# Build only (no switch)
nixos-rebuild build --flake .#default
```

### Home Manager (standalone)
```bash
home-manager -v dryActivation --flake .#default
home-manager switch --flake .#default
```

### Formatting / Linting
```bash
# Format all .nix files (alejandra — idempotent, no-conflict formatting)
nix fmt

# Lint with statix (static analysis for Nix)
nix run nixpkgs#statix -- fix --mode=clippy ./modules/shared/*.nix

# Check formatting
nix run nixpkgs#alejandra -- --check *.nix hosts/**/*.nix modules/**/*.nix
```

### Single-file eval (useful for debugging a specific Nix expression)
```bash
nix eval --file ./modules/shared/hyprland.nix --apply 'x: x.options.hyperland.hyprland' 2>/dev/null
```

## Code Style Guidelines

### General Conventions
- **Flakes-first**: Always use flakes. No `niv` or channel-based approaches.
- **Modular structure**: System config in `hosts/<name>/system.nix`, user config in `home.nix`.
  Reusable logic in `modules/shared/`, shared dotfile configs in `configs/`.
- **Multi-host**: All host-specific data (username, groups, hostname, monitor config) lives in
  `flake.nix` (hosts attr) and `hosts/default/system.nix`. Shared modules have no host-specific values.
- **State version**: Always set `stateVersion` to the NixOS release (e.g., `"24.05"`).

### Nix Language Style
- **Formatter**: `alejandra` (idempotent). Run `nix fmt` before committing.
- **Indentation**: 2 spaces.
- **Attribute ordering**: Alphabetical within attribute sets, or logical (imports first).
- **Imports**: Single `imports = []` at top of each module.
- **Package references**: Always `pkgs.<name>`. Avoid `with pkgs;` at top level.
- **Quotes**: Double quotes for strings; single quotes only where needed.
- **Error handling**: No `|| true` or silent failures. Nix is declarative — fail loudly.

### Naming Conventions
- **Module prefix**: `hyperland.<submodule>` (e.g., `hyperland.hyprland`, `hyperland.waybar`).
- **Option names**: `lowerCamelCase` (matches NixOS convention).
- **File names**: `kebab-case.nix` for modules.
- **Host names**: `default` (single host). Add `workstation`, `laptop`, etc. in `flake.nix`.

### Nixpkgs Usage
- **Package sets**: Always `pkgs.<name>`. No bare package names.
- **Unfree packages**: Set `nixpkgs.config.allowUnfree = true` only in `home.nix` or `system.nix`.
- **Overlays**: Define in `flake.nix` if you need custom packages.

### Module System
- **Module args**: Prefer `{ config, pkgs, lib, ... }` as the function signature.
- **Enable toggles**: Every shared submodule has `hyperland.<name>.enable` option.
- **User info**: Shared via `hyperland.user.<field>` options (defined in `user.nix`).
  Host-specific values set in `flake.nix` (hosts attr) and passed to `hosts/<name>/system.nix`.

### Home Manager
- **User packages**: Add to `home.packages` in `home.nix`, not `environment.systemPackages`.
- **Shell integration**: Use `programs.fish.*Init` for Fish, `programs.starship` for Starship.
- **Secrets**: Never hardcode secrets. Load from `~/.config/secrets/` via shell snippets.

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
   ```

3. Edit `hosts/workstation/system.nix`:
   - Update `hyperland.hyprland.monitorsFile` to your monitor config
   - Update `networking.hostName`

4. Edit `configs/hyprland-monitors.conf` with your monitor setup.

5. Rebuild: `sudo nixos-rebuild switch --flake .#workstation`

## Workflow Tips

- **Before committing**: Run `nix fmt`
- **Debugging**: Use `nix eval .#nixosConfigurations.default.config.services.hyprland.enable`
- **flake.lock**: Commit it for reproducible builds. Update with `nix flake update`
