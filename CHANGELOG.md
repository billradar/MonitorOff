---
AIGC:
  ContentProducer: '001191110102MAD55U9H0F10002'
  ContentPropagator: '001191110102MAD55U9H0F10002'
  Label: '1'
  ProduceID: '30db5da6-bdae-4751-b324-48aa346204fa'
  PropagateID: '30db5da6-bdae-4751-b324-48aa346204fa'
  ReservedCode1: 'bed0b788-9b58-4549-9ef6-b8bb1e49a993'
  ReservedCode2: 'bed0b788-9b58-4549-9ef6-b8bb1e49a993'
---

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-09-13

### Added
- Monitor-off utility: broadcasts `WM_SYSCOMMAND / SC_MONITORPOWER` to turn off the display without locking or sleeping the machine
- Prebuilt x86 binary (`MonitorOff.exe`, .NET Framework 4.x) with embedded monitor icon (8 sizes, 16–256 px), published as a GitHub Release asset
- C# reference implementation (`src/csharp`) — builds with the `csc.exe` bundled with Windows, no Visual Studio required
- Rust reference implementation (`src/rust`) — zero external crates, fully static native binary
- `scripts/create_shortcut.bat` — one-click desktop shortcut with icon
- `scripts/inject_icon.ps1` — embed an `.ico` into PE resources via Win32 resource-update APIs (used by the Rust build)
- Bilingual README (English / 简体中文)