# MonitorOff

[简体中文](README.zh-CN.md) | **English**

Turn off your monitor with one double-click/command — no sleep, no lock screen.

![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux-0078D6)
![License](https://img.shields.io/badge/license-MIT-blue)
![C#](https://img.shields.io/badge/C%23-.NET%20Framework%204.x-9B4F96)
![Rust](https://img.shields.io/badge/Rust-stable-DEA584)

## Features

- **Instant** — turns off the display immediately, using the same power-management channel as the "turn display off after timeout" setting
- **Safe** — does not lock the workstation, does not hibernate or sleep; background tasks keep running
- **Wake-friendly** — move the mouse or press any key and the screen comes back
- **Portable** — single-file executable; Windows builds can embed the monitor icon (8 sizes)
- **Cross-platform Rust build** — Windows via Win32; Linux via X11, Sway, or Hyprland
- **C# reference implementation** — Windows-only .NET Framework build

## How It Works

On Windows, the Rust and C# builds use one Win32 monitor-power broadcast:

```c
SendMessageTimeout(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, 2,
                   SMTO_ABORTIFHUNG, 1000, NULL);
```

This broadcasts the monitor-power system command (`0xF170`) to all top-level windows; Windows powers off the display while the machine keeps running. Input (mouse move / key press) restores it. The timeout avoids waiting forever if another top-level window is hung.

On Linux/X11, the Rust build runs:

```sh
xset dpms force off
```

On Wayland, Sway uses `swaymsg output '*' power off`, and Hyprland uses `hyprctl dispatch dpms off`. Other Wayland compositors return an explicit unsupported error; XWayland's `DISPLAY` is never used as a fallback.

## Usage

1. Download a prebuilt binary from the [Releases](../../releases) page:
   - `MonitorOff.exe` — C# build (x86, ~90 KB, requires .NET Framework 4.x)
   - `MonitorOff-rust.exe` — Rust build for Windows (x64, **no runtime dependencies**)
   - `MonitorOff-linux` — Rust build for Linux/X11, Sway, and Hyprland
2. Run it — the screen turns off instantly.
3. Move the mouse or press any key to turn it back on.

To create a desktop shortcut (with the monitor icon), place the exe in the project root and double-click:

```
scripts\create_shortcut.bat
```

## Build from Source

Windows builds embed `assets/MonitorOff.ico` and copy the result to the project root.

### Option 1 — Windows C# (.NET Framework)

**Requirements**

- Windows 7 or later (32/64-bit)
- .NET Framework 4.x — preinstalled on Windows 7 SP1 and later; no Visual Studio needed (the build uses the `csc.exe` shipped with Windows)

```bat
cd src\csharp
build.bat
```

The icon is embedded at compile time via the `/win32icon` switch.

### Option 2 — Windows Rust

**Requirements**

- [Rust toolchain](https://rustup.rs) (stable; `*-pc-windows-gnu` or `*-pc-windows-msvc` host)
- No external crates — the build needs no network access

```bat
cd src\rust
build.bat
```

`cargo build --release` produces the binary, then `scripts/inject_icon.ps1` (plain Windows PowerShell, no dependencies) embeds the icon into the PE resources.

### Option 3 — Linux Rust

**Requirements**

- [Rust toolchain](https://rustup.rs) (stable)
- X11 with `xset` installed (`x11-xserver-utils` on Debian/Ubuntu), or Wayland with Sway (`swaymsg`) or Hyprland (`hyprctl`)

```sh
cd src/rust
sh build.sh
```

`cargo build --release` produces the binary, then `build.sh` copies it to the project root as `MonitorOff-linux`.

> **Which one should I ship?**
> The Rust build is the main cross-platform implementation.
> The C# build is smaller (~90 KB) but requires .NET Framework 4.x on the target machine.
> On Windows, prefer Rust for stripped-down or unknown environments. On Linux, use the Rust build.

## Project Structure

```
MonitorOff/
├── assets/
│   └── MonitorOff.ico          # Monitor icon, 8 sizes (16–256 px)
├── scripts/
│   ├── create_shortcut.bat     # One-click desktop shortcut with icon
│   └── inject_icon.ps1         # Embed an .ico into a PE file (Win32 resource update)
├── src/
│   ├── csharp/                 # Windows C# implementation
│   │   ├── MonitorOff.cs
│   │   └── build.bat
│   └── rust/                   # Cross-platform Rust implementation (zero crates)
│       ├── build.bat
│       ├── build.sh
│       ├── Cargo.toml
│       └── src/main.rs
├── CHANGELOG.md
├── LICENSE
└── README.md
```

> Prebuilt binaries are published as **GitHub Release assets** (not tracked in the repository).
> Either build from source, or download a Release and place `MonitorOff.exe` in the project root.

## Notes

- If your antivirus flags the executable, add it to the whitelist — the program only sends a monitor-power command.
- The app uses `SendMessageTimeout(..., SMTO_ABORTIFHUNG, 1000, ...)` so a hung top-level window cannot keep the process alive indefinitely.
- Wayland support currently covers Sway and Hyprland. Run the program inside your graphical user session, with its session environment available. GNOME, KDE Plasma, and other compositors currently report unsupported.

## License

[MIT](LICENSE)

