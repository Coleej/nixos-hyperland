# NixOS Hyperland Configuration

A flake-based NixOS system configuration with **Hyprland** (Wayland compositor),
**Home Manager** for user-level dotfiles and packages, and a modular structure designed
for easy multi-host support.

---

## Table of Contents

1. [Quickstart: From ISO to Running System](#1-quickstart-from-iso-to-running-system)
2. [Daily Workflow](#2-daily-workflow)
3. [Repository Structure](#3-repository-structure)
4. [Architecture](#4-architecture)
5. [Key Modules](#5-key-modules)
6. [Configuration Reference](#6-configuration-reference)
7. [Adding a New Host](#7-adding-a-new-host)
8. [Home Manager vs System Packages](#8-home-manager-vs-system-packages)
9. [Common Tasks](#9-common-tasks)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Quickstart: From ISO to Running System

### 1.1 Boot the NixOS Installer

Download the minimal NixOS installer ISO from [nixos.org/download](https://nixos.org/download.html) and boot it.

### 1.2 Partition Your Disk

Assuming a single-disk setup with UEFI:

```bash
# Identify your disk
lsblk

# Partition the disk (replace /dev/sda with your disk)
sudo fdisk /dev/sda

# Create partitions:
#   /dev/sda1  - Linux filesystem (root), minimum 30GB recommended
#   /dev/sda2  - EFI boot partition, 512MB
#   /dev/sda3  - Linux swap (optional), 8-16GB
```

Or use `cfdisk` or `parted` for a more interactive experience:

```bash
sudo cfdisk /dev/sda
```

Format the partitions:

```bash
sudo mkfs.ext4 -L nixos /dev/sda1
sudo mkfs.vfat -F 32 -n boot /dev/sda2
sudo mkswap -L swap /dev/sda3
sudo swapon /dev/sda3
```

Mount them:

```bash
sudo mount /dev/sda1 /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/sda2 /mnt/boot
```

### 1.3 Generate Initial NixOS Config (Optional but Recommended)

```bash
sudo nixos-generate-config --root /mnt --dir /mnt/etc/nixos
```

Then copy the generated `hardware-configuration.nix` into this repo:

```bash
# On the live system, clone or copy your config into /mnt/etc/nixos/
cp -r /path/to/nixos-hyperland /mnt/etc/nixos/
```

### 1.4 Edit the Configuration

At minimum, edit these files **before building**:

**`hosts/default/hardware-configuration.nix`** — update the root and boot device:
```nix
fileSystems."/" = {
  device = "/dev/sda1";   # Your root partition
  fsType = "ext4";
};

fileSystems."/boot" = {
  device = "/dev/sda2";   # Your EFI partition
  fsType = "vfat";
};
```

**`configs/hyprland-monitors.conf`** — configure your display:
```conf
# Example single monitor (replace with your actual monitor name and resolution)
monitor=DP-1,2560x1440@144,0x0,1

# Example dual monitor
# monitor=DP-1,2560x1440@144,0x0,1
# monitor=HDMI-A-1,1920x1080@60,2560x0,1
```

**`wallpapers/default.jpg`** — replace with your wallpaper (any image format).

### 1.5 Build and Install

```bash
cd /mnt/etc/nixos

# Dry-run first to catch any errors
sudo nixos-rebuild dry-activate --flake .#default

# If dry-run succeeds, install
sudo nixos-rebuild switch --flake .#default
```

### 1.6 Post-Install

Reboot. If using GDM, select **Hyprland** from the session picker on the login screen.

### 1.7 Apply Home Manager Separately (Recommended)

Home Manager can be updated independently of the system:

```bash
home-manager switch --flake .#default
```

---

## 2. Daily Workflow

### Rebuild the system

```bash
cd ~/Projects/Nix/nixos-hyperland
sudo nixos-rebuild switch --flake .#default
```

### Update Home Manager only (faster, no system restart needed)

```bash
home-manager switch --flake .#default
```

### Update flake inputs (nixpkgs, home-manager, hyprland)

```bash
nix flake update
```

Then rebuild to apply the updates.

### Format all .nix files

```bash
nix fmt
```

---

## 3. Repository Structure

```
nixos-hyperland/
├── flake.nix                       # Flake definition — inputs, outputs, hosts
├── flake.lock                      # Locked versions of all flake inputs
│
├── hosts/                          # Per-host NixOS configurations
│   └── default/
│       ├── system.nix              # System config for this host
│       └── hardware-configuration.nix  # Kernel modules, filesystem layout (from nixos-generate-config)
│
├── modules/shared/                 # Reusable NixOS module library
│   ├── default.nix                 # Master module — imports all submodules
│   ├── user.nix                    # User creation and group management
│   ├── desktop.nix                 # Display manager, portals, fonts, session vars
│   ├── hyprland.nix                # Hyprland + hyprpaper/hyprlock/hypridle
│   ├── waybar.nix                  # Waybar + waybar scripts install
│   ├── shell.nix                   # Fish + Oh My Posh + Atuin
│   ├── services.nix                # PipeWire, flatpak, polkit, blueman
│   ├── system.nix                  # Kernel, zram, fstrim, Nix GC
│   └── packages.nix                # Shared package groups (base, desktop, dev)
│
├── configs/                        # Shared dotfile configurations
│   ├── hyprland-base.conf          # Hyprland base config (keybindings, animations, env)
│   ├── hyprland-default.conf       # Sources base + local config
│   ├── hyprland-monitors.conf      # Per-host monitor setup (EDIT THIS)
│   ├── hyprpaper-default.conf      # Hyprpaper wallpaper config
│   ├── hyprlock-default.conf       # Lock screen with blur + wallpaper
│   ├── hypridle-default.conf       # Idle timeout → dpms off → lock
│   └── waybar/
│       ├── config.json             # Waybar module configuration
│       └── style.css               # Waybar CSS (cyberpunk theme)
│
├── scripts/
│   ├── hyprland/
│   │   └── brightness.sh           # Backlight/DDC brightness control
│   ├── waybar/
│   │   ├── waybar-dunst.sh         # Waybar: notification daemon toggle
│   │   ├── waybar-mpris.sh         # Waybar: media player info
│   │   └── waybar-public-ip.sh     # Waybar: public IP address
│   └── rofi-brightness.sh          # Standalone brightness menu
│
├── wallpapers/
│   └── default.jpg                 # Placeholder wallpaper (replace with yours)
│
├── home.nix                        # Home Manager user config
│                                      (packages, shell, starship, session vars)
│
└── AGENTS.md                       # Instructions for AI coding agents
```

---

## 4. Architecture

### 4.1 The Flake

`flake.nix` defines all inputs and outputs. It registers per-host configurations
by adding entries to the `hosts` attribute set. Each host gets its own `nixosSystem`
derivation.

### 4.2 NixOS Modules vs Home Manager Modules

There are **two module systems** in this repo:

| Layer | Tool | Configured in | How it works |
|---|---|---|---|
| **NixOS** | `nixos-rebuild` | `hosts/*/system.nix` | Manages system-level things: kernel, services, packages |
| **Home Manager** | `home-manager switch` | `home.nix` | Manages user-level things: home directory dotfiles, user packages, shell config |

Both layers are composed together in the flake. Home Manager runs as a NixOS module
under the hood, but it is evaluated independently for faster iteration.

### 4.3 Shared Modules

The `modules/shared/` directory contains **NixOS modules** that are imported by host
configurations. They expose options under the `hyperland.` prefix (e.g., `hyperland.hyprland`).
Each module can be enabled or disabled independently, and hosts can override any option.

The dependency chain is:

```
flake.nix
  └── nixosConfigurations.default
        ├── hosts/default/system.nix      ← host-specific config
        │     └── imports modules/shared
        │           ├── user.nix          → sets up user account + groups
        │           ├── desktop.nix       → GDM, portals, fonts, env vars
        │           ├── hyprland.nix      → Hyprland WM + systemd user services
        │           ├── waybar.nix        → Waybar + systemd user services
        │           ├── shell.nix         → Fish + Oh My Posh + Atuin
        │           ├── services.nix       → PipeWire, blueman, polkit...
        │           ├── system.nix        → kernel, zram, fstrim, GC
        │           └── packages.nix       → shared package groups
        │
        └── home-manager.users.cody
              └── home.nix                 ← user-level dotfiles + packages
```

### 4.4 Activation Scripts

Some modules write files into `~/.config/` at activation time using `systemd.user.services`
with `Type = "oneshot"` and `RemainAfterExit = true`. This is the pattern used for:

- Copying/symlinking Hyprland, Waybar, and shell config files
- Generating `hyprpaper.conf` and `hyprlock.conf` with the actual wallpaper path
- Installing scripts and setting permissions

This approach avoids the common Nix problem of embedding Nix store paths into config files
that expect plain file paths.

---

## 5. Key Modules

### `modules/shared/hyprland.nix`

Sets up Hyprland and its companion tools. Options:

- `hyperland.hyprland.monitorsFile` — path to your monitor config (e.g., `configs/hyprland-monitors.conf`)
- `hyperland.hyprland.wallpaper` — override the default wallpaper path
- `hyperland.hyprland.hypridleConfig` — path to hypridle.conf (idle → dpms off)
- `hyperland.hyprland.amd.enable` — set AMD Vulkan/Mesa env vars

Creates systemd user services:
- `hyprpaper` — wallpaper daemon (waits for Hyprland socket)
- `hypridle` — idle detection
- `hyprlock` — screen lock on sleep
- `hyperland-setup` — generates configs at boot

### `modules/shared/waybar.nix`

Sets up Waybar with a systemd user service. Options:

- `hyperland.waybar.configPath` — path to waybar JSON config
- `hyperland.waybar.stylePath` — path to CSS
- `hyperland.waybar.scriptsDir` — directory of shell scripts for custom waybar modules

### `modules/shared/shell.nix`

Fish shell with Oh My Posh prompt and Atuin history. Options:

- `hyperland.shell.defaultTerminal` — sets `$TERMINAL` env var (default: `"alacritty"`)
- `hyperland.shell.atuin.enable` — enables Atuin shell history

### `modules/shared/user.nix`

Creates the primary user account. Options:

- `hyperland.user.name` — username
- `hyperland.user.group` — primary group
- `hyperland.user.home` — home directory path
- `hyperland.user.extraGroups` — additional groups (e.g., `["libvirtd" "docker"]`)

### `modules/shared/packages.nix`

Shared package groups. Enable any combination:

- `hyperland.packages.base.enable` — CLI utilities (htop, fzf, bat, eza, ripgrep...)
- `hyperland.packages.desktop.enable` — Wayland helpers (wl-clipboard, brightnessctl, playerctl...)
- `hyperland.packages.dev.enable` — Dev toolchain (git, gcc, cmake, nodejs...)

### `modules/shared/services.nix`

System services. Enable as needed:

- `hyperland.services.openssh.enable` — OpenSSH server

### `modules/shared/desktop.nix`

Desktop environment basics — GDM Wayland, portals, font packages, session variables.
Most options here are always-on for this config.

---

## 6. Configuration Reference

### Environment Variables Set

| Variable | Value | Where |
|---|---|---|
| `NIXOS_OZONE_WL` | `1` | forces Qt/WebKit Wayland |
| `MOZ_ENABLE_WAYLAND` | `1` | Firefox Wayland |
| `QT_QPA_PLATFORM` | `wayland` | Qt apps Wayland |
| `GDK_BACKEND` | `wayland` | GTK apps Wayland |
| `XCURSOR_THEME` | `Bibata-Modern-Ice` | cursor theme |
| `XCURSOR_SIZE` | `24` | cursor size |

### Theming

The config uses the **Tokyo Night** color scheme for GTK theming. Installed fonts include:
FiraCode Nerd Font, Hack, Noto, Ubuntu. Cursor is Bibata-Modern-Ice.

### Hyprland Keybindings

| Binding | Action |
|---|---|
| `SUPER + RETURN` | Open terminal |
| `SUPER + Q` | Close active window |
| `SUPER + M` | Exit Hyprland |
| `SUPER + L` | Lock screen (hyprlock) |
| `SUPER + SPACE` | App launcher (wofi) |
| `SUPER + V` | Toggle float |
| `SUPER + P` | Pseudotile |
| `SUPER + B` | Brightness menu |
| `SUPER + SHIFT + L` | DPMS off |
| `SUPER + SHIFT + 1-0` | Move window to workspace |
| `SUPER + 1-0` | Switch workspace |
| `SUPER + arrow` | Move focus |
| `SUPER + scroll` | Cycle workspaces |
| `Print` | Screenshot (region → clipboard) |
| `SHIFT + Print` | Screenshot (region → file) |
| `XF86Audio*` | Volume control |
| `XF86MonBrightness*` | Brightness control |

---

## 7. Adding a New Host

### Step 1: Add the host entry in `flake.nix`

Add an entry to the `hosts` attrset in `flake.nix`:

```nix
hosts = {
  default = {
    user = { name = "cody"; group = "users"; home = "/home/cody"; extraGroups = [ ]; };
  };
  workstation = {
    user = { name = "alice"; group = "users"; home = "/home/alice"; extraGroups = [ "libvirtd" ]; };
  };
};
```

### Step 2: Create the host directory

```bash
mkdir -p hosts/workstation
cp hosts/default/hardware-configuration.nix hosts/workstation/
```

### Step 3: Edit `hosts/workstation/system.nix`

Copy from `hosts/default/system.nix` and update:
- `hyperland.hyprland.monitorsFile` — point to a new monitor config in `configs/`
- `networking.hostName` — set the hostname
- `hyperland.user` — user info
- `boot.loader.grub.device` — correct boot disk

### Step 4: Create monitor config

```bash
cp configs/hyprland-monitors.conf configs/hyprland-monitors-workstation.conf
# Edit it with your monitor setup
```

### Step 5: Build

```bash
sudo nixos-rebuild switch --flake .#workstation
```

---

## 8. Home Manager vs System Packages

The **rule of thumb**: put packages in `home.packages` unless they must be available at boot
or are needed by system services.

| Category | `home.packages` | `hyperland.packages` / `environment.systemPackages` |
|---|---|---|
| CLI tools you use daily | ✅ | |
| Editors, shells | ✅ | |
| GUI applications | ✅ | |
| Language runtimes (python, node) | ✅ | |
| System services (blueman, polkit) | | ✅ |
| Kernel modules | | ✅ |
| Display server tools | | ✅ |
| Fonts | | ✅ |
| Tools needed at boot | | ✅ |

---

## 9. Common Tasks

### Add a package to the system
Edit `hosts/default/system.nix`:
```nix
hyperland.packages = {
  enable = true;
  base.enable = true;
  desktop.enable = true;
  dev.enable = true;
  extraPackages = with pkgs; [
    my-package
  ];
};
```

### Add a package to your user environment
Edit `home.nix`:
```nix
home.packages = with pkgs; [
  my-package
];
```

### Change the wallpaper
Edit `hosts/default/system.nix`:
```nix
hyperland.hyprland.wallpaper = /path/to/your/wallpaper.jpg;
```

### Add a waybar script
1. Create `scripts/waybar/waybar-my-script.sh`
2. Add it to `configs/waybar/config.json`:
   ```json
   "custom/my_script": {
     "return-type": "json",
     "exec": "~/.config/waybar/scripts/waybar-my-script.sh",
     "interval": 30,
     "format": "{}"
   }
   ```
3. Add `custom/my_script` to a module list in `configs/waybar/config.json`

### Add a Hyprland window rule
Edit `configs/hyprland-base.conf`:
```
windowrule = float, match:class:^(kitty)$
windowrule = opacity 0.9 0.7, match:class:^(floating-window)$
```

### Enable SSH server
Already enabled in `hosts/default/system.nix`. To disable:
```nix
hyperland.services.openssh.enable = false;
```

### Switch to a different kernel
```nix
hyperland.system.kernelPackages = pkgs.linuxPackages_latest;
# or null for default, or pkgs.linuxPackages_hardened, etc.
```

---

## 10. Troubleshooting

### Hyprland fails to start

Check the Hyprland logs:
```bash
cat ~/.config/hypr/hyprland.log
```

Common causes:
- Missing GPU drivers — check `hardware.graphics.enable` and `enable32Bit`
- Monitor config wrong — run `hyprctl monitors` to see detected monitors
- Wayland portal issues — ensure `xdg.portal.enable = true` and `xdg.portal.wlr.enable = true`

### Waybar not showing

```bash
# Check if waybar is running
systemctl --user status waybar

# View waybar errors
waybar --log-errors
```

### Home Manager not applying

```bash
home-manager switch --flake .#default -v
```

### Config evaluates but build fails

Run the full rebuild with `--show-trace`:
```bash
sudo nixos-rebuild switch --flake .#default --show-trace
```

### Check which NixOS/Hyprland/Home Manager versions are in use

```bash
nixos-version
hyprland --version
home-manager --version
```

---

## Credits

This configuration is inspired by [ChrisLAS/hyprvibe](https://github.com/ChrisLAS/hyprvibe),
which provided the modular structure, theming, and waybar setup patterns.
