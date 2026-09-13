# MonitorOff

[简体中文](README.zh-CN.md) | **English**

Turn off your monitor with one double-click — no sleep, no lock screen, no console window.

![Platform](https://img.shields.io/badge/platform-Windows-0078D6)
![License](https://img.shields.io/badge/license-MIT-blue)
![C#](https://img.shields.io/badge/C%23-.NET%20Framework%204.x-9B4F96)
![Rust](https://img.shields.io/badge/Rust-stable-DEA584)

## Features

- **Instant** — turns off the display immediately, using the same power-management channel as the "turn display off after timeout" setting
- **Safe** — does not lock the workstation, does not hibernate or sleep; background tasks keep running
- **Wake-friendly** — move the mouse or press any key and the screen comes back
- **Portable** — single-file executable with an embedded monitor icon (8 sizes)
- **Two reference implementations** — C# and Rust, functionally identical

## How It Works

The whole tool boils down to a single Win32 call:

```c
SendMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, 2);
```

This broadcasts the monitor-power system command (`0xF170`) to all top-level windows; Windows powers off the display while the machine keeps running. Input (mouse move / key press) restores it.

## Usage

1. Download `MonitorOff.exe` from the [Releases](../../releases) page (prebuilt x86 build, .NET Framework 4.x).
2. Double-click it — the screen turns off instantly.
3. Move the mouse or press any key to turn it back on.

To create a desktop shortcut (with the monitor icon), place the exe in the project root and double-click:

```
scripts\create_shortcut.bat
```

## Build from Source

Both implementations embed `assets/MonitorOff.ico` and copy the result to the project root.

### Option 1 — C# (.NET Framework)

**Requirements**

- Windows 7 or later (32/64-bit)
- .NET Framework 4.x — preinstalled on Windows 7 SP1 and later; no Visual Studio needed (the build uses the `csc.exe` shipped with Windows)

```bat
cd src\csharp
build.bat
```

The icon is embedded at compile time via the `/win32icon` switch.

### Option 2 — Rust

**Requirements**

- [Rust toolchain](https://rustup.rs) (stable; `*-pc-windows-gnu` or `*-pc-windows-msvc` host)
- No external crates — the build needs no network access

```bat
cd src\rust
build.bat
```

`cargo build --release` produces the binary, then `scripts/inject_icon.ps1` (plain Windows PowerShell, no dependencies) embeds the icon into the PE resources.

> **Which one should I ship?**
> The Rust build is a fully native binary with **no runtime dependencies** (~330 KB, static CRT).
> The C# build is smaller (~90 KB) but requires .NET Framework 4.x on the target machine.
> On any standard Windows 7+ system both work; prefer Rust for stripped-down or unknown environments.

## Project Structure

```
MonitorOff/
├── assets/
│   └── MonitorOff.ico          # Monitor icon, 8 sizes (16–256 px)
├── scripts/
│   ├── create_shortcut.bat     # One-click desktop shortcut with icon
│   └── inject_icon.ps1         # Embed an .ico into a PE file (Win32 resource update)
├── src/
│   ├── csharp/                 # C# implementation
│   │   ├── MonitorOff.cs
│   │   └── build.bat
│   └── rust/                   # Rust implementation (zero crates)
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
- `SendMessage(HWND_BROADCAST, ...)` is synchronous: if some top-level window is hung, the process stays alive until the broadcast completes. This is standard Windows behavior and matches the original tool.

## License

[MIT](LICENSE)
