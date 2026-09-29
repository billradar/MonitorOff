# MonitorOff —— 关闭显示器

**简体中文** | [English](README.md)

双击或执行命令，立即关闭显示器 —— 不锁屏、不休眠。

![平台](https://img.shields.io/badge/platform-Windows%20%7C%20Linux-0078D6)
![许可证](https://img.shields.io/badge/license-MIT-blue)
![C#](https://img.shields.io/badge/C%23-.NET%20Framework%204.x-9B4F96)
![Rust](https://img.shields.io/badge/Rust-stable-DEA584)

## 功能特性

- **立即生效** —— 通过与"等待超时自动熄屏"相同的电源管理通道瞬间关闭显示器
- **安全** —— 不锁定工作站、不进入休眠或睡眠，后台任务照常运行
- **易唤醒** —— 移动鼠标或按任意键，屏幕立即恢复
- **便携** —— 单文件可执行程序；Windows 产物可内嵌显示器图标（8 种尺寸）
- **Rust 跨平台实现** —— Windows 走 Win32，Linux/X11 走 `xset dpms force off`
- **C# 参考实现** —— Windows-only .NET Framework 构建

## 工作原理

Windows 下，Rust 与 C# 版本使用 Win32 关屏广播：

```c
SendMessageTimeout(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, 2,
                   SMTO_ABORTIFHUNG, 1000, NULL);
```

向系统所有顶层窗口广播显示器电源子命令（`0xF170`），Windows 随即关闭显示器画面，
主机保持正常运行；输入设备一有动作（移动鼠标 / 按键），屏幕自动点亮。超时参数可以避免个别无响应窗口导致程序一直等待。

Linux/X11 下，Rust 版本执行：

```sh
xset dpms force off
```

Wayland 没有统一的全局关屏 API，因此本项目不猜测各桌面环境的私有命令。

## 使用方法

1. 从 [Releases](../../releases) 页面下载预编译版（任选其一）：
   - `MonitorOff.exe` —— C# 版（x86，约 90KB，需 .NET Framework 4.x）
   - `MonitorOff-rust.exe` —— Windows Rust 版（x64，**零运行时依赖**）
   - `MonitorOff-linux` —— Linux/X11 Rust 版（需要 `xset`）
2. 运行程序，屏幕立即关闭；
3. 移动鼠标或按任意键，屏幕恢复。

如需在桌面创建带图标的快捷方式，将 exe 放在项目根目录后双击：

```
scripts\create_shortcut.bat
```

## 从源码编译

Windows 产物会嵌入 `assets/MonitorOff.ico`，并复制到项目根目录。

### 方式一：Windows C#（.NET Framework）

**环境要求**

- Windows 7 及以上（32/64 位）
- .NET Framework 4.x —— Windows 7 SP1 起系统自带，无需安装 Visual Studio
  （构建脚本直接调用 Windows 自带的 `csc.exe` 编译器）

```bat
cd src\csharp
build.bat
```

编译时通过 `/win32icon` 开关嵌入图标。

### 方式二：Windows Rust

**环境要求**

- [Rust 工具链](https://rustup.rs)（stable 版，`*-pc-windows-gnu` 或 `*-pc-windows-msvc`）
- 零第三方 crate 依赖 —— 编译过程无需联网

```bat
cd src\rust
build.bat
```

`cargo build --release` 编译出二进制后，由 `scripts/inject_icon.ps1`
（纯 Windows PowerShell 实现，无任何依赖）把图标嵌入 PE 资源。

### 方式三：Linux Rust

**环境要求**

- [Rust 工具链](https://rustup.rs)（stable 版）
- X11 会话，并已安装 `xset`（Debian/Ubuntu 为 `x11-xserver-utils`，Fedora/Arch 类包名通常为 `xorg-xset`）

```sh
cd src/rust
sh build.sh
```

`cargo build --release` 编译出二进制后，`build.sh` 会复制到项目根目录并命名为 `MonitorOff-linux`。

> **该用哪一版发布？**
> Rust 版是主要跨平台实现；
> C# 版更小（约 90KB），但目标机器需要 .NET Framework 4.x。
> Windows 上目标环境是精简系统或情况不明时，优先 Rust 版；Linux 上使用 Rust 版。

## 项目结构

```
MonitorOff/
├── assets/
│   └── MonitorOff.ico          # 显示器图标，8 种尺寸（16–256px）
├── scripts/
│   ├── create_shortcut.bat     # 一键创建带图标的桌面快捷方式
│   └── inject_icon.ps1         # 将 .ico 嵌入 PE 文件资源（Win32 资源更新）
├── src/
│   ├── csharp/                 # Windows C# 实现
│   │   ├── MonitorOff.cs
│   │   └── build.bat
│   └── rust/                   # Rust 跨平台实现（零 crate 依赖）
│       ├── build.bat
│       ├── build.sh
│       ├── Cargo.toml
│       └── src/main.rs
├── CHANGELOG.md
├── LICENSE
└── README.md
```

> 预编译二进制以 **GitHub Release 资产**形式发布（不入仓库）。
> 可从源码自行编译，或下载 Release 后将 `MonitorOff.exe` 放到项目根目录使用。

## 注意事项

- 若杀毒软件误报，可将程序加入白名单 —— 本程序仅发送显示器电源管理指令；
- 程序使用 `SendMessageTimeout(..., SMTO_ABORTIFHUNG, 1000, ...)`，个别顶层窗口无响应时不会导致进程无限等待。
- Linux 支持当前面向 X11；Wayland 请使用桌面环境/合成器自己的命令，或在 X11 会话下运行。

## 许可证

[MIT](LICENSE)

