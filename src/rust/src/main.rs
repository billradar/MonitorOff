// =====================================================================
// MonitorOff - 关闭显示器小工具（Rust 版，零依赖单文件）
// ---------------------------------------------------------------------
// 原理与 C# 版完全一致：
//   通过 FFI 调用 Win32 API，向系统广播 WM_SYSCOMMAND / SC_MONITORPOWER
//   消息，命令显示子系统立即关闭显示器（与"等待超时自动熄屏"同一底层
//   机制）。主机保持正常运行：不锁屏、不休眠、不影响后台任务；
//   移动鼠标或按任意键，显示器自动点亮。
//
// 与 .NET 版的区别：
//   - 编译产物为纯原生代码，不依赖 .NET Framework 运行时；
//   - 体积更小、启动更快；
//   - 本项目零第三方 crate 依赖，仅需官方 Rust 工具链即可编译。
//
// 编译：双击 build.bat（或手工执行 cargo build --release）
// =====================================================================

// 发布版不显示控制台窗口（等价 MSVC /subsystem:windows），
// 调试构建保留控制台便于排错。
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

// ---------------- Win32 消息常量 ----------------

const WM_SYSCOMMAND: u32 = 0x0112;      // 系统命令消息
const SC_MONITORPOWER: usize = 0xF170; // 显示器电源子命令
const MONITOR_OFF: isize = 2;           // lParam：2=关闭 1=低功耗 -1=打开
const HWND_BROADCAST: isize = 0xFFFF;   // 广播给所有顶层窗口

// ---------------- FFI 声明（等价 C# 的 P/Invoke） ----------------

#[link(name = "user32")]
extern "system" {
    /// user32.dll 的 SendMessageW：向窗口发送消息。
    /// x64 下句柄/参数为 8 字节，与 isize/usize 对应。
    fn SendMessageW(
        hwnd: isize,   // 目标窗口句柄（此处为广播句柄）
        msg: u32,      // 消息类型（WM_SYSCOMMAND）
        wparam: usize, // 子命令（SC_MONITORPOWER）
        lparam: isize, // 参数（2 = 关闭）
    ) -> isize;
}

fn main() {
    // 仅关闭显示器画面；系统、网络、后台任务均不受影响
    unsafe {
        SendMessageW(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, MONITOR_OFF);
    }
}