#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"

if ! command -v cargo >/dev/null 2>&1; then
    echo "[ERROR] Rust toolchain not found. Install from https://rustup.rs" >&2
    exit 1
fi

cargo build --release
cp target/release/MonitorOff ../../MonitorOff-linux
echo "[OK] Built and copied to project root: MonitorOff-linux"
