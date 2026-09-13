// =====================================================================
// MonitorOff - 关闭显示器小工具（单文件源码）
// ---------------------------------------------------------------------
// 原理：
//   通过 Win32 API 向系统广播 WM_SYSCOMMAND / SC_MONITORPOWER 消息，
//   命令显示子系统立即关闭显示器（与"等待超时自动熄屏"同一底层机制）。
//   主机保持正常运行：不锁屏、不休眠、不影响后台任务；
//   移动鼠标或按任意键，显示器自动点亮。
//
// 编译（无需 Visual Studio，Windows 自带 .NET 编译器，见 build.bat）：
//   %WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe
//       /nologo /target:winexe /platform:x86 /optimize+
//       /win32icon:MonitorOff.ico /out:MonitorOff.exe MonitorOff.cs
// =====================================================================

using System;
using System.Runtime.InteropServices;

namespace MonitorOff
{
    /// <summary>关闭显示器工具入口类。</summary>
    internal static class MonitorOff
    {
        // ---------------- Win32 消息常量 ----------------

        /// <summary>系统命令消息（WM_SYSCOMMAND = 0x0112）。</summary>
        private const uint WM_SYSCOMMAND = 0x0112;

        /// <summary>显示器电源子命令（SC_MONITORPOWER = 0xF170）。</summary>
        private const int SC_MONITORPOWER = 0xF170;

        /// <summary>lParam 参数：2 = 关闭显示器（1 = 低功耗，-1 = 打开）。</summary>
        private const int MONITOR_OFF = 2;

        /// <summary>广播句柄：0xFFFF 表示发送给所有顶层窗口。</summary>
        private static readonly IntPtr HWND_BROADCAST = (IntPtr)0xFFFF;

        // ---------------- P/Invoke 声明 ----------------

        [DllImport("user32.dll")]
        private static extern IntPtr SendMessage(
            IntPtr hWnd,    // 目标窗口句柄（此处为广播句柄）
            uint Msg,       // 消息类型（WM_SYSCOMMAND）
            IntPtr wParam,  // 子命令（SC_MONITORPOWER）
            IntPtr lParam); // 参数（2 = 关闭）

        // ---------------- 程序入口 ----------------

        /// <summary>程序入口：发送关屏命令后立即退出。</summary>
        [STAThread]
        private static void Main()
        {
            // 仅关闭显示器画面；系统、网络、后台任务均不受影响
            SendMessage(
                HWND_BROADCAST,
                WM_SYSCOMMAND,
                (IntPtr)SC_MONITORPOWER,
                (IntPtr)MONITOR_OFF);
        }
    }
}