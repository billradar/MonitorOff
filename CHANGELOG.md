# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Add Linux/X11 support to the Rust implementation through `xset dpms force off`.
- Add `src/rust/build.sh` to build the Linux Rust binary and copy it to the project root as `MonitorOff-linux`.

### Changed
- Refactor the Rust entry point into platform-specific implementations while keeping the build dependency-free.
- Update documentation to describe Windows and Linux behavior separately.

### Fixed
- Use `SendMessageTimeout(..., SMTO_ABORTIFHUNG, 1000, ...)` in both C# and Rust builds so a hung top-level window cannot keep MonitorOff alive indefinitely.
- Use pointer-sized Win32 resource identifiers in `inject_icon.ps1` to make icon injection interop signatures match the native APIs more closely.

## [1.0.0] - 2026-09-13

### Added
- Monitor-off utility: broadcasts `WM_SYSCOMMAND / SC_MONITORPOWER` to turn off the display without locking or sleeping the machine
- Prebuilt x86 binary (`MonitorOff.exe`, .NET Framework 4.x) with embedded monitor icon (8 sizes, 16–256 px), published as a GitHub Release asset
- C# reference implementation (`src/csharp`) — builds with the `csc.exe` bundled with Windows, no Visual Studio required
- Rust reference implementation (`src/rust`) — zero external crates, fully static native binary
- `scripts/create_shortcut.bat` — one-click desktop shortcut with icon
- `scripts/inject_icon.ps1` — embed an `.ico` into PE resources via Win32 resource-update APIs (used by the Rust build)
- Bilingual README (English / 简体中文)
