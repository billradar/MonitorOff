@echo off
rem ============================================================
rem  MonitorOff - Rust build (zero external crates)
rem  Requires: Rust toolchain from https://rustup.rs
rem  Output goes to project root.
rem ============================================================
setlocal
cd /d "%~dp0"

where cargo >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Rust toolchain not found. Install from https://rustup.rs
    pause
    exit /b 1
)

call cargo build --release
if errorlevel 1 (
    echo [FAILED] cargo build error.
    pause
    exit /b 1
)

copy /y "target\release\MonitorOff.exe" "MonitorOff.exe" >nul

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\..\scripts\inject_icon.ps1" -Exe "%~dp0MonitorOff.exe"
if errorlevel 1 (
    echo [FAILED] icon embed error.
    pause
    exit /b 1
)

copy /y "%~dp0MonitorOff.exe" "%~dp0..\..\MonitorOff.exe" >nul
echo [OK] Built and copied to project root.
pause