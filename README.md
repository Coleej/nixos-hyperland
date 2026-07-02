# NixOS Hyperland Configuration

A flake-based NixOS system configuration with **Hyprland** (Wayland compositor),
**Home Manager** for user-level dotfiles and packages, **sops-nix** for encrypted secrets, and a
modular structure supporting multiple hosts: `default` and `amd-workstation` (Hyprland desktops)
plus `wsl` (headless NixOS-WSL, terminal-only).

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

**`hosts/default/hyprland-monitors.conf`** — configure your display:
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

### Update flake inputs (nixpkgs, home-manager, hyprland, hypr-binds, sops-nix)

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
├── flake.nix                       # Flake definition — inputs (incl. hypr-binds, sops-nix), outputs, hosts
├── flake.lock                      # Locked versions of all flake inputs
│
├── hosts/                          # Per-host NixOS configurations
│   ├── default/
│   │   ├── system.nix              # System config for this host
│   │   ├── hardware-configuration.nix  # Kernel modules, filesystem layout (from nixos-generate-config)
│   │   └── hyprland-monitors.conf  # Per-host monitor setup (EDIT THIS)
│   ├── amd-workstation/
│   │   ├── system.nix              # Same shape, plus hyperland.hyprland.amd.enable + hyperland.gaming.enable
│   │   ├── hardware-configuration.nix
│   │   └── hyprland-monitors.conf
│   └── wsl/
│       └── system.nix              # Headless NixOS-WSL host (no hardware-configuration.nix / bootloader / kernel)
│
├── modules/
│   ├── shared/                     # Reusable NixOS module library — options under `hyperland.*`
│   │   ├── default.nix             # hyperland.enable gate — wires default sub-options
│   │   ├── user.nix                # User creation and group management
│   │   ├── desktop.nix             # Display manager, portals, fonts, session vars
│   │   ├── hyprland.nix            # Hyprland + hyprpaper/hyprlock/hypridle
│   │   ├── waybar.nix              # Waybar systemd service + waybar scripts install
│   │   ├── services.nix            # PipeWire, flatpak, polkit, blueman, gnome-keyring, tlp
│   │   ├── system.nix              # Kernel, zram, fstrim, Nix GC, power management
│   │   ├── packages.nix            # Shared package groups (base, desktop, dev)
│   │   └── gaming.nix              # Steam, Gamescope, gamemode (amd-workstation only)
│   │
│   └── home/                       # Reusable Home Manager module library — plain HM options
│       ├── default.nix             # Desktop HM entrypoint (imports below) + session vars/path
│       ├── packages.nix            # home.packages (CLI + GUI apps: firefox, obsidian, telegram...)
│       ├── shell.nix               # Fish + Starship prompt + fzf + direnv (shared by desktop + WSL)
│       ├── desktop.nix             # GTK theme, alacritty, wofi, hypr-binds; installs configs/* via home.file
│       ├── services.nix            # taskwarrior (taskchampion sync), netrc activation script
│       ├── secrets.nix             # sops age key + secret declarations (desktop)
│       ├── git.nix                 # Git identity + aliases (shared by desktop + WSL)
│       ├── email.nix               # Proton Mail Bridge (IMAP/SMTP)
│       ├── wsl.nix                 # Headless WSL HM entrypoint (imports packages-wsl/shell/git/secrets-wsl/taskwarrior)
│       ├── packages-wsl.nix        # Curated headless CLI/dev packages (no GUI)
│       ├── secrets-wsl.nix         # sops wiring for WSL — only taskchampion_secret
│       └── taskwarrior.nix         # Taskwarrior 3 + Taskchampion sync (secret injected at activation)
│
├── configs/                        # Dotfile configs installed by modules/home/desktop.nix or the hyperland-setup service
│   ├── hyprland-base.conf          # Hyprland base config (keybindings, animations, env, Obsidian special workspace)
│   ├── hyprland-default.conf       # Sources base + local config
│   ├── hyprpaper-default.conf      # Hyprpaper template — __WALLPAPER__ substituted at activation
│   ├── hyprlock-default.conf       # Lock screen template — __WALLPAPER__ substituted at activation
│   ├── hypridle-default.conf       # Idle timeout → dpms off → lock
│   ├── wofi-style.css              # App launcher styling
│   └── waybar/
│       ├── config.json             # Waybar module configuration
│       ├── style.css               # Active waybar theme (currently cyberpunk)
│       └── base.css, cyberpunk.css, catppuccin-*.css  # Selectable theme variants
│
├── scripts/
│   ├── hyprland/
│   │   ├── brightness.sh           # Backlight/DDC brightness control
│   │   └── show-keybindings.sh     # wofi popup listing Hyprland keybindings
│   ├── waybar/
│   │   ├── waybar-dunst.sh         # Waybar: notification daemon toggle
│   │   ├── waybar-mpris.sh         # Waybar: media player info
│   │   └── waybar-public-ip.sh     # Waybar: public IP address
│   └── rofi-brightness.sh          # Standalone brightness menu
│
├── secrets/secrets.yaml            # sops-encrypted secrets (edit with `sops secrets/secrets.yaml`)
├── .sops.yaml                      # age recipient key used to encrypt secrets/secrets.yaml
│
├── wallpapers/
│   └── default.jpg                 # Placeholder wallpaper (replace with yours)
│
├── home.nix                        # Desktop HM entrypoint → modules/home/default.nix (username/homeDirectory/stateVersion)
├── home-wsl.nix                    # WSL HM entrypoint → modules/home/wsl.nix
│
└── AGENTS.md                       # Instructions for AI coding agents
```

---

## 4. Architecture

### 4.1 The Flake

`flake.nix` defines all inputs (`nixpkgs`, `home-manager`, `hyprland`, `hypr-binds`, `sops-nix`)
and outputs. It registers per-host configurations by adding entries to the `hosts` attribute set
(currently `default` and `amd-workstation`). Each host gets its own `nixosSystem` derivation via
`makeHostConfig`, which also wires up `home-manager.users.<name>` and the sops-nix NixOS + Home
Manager modules for that host.

### 4.2 NixOS Modules vs Home Manager Modules

There are **two module systems** in this repo:

| Layer | Tool | Configured in | How it works |
|---|---|---|---|
| **NixOS** | `nixos-rebuild` | `hosts/*/system.nix` → `modules/shared/` | Manages system-level things: kernel, services, packages. Options live under `hyperland.<name>` and each submodule has its own `enable` toggle. |
| **Home Manager** | `home-manager switch` | `home.nix` → `modules/home/` | Manages user-level things: dotfiles, user packages, shell config, secrets. Uses plain `programs.*`/`home.*` — no `hyperland.*` namespace. |

Both layers are composed together in the flake. Home Manager runs as a NixOS module
under the hood, but it is evaluated independently for faster iteration.

### 4.3 Shared Modules

The `modules/shared/` directory contains **NixOS modules** imported by `hosts/<host>/system.nix`.
They expose options under the `hyperland.` prefix (e.g., `hyperland.hyprland`).
Each module can be enabled or disabled independently, and hosts can override any option.

The dependency chain is:

```
flake.nix  (hosts: default, amd-workstation)
  └── makeHostConfig → nixosConfigurations.<host>
        ├── hosts/<host>/system.nix        ← host-specific config, sets hyperland.* options
        │     └── imports modules/shared
        │           ├── default.nix        → hyperland.enable gate + default sub-option wiring
        │           ├── user.nix           → sets up user account + groups
        │           ├── desktop.nix        → GDM, portals, fonts, env vars
        │           ├── hyprland.nix       → Hyprland WM + systemd user services
        │           ├── waybar.nix         → Waybar + systemd user services
        │           ├── services.nix       → PipeWire, blueman, polkit, gnome-keyring, tlp...
        │           ├── system.nix         → kernel, zram, fstrim, GC
        │           ├── packages.nix       → shared package groups
        │           └── gaming.nix         → Steam/Gamescope (amd-workstation only)
        │
        ├── home-manager.nixosModules.home-manager
        │     └── home-manager.users.<name> = home.nix + hypr-binds HM module + sops-nix HM module
        │           └── home.nix → modules/home/default.nix
        │                 ├── packages.nix, shell.nix, desktop.nix, services.nix
        │                 ├── secrets.nix    → sops age key + secrets from secrets/secrets.yaml
        │                 └── git.nix, email.nix
        │
        └── sops-nix.nixosModules.sops       ← system-level secrets (alongside HM-level sops)
```

### 4.4 Config File Installation

Both current hosts set `hyperland.hyprland.useHomeManager = true` and
`hyperland.waybar.useHomeManager = true`, which splits config installation two ways:

- **Static files with no substitution** — `hyprland-base.conf`, `hyprland.conf`,
  `hyprland-monitors.conf`, waybar `config`/`style.css`, `wofi/style.css` — are installed directly
  by Home Manager's `home.file` in `modules/home/desktop.nix` (`force = true` so it overwrites
  whatever a previous non-HM activation left behind).
- **Files needing the wallpaper path substituted in** — `hyprpaper.conf`, `hyprlock.conf` — are
  generated at activation time by the `hyperland-setup` `systemd.user.service`
  (`Type = "oneshot"`, `RemainAfterExit = true`, in `modules/shared/hyprland.nix`), which `sed`s
  `__WALLPAPER__` in the configured template into a real path. `hypridle.conf` and the Hyprland
  helper scripts are also installed by this service regardless of `useHomeManager`, and the
  equivalent `hyperland-waybar-setup` service always installs the waybar scripts directory.
- If a host sets `useHomeManager = false` instead, the oneshot services fall back to symlinking
  the Hyprland/waybar config files themselves rather than deferring to Home Manager. Neither
  current host uses this path.

This split exists because template substitution (wallpaper path) can't happen through a plain
`home.file` symlink, but everything else is simpler to just let Home Manager manage directly.

---

## 5. Key Modules

### `modules/shared/hyprland.nix` (NixOS)

Sets up Hyprland and its companion tools. Options:

- `hyperland.hyprland.useHomeManager` — defer static config file installs to Home Manager (both hosts set this `true`; see [§4.4](#44-config-file-installation))
- `hyperland.hyprland.monitorsFile` — path to this host's monitor config (`hosts/<host>/hyprland-monitors.conf`)
- `hyperland.hyprland.wallpaper` — override the default wallpaper path
- `hyperland.hyprland.hyprpaperTemplate` / `hyprlockTemplate` — templates with a `__WALLPAPER__` placeholder
- `hyperland.hyprland.hypridleConfig` — path to hypridle.conf (idle → dpms off)
- `hyperland.hyprland.scriptsDir` — directory of Hyprland helper scripts to install
- `hyperland.hyprland.amd.enable` — set AMD Vulkan/Mesa env vars (used by `amd-workstation`)

Creates systemd user services:
- `hyprvibe-hyprpaper` — wallpaper daemon (waits for the Hyprland socket to appear)
- `hypridle` — idle detection
- `hyprlock` — screen lock on sleep
- `hyperland-setup` — generates `hyprpaper.conf`/`hyprlock.conf` from templates and installs
  `hypridle.conf` + helper scripts at every activation

### `modules/shared/waybar.nix` (NixOS)

Sets up Waybar with a systemd user service. Options:

- `hyperland.waybar.useHomeManager` — defer static config file installs to Home Manager (both hosts set this `true`)
- `hyperland.waybar.configPath` — path to waybar JSON config
- `hyperland.waybar.stylePath` — path to CSS
- `hyperland.waybar.scriptsDir` — directory of shell scripts for custom waybar modules

Also creates `hyperland-waybar-setup`, which always installs the waybar scripts directory
(and `rofi-brightness.sh` into `~/.local/bin`) regardless of `useHomeManager`.

### `modules/home/shell.nix` (Home Manager)

Fish shell (`programs.fish`) with a Starship prompt (`programs.starship`) and `fzf` fish
integration. Direnv hook and a `activate <venv>` helper for uv-managed Python venvs are wired into
`programs.fish.interactiveShellInit`.

### `modules/home/desktop.nix` (Home Manager)

GTK theming (Adwaita-dark via `gnome-themes-extra`), alacritty terminal config, wofi launcher
settings, `programs.hypr-binds` (the on-screen keybinding cheat-sheet tool), and the `home.file`
entries that install the static Hyprland/waybar/wofi config files (see [§4.4](#44-config-file-installation)). Picks the right
per-host `hyprland-monitors.conf` via an attrset keyed on the `hostName` module arg.

### `modules/shared/user.nix` (NixOS)

Creates the primary user account. Options:

- `hyperland.user.name` — username
- `hyperland.user.group` — primary group
- `hyperland.user.home` — home directory path
- `hyperland.user.extraGroups` — additional groups (e.g., `["libvirtd" "docker"]`)
- `hyperland.user.linger` — keep user services running while logged out (default `true`)

### `modules/shared/packages.nix` (NixOS)

Shared package groups. Enable any combination:

- `hyperland.packages.base.enable` — CLI utilities (htop, btop, bottom, ripgrep, bat, fd, jq...)
- `hyperland.packages.desktop.enable` — Wayland helpers (wl-clipboard, brightnessctl, playerctl...)
- `hyperland.packages.dev.enable` — Dev toolchain (git, gcc, cmake, nodejs...)
- `hyperland.packages.extraPackages` — extra packages appended on top

### `modules/shared/services.nix` (NixOS)

System services. Options:

- `hyperland.services.openssh.enable` — OpenSSH server
- `hyperland.services.tlp.enable` — TLP power management (laptops)

Always-on when the module is enabled: PipeWire (+ ALSA/PulseAudio/JACK compat), flatpak, polkit,
rtkit, udisks2/gvfs/tumbler, blueman, avahi (mDNS), gnome-keyring (with PAM auto-unlock for GDM,
login, and hyprlock), and Evolution.

### `modules/shared/gaming.nix` (NixOS)

`hyperland.gaming.enable` — Steam (+ Gamescope session), gamemode, vulkan-tools, mangohud, and the
firewall ports/interfaces Steam remote play/in-home streaming needs. Enabled on `amd-workstation` only.

### `modules/shared/desktop.nix` (NixOS)

Desktop environment basics — GDM Wayland, portals, font packages, Wayland session env vars.
Most options here are always-on for this config; `hyperland.desktop.fonts.enable` gates font installs.

### `modules/home/secrets.nix` (Home Manager)

sops-nix wiring: age key at `~/.config/sops/age/keys.txt`, default sops file
`secrets/secrets.yaml`, and the secrets it declares (`nextcloud_password`, `taskchampion_secret`).

### `modules/home/services.nix` (Home Manager)

Taskwarrior 3 configured for Taskchampion sync (`taskchampion_secret` written into `taskrc` at
activation), a `~/.netrc` entry for Nextcloud written from `nextcloud_password` at activation, a
`gnome-keyring-daemon` user service, and an hourly `nextcloud-sync` timer running `nextcloudcmd`.

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

GTK theme is **Adwaita-dark** (`gnome-themes-extra`, set via Home Manager's `gtk.theme` in
`modules/home/desktop.nix`), icon theme is **Papirus**, cursor is **Bibata-Modern-Ice**. The
`tokyonight-gtk-theme` package is installed system-wide (`hosts/<host>/system.nix` fonts.packages)
but not currently selected as the active GTK theme. Waybar uses the **cyberpunk** CSS theme
(`configs/waybar/style.css`); alternate variants (`base.css`, `catppuccin-{frappe,latte,macchiato,mocha}.css`)
live alongside it in `configs/waybar/` and can be swapped in via `hyperland.waybar.stylePath`.
Installed fonts include FiraCode Nerd Font, Hack Nerd Font, Noto (+ color emoji), Ubuntu, Font
Awesome, Liberation.

### Hyprland Keybindings

`$MOD` = `SUPER`. Defined in `configs/hyprland-base.conf`.

| Binding | Action |
|---|---|
| `MOD + RETURN` | Open terminal (alacritty) |
| `MOD + SHIFT + RETURN` | Open browser (firefox) |
| `MOD + Q` | Close active window |
| `MOD + M` | Exit Hyprland |
| `MOD + X` | Lock screen (hyprlock) |
| `MOD + SPACE` | App launcher (`wofi --show drun`) |
| `MOD + V` | Toggle float |
| `MOD + P` | Pseudotile |
| `MOD + ALT + J` | Toggle split direction |
| `MOD + SHIFT + O` | DPMS off |
| `MOD + ALT + L` | DPMS on |
| `MOD + ALT + S` | Toggle special workspace `magic` |
| `MOD + SHIFT + S` | Move window to special workspace `magic` |
| `MOD + ALT + O` | Toggle special workspace `obsidian` (Obsidian auto-launches into it hidden at startup) |
| `MOD + TAB` | Show keybinding cheat-sheet (`hypr-binds`) |
| `MOD + SHIFT + 1-0` | Move window to workspace |
| `MOD + 1-0` | Switch workspace |
| `MOD + arrow` / `MOD + hjkl` | Move focus |
| `MOD + SHIFT + hjkl` | Move window |
| `MOD + scroll` | Cycle workspaces |
| `MOD + left-click drag` / `right-click drag` | Move / resize window |
| `Print` | Screenshot (region → clipboard) |
| `SHIFT + Print` | Screenshot (region → file) |
| `XF86Audio*` | Volume control |
| `XF86MonBrightness*` | Brightness control |

---

## 7. Adding a New Host

Two hosts exist today: `default` and `amd-workstation` (the latter also enables
`hyperland.hyprland.amd.enable` and `hyperland.gaming.enable`). To add another:

### Step 1: Add the host entry in `flake.nix`

Add an entry to the `hosts` attrset in `flake.nix`:

```nix
hosts = {
  default = {
    user = { name = "cody"; group = "users"; home = "/home/cody"; extraGroups = [ ]; };
  };
  amd-workstation = {
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
cp hosts/default/hyprland-monitors.conf hosts/workstation/
```

### Step 3: Edit `hosts/workstation/system.nix`

Copy from `hosts/default/system.nix` and update:
- `hyperland.hyprland.monitorsFile` — point to `./hyprland-monitors.conf`
- `networking.hostName` — set the hostname
- `hyperland.user` — user info
- `boot.loader.grub.device` — correct boot disk

### Step 4: Edit the monitor config

```bash
$EDITOR hosts/workstation/hyprland-monitors.conf
```

### Step 5: Register the host in `modules/home/desktop.nix`

Add `workstation = self + /hosts/workstation/hyprland-monitors.conf;` to the `monitorsFile`
attrset — Home Manager throws if the current `hostName` isn't listed there.

### Step 6: Build

```bash
sudo nixos-rebuild switch --flake .#workstation
```

### The `wsl` host (headless NixOS-WSL)

`wsl` is a special case: a headless, terminal-only [NixOS-WSL](https://github.com/nix-community/NixOS-WSL)
host. It does **not** import `modules/shared` (the Hyprland desktop stack) and has **no**
`hardware-configuration.nix` — NixOS-WSL supplies the kernel, bootloader, and root filesystem, so
`boot.kernelPackages` and bootloader options must never be set for it. It runs a minimal Home
Manager profile (`home-wsl.nix` → `modules/home/wsl.nix`): fish + starship, git, a curated CLI/dev
toolchain, and taskwarrior (Taskchampion sync backed by the `taskchampion_secret` sops secret). No
GUI apps, no `hypr-binds`.

The host is wired via two per-host flags in `flake.nix`'s `hosts` attrset: `wsl = true` (adds
`nixos-wsl.nixosModules.default`, drops the `hypr-binds` HM module) and `homeModule = ./home-wsl.nix`.

**First-time deploy (run inside the WSL instance), in order.** This is a **two-phase** deploy
because sops needs the age key under `/home/cody/.config/…`, but `/home/cody` doesn't exist until
the first switch creates the `cody` user (the current instance runs as the default `nixos` user):

1. **Get the flake onto the WSL Linux filesystem.** Clone/copy this repo into the WSL instance's
   ext4 filesystem (e.g. `~/nixos-hyperland` or `/etc/nixos`), **not** under `/mnt/c/...` — Windows
   mounts have broken permissions and poor performance.

2. **Phase 1 — bring up the box without secrets.** Temporarily comment out **both**
   `./secrets-wsl.nix` and `./taskwarrior.nix` in `modules/home/wsl.nix` (drop them together —
   `taskwarrior.nix` reads the sops secret). Then switch, enabling flakes on the CLI (a fresh
   NixOS-WSL install has flakes off, and the in-config `nix.settings.experimental-features` only
   takes effect *after* a successful switch):
   ```bash
   sudo nixos-rebuild switch --flake .#wsl \
     --option experimental-features "nix-command flakes"
   ```
   This creates the `cody` user and `/home/cody` with the minimal headless profile.

3. **Phase 2 — add the key and enable sops.** Place your age private key at
   `/home/cody/.config/sops/age/keys.txt` (owned by `cody`, `chmod 600`), uncomment the two modules
   from step 2, and switch again:
   ```bash
   sudo nixos-rebuild switch --flake .#wsl
   ```

   If you don't want sops/taskwarrior on WSL at all, just leave those two imports out of
   `modules/home/wsl.nix` permanently and stop after phase 1.

> **Note:** switching `wsl.defaultUser` from `nixos` (the NixOS-WSL default) to `cody` creates a
> **new** user and `/home/cody`; anything under the old `/home/nixos` does not migrate.

> **Warning:** don't `sudo mkdir -p /home/cody/.config/...` before phase 1 — `cody` and
> `/home/cody` don't exist yet, so it creates a root-owned `~/.config` that phase 2's sops step
> will then fail to read/write. If you already did this, fix it with
> `sudo chown -R cody:users /home/cody` before phase 2.

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
Edit `modules/home/packages.nix`:
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

### Switch the waybar theme
Point `hyperland.waybar.stylePath` at one of the other CSS files in `configs/waybar/`
(`base.css`, `cyberpunk.css`, `catppuccin-frappe.css`, `catppuccin-latte.css`,
`catppuccin-macchiato.css`, `catppuccin-mocha.css`) in `hosts/<host>/system.nix`.

### Add a Hyprland window rule
Edit `configs/hyprland-base.conf`, following the existing `match:` rule style, e.g.:
```
windowrule = float, match:class kitty
windowrule = workspace special:obsidian silent, match:initial_class obsidian
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
