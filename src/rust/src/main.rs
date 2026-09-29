// =====================================================================
// MonitorOff - turn off the display without locking or suspending
// ---------------------------------------------------------------------
// Windows: broadcasts WM_SYSCOMMAND / SC_MONITORPOWER through user32.dll.
// Linux:   uses xset on X11 or the compositor's power command on Wayland.
//
// The project intentionally keeps the Rust build dependency-free.
// =====================================================================

#![cfg_attr(all(windows, not(debug_assertions)), windows_subsystem = "windows")]
#![allow(non_snake_case)]

fn main() {
    if let Err(err) = turn_monitor_off() {
        eprintln!("MonitorOff: {err}");
        std::process::exit(1);
    }
}

#[cfg(windows)]
fn turn_monitor_off() -> Result<(), String> {
    windows_impl::turn_monitor_off()
}

#[cfg(target_os = "linux")]
fn turn_monitor_off() -> Result<(), String> {
    linux_impl::turn_monitor_off()
}

#[cfg(not(any(windows, target_os = "linux")))]
fn turn_monitor_off() -> Result<(), String> {
    unsupported_impl::turn_monitor_off()
}

#[cfg(windows)]
mod windows_impl {
    const WM_SYSCOMMAND: u32 = 0x0112;
    const SC_MONITORPOWER: usize = 0xF170;
    const MONITOR_OFF: isize = 2;
    const HWND_BROADCAST: isize = 0xFFFF;
    const SMTO_ABORTIFHUNG: u32 = 0x0002;
    const TIMEOUT_MS: u32 = 1000;

    #[link(name = "user32")]
    extern "system" {
        fn SendMessageTimeoutW(
            hwnd: isize,
            msg: u32,
            wparam: usize,
            lparam: isize,
            flags: u32,
            timeout: u32,
            result: *mut isize,
        ) -> isize;
    }

    pub fn turn_monitor_off() -> Result<(), String> {
        let mut result = 0isize;
        let status = unsafe {
            SendMessageTimeoutW(
                HWND_BROADCAST,
                WM_SYSCOMMAND,
                SC_MONITORPOWER,
                MONITOR_OFF,
                SMTO_ABORTIFHUNG,
                TIMEOUT_MS,
                &mut result,
            )
        };

        if status == 0 {
            Err("Windows did not accept the monitor power broadcast before the timeout".to_string())
        } else {
            Ok(())
        }
    }
}

#[cfg(target_os = "linux")]
mod linux_impl {
    use std::env;
    use std::process::{Command, Stdio};

    pub fn turn_monitor_off() -> Result<(), String> {
        let session_type = env::var("XDG_SESSION_TYPE").unwrap_or_default();
        // Wayland sessions commonly set DISPLAY for XWayland too. Never treat
        // that compatibility display as the physical display's power control.
        if session_type.eq_ignore_ascii_case("wayland")
            || (env::var_os("WAYLAND_DISPLAY").is_some()
                && !session_type.eq_ignore_ascii_case("x11"))
        {
            return turn_off_wayland();
        }

        if session_type.eq_ignore_ascii_case("x11") || env::var_os("DISPLAY").is_some() {
            return turn_off_x11();
        }

        Err("no graphical session detected: DISPLAY and WAYLAND_DISPLAY are both unset".to_string())
    }

    fn turn_off_wayland() -> Result<(), String> {
        let desktop = env::var("XDG_CURRENT_DESKTOP").unwrap_or_default();
        if env::var_os("HYPRLAND_INSTANCE_SIGNATURE").is_some()
            || desktop.split(':').any(|part| part.eq_ignore_ascii_case("Hyprland"))
        {
            return run("hyprctl", &["dispatch", "dpms", "off"]);
        }
        if env::var_os("SWAYSOCK").is_some()
            || desktop.split(':').any(|part| part.eq_ignore_ascii_case("sway"))
        {
            return run("swaymsg", &["output", "*", "power", "off"]);
        }
        Err(format!(
            "unsupported Wayland compositor (XDG_CURRENT_DESKTOP={desktop:?}); supported: Sway and Hyprland"
        ))
    }

    fn turn_off_x11() -> Result<(), String> {
        run("xset", &["dpms", "force", "off"])
    }

    fn run(program: &str, args: &[&str]) -> Result<(), String> {
        let output = Command::new(program)
            .args(args)
            .stdin(Stdio::null())
            .output()
            .map_err(|err| format!("failed to run {program}: {err}. Install {program} and run from the graphical session."))?;

        if output.status.success() {
            return Ok(());
        }

        let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
        if stderr.is_empty() {
            Err(format!("{program} exited with status {}", output.status))
        } else {
            Err(format!("{program} failed: {stderr}"))
        }
    }
}

#[cfg(not(any(windows, target_os = "linux")))]
mod unsupported_impl {
    pub fn turn_monitor_off() -> Result<(), String> {
        Err(format!("unsupported platform: {}", std::env::consts::OS))
    }
}
