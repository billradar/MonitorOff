# MonitorOff —— 关闭显示器

**简体中文** | [English](README.md)

双击一下，立即关闭显示器 —— 不锁屏、不休眠、无控制台窗口。

![平台](https://img.shields.io/badge/platform-Windows-0078D6)
![许可证](https://img.shields.io/badge/license-MIT-blue)
![C#](https://img.shields.io/badge/C%23-.NET%20Framework%204.x-9B4F96)
![Rust](https://img.shields.io/badge/Rust-stable-DEA584)

## 功能特性

- **立即生效** —— 通过与"等待超时自动熄屏"相同的电源管理通道瞬间关闭显示器
- **安全** —— 不锁定工作站、不进入休眠或睡眠，后台任务照常运行
- **易唤醒** —— 移动鼠标或按任意键，屏幕立即恢复
- **便携** —— 单文件可执行程序，内嵌显示器图标（8 种尺寸），拷走即用
- **双实现参考** —— C# 与 Rust 两套等价源码，功能完全一致

## 工作原理

整个工具的核心只有一行 Win32 调用：

```c
SendMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, 2);
```

向系统所有顶层窗口广播显示器电源子命令（`0xF170`），Windows 随即关闭显示器画面，
主机保持正常运行；输入设备一有动作（移动鼠标 / 按键），屏幕自动点亮。

## 使用方法

1. 从 [Releases](../../releases) 页面下载预编译版（任选其一）：
   - `MonitorOff.exe` —— C# 版（x86，约 90KB，需 .NET Framework 4.x）
   - `MonitorOff-rust.exe` —— Rust 版（x64，约 330KB，**零运行时依赖**）
2. 双击运行，屏幕立即关闭；
3. 移动鼠标或按任意键，屏幕恢复。

如需在桌面创建带图标的快捷方式，将 exe 放在项目根目录后双击：

```
scripts\create_shortcut.bat
```

## 从源码编译

两套实现的产物都会嵌入 `assets/MonitorOff.ico`，并复制到项目根目录。

### 方式一：C#（.NET Framework）

**环境要求**

- Windows 7 及以上（32/64 位）
- .NET Framework 4.x —— Windows 7 SP1 起系统自带，无需安装 Visual Studio
  （构建脚本直接调用 Windows 自带的 `csc.exe` 编译器）

```bat
cd src\csharp
build.bat
```

编译时通过 `/win32icon` 开关嵌入图标。

### 方式二：Rust

**环境要求**

- [Rust 工具链](https://rustup.rs)（stable 版，`*-pc-windows-gnu` 或 `*-pc-windows-msvc`）
- 零第三方 crate 依赖 —— 编译过程无需联网

```bat
cd src\rust
build.bat
```

`cargo build --release` 编译出二进制后，由 `scripts/inject_icon.ps1`
（纯 Windows PowerShell 实现，无任何依赖）把图标嵌入 PE 资源。

> **该用哪一版发布？**
> Rust 版为纯原生单文件，**零运行时依赖**（约 330KB，静态链接 CRT）；
> C# 版更小（约 90KB），但目标机器需要 .NET Framework 4.x。
> 正常的 Windows 7+ 系统两者皆可；目标环境是精简系统或情况不明时，优先 Rust 版。

## 项目结构

```
MonitorOff/
├── assets/
│   └── MonitorOff.ico          # 显示器图标，8 种尺寸（16–256px）
├── scripts/
│   ├── create_shortcut.bat     # 一键创建带图标的桌面快捷方式
│   └── inject_icon.ps1         # 将 .ico 嵌入 PE 文件资源（Win32 资源更新）
├── src/
│   ├── csharp/                 # C# 实现
│   │   ├── MonitorOff.cs
│   │   └── build.bat
│   └── rust/                   # Rust 实现（零 crate 依赖）
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
- `SendMessage(HWND_BROADCAST, ...)` 为同步调用：个别顶层窗口无响应时，
  进程会存活至广播完成，这是 Windows 的标准行为，与原始工具一致。

## 许可证

[MIT](LICENSE)

