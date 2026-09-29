# =====================================================================
# inject_icon.ps1 - 将 .ico 图标嵌入 exe 的 PE 资源
# 用法：inject_icon.ps1 -Exe <path-to-exe> [-Ico <path-to-ico>]
# Ico 缺省时自动使用 <项目根>\assets\MonitorOff.ico
# 依赖：Windows PowerShell（系统自带），无需安装任何东西
# =====================================================================
param(
    [Parameter(Mandatory = $true)][string]$Exe,
    [string]$Ico
)
$ErrorActionPreference = 'Stop'

Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;

public class IcoInjector {
    [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    static extern IntPtr BeginUpdateResourceW(string fileName, bool deleteExisting);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool UpdateResourceW(IntPtr hUpdate, IntPtr type, IntPtr name, ushort lang, byte[] data, uint cb);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool EndUpdateResourceW(IntPtr hUpdate, bool discard);

    delegate bool EnumNameProc(IntPtr h, IntPtr type, IntPtr name, IntPtr param);
    delegate bool EnumLangProc(IntPtr h, IntPtr type, IntPtr name, ushort lang, IntPtr param);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern IntPtr LoadLibraryExW(string f, IntPtr h, uint flags);
    [DllImport("kernel32.dll")] static extern bool FreeLibrary(IntPtr h);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool EnumResourceNamesW(IntPtr h, IntPtr type, EnumNameProc cb, IntPtr param);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool EnumResourceLanguagesW(IntPtr h, IntPtr type, IntPtr name, EnumLangProc cb, IntPtr param);

    class ResItem { public IntPtr Name; public List<ushort> Langs = new List<ushort>(); }

    static List<ResItem> EnumRes(IntPtr h, IntPtr type) {
        var list = new List<ResItem>();
        EnumNameProc cb = delegate(IntPtr mh, IntPtr t, IntPtr n, IntPtr p) {
            var item = new ResItem { Name = n };
            EnumLangProc lcb = delegate(IntPtr mh2, IntPtr t2, IntPtr n2, ushort lang, IntPtr p2) {
                item.Langs.Add(lang); return true;
            };
            EnumResourceLanguagesW(mh, type, n, lcb, IntPtr.Zero);
            GC.KeepAlive(lcb);
            list.Add(item);
            return true;
        };
        EnumResourceNamesW(h, type, cb, IntPtr.Zero);
        GC.KeepAlive(cb);
        return list;
    }

    public static string InjectIco(string icoPath, string exePath, string backupPath) {
        byte[] ico = File.ReadAllBytes(icoPath);
        if (ico.Length < 6 || BitConverter.ToUInt16(ico, 2) != 1)
            return "FAIL: not a valid .ico file";
        ushort count = BitConverter.ToUInt16(ico, 4);

        // 解析 .ico 目录项，取出每个图像块
        var blobs = new List<byte[]>();
        var sizes = new List<uint>();
        for (int i = 0; i < count; i++) {
            int e = 6 + i * 16;
            // ICONDIRENTRY: dwBytesInRes 在 +8(4字节)，dwImageOffset 在 +12(4字节)
            uint len = BitConverter.ToUInt32(ico, e + 8);
            uint off = BitConverter.ToUInt32(ico, e + 12);
            byte[] blob = new byte[len];
            Array.Copy(ico, (int)off, blob, 0, (int)len);
            blobs.Add(blob);
            sizes.Add(len);
        }

        // 组装 RT_GROUP_ICON 数据（每项 14 字节：前 12 字节 + 2 字节 RT_ICON 资源 ID）
        byte[] group = new byte[6 + count * 14];
        using (MemoryStream ms = new MemoryStream(group)) {
            using (BinaryWriter w = new BinaryWriter(ms)) {
                w.Write((ushort)0); w.Write((ushort)1); w.Write(count);
                for (int i = 0; i < count; i++) {
                    int e = 6 + i * 16;
                    w.Write(ico, e, 12);   // bWidth..wBitCount + dwBytesInRes
                    w.Write((ushort)(i + 1)); // RT_ICON 资源 ID，从 1 起
                }
            }
        }

        if (!string.IsNullOrEmpty(backupPath)) File.Copy(exePath, backupPath, true);

        IntPtr hUpd = BeginUpdateResourceW(exePath, false);
        if (hUpd == IntPtr.Zero) return "FAIL: begin update, err=" + Marshal.GetLastWin32Error();
        bool ok = true;

        // 删除 exe 内已有图标资源（若有）
        IntPtr tgt = LoadLibraryExW(exePath, IntPtr.Zero, 0x2);
        if (tgt != IntPtr.Zero) {
            try {
                foreach (var g in EnumRes(tgt, (IntPtr)14)) foreach (var l in g.Langs) ok &= UpdateResourceW(hUpd, (IntPtr)14, g.Name, l, null, 0);
                foreach (var ic in EnumRes(tgt, (IntPtr)3)) foreach (var l in ic.Langs) ok &= UpdateResourceW(hUpd, (IntPtr)3, ic.Name, l, null, 0);
            } finally { FreeLibrary(tgt); }
        }

        // 写入新图标：RT_ICON(1..n) + RT_GROUP_ICON(ID=1)
        for (int i = 0; i < count; i++)
            ok &= UpdateResourceW(hUpd, (IntPtr)3, (IntPtr)(i + 1), 0, blobs[i], sizes[i]);
        ok &= UpdateResourceW(hUpd, (IntPtr)14, (IntPtr)1, 0, group, (uint)group.Length);

        if (!EndUpdateResourceW(hUpd, false)) return "FAIL: end update, err=" + Marshal.GetLastWin32Error();
        if (!ok) return "FAIL: some UpdateResource calls failed";
        return "OK: embedded " + count + " icon images";
    }
}
'@

# ---- 路径解析 ----
if (-not $Ico) {
    $projectRoot = Split-Path -Parent $PSScriptRoot
    $Ico = Join-Path (Join-Path $projectRoot 'assets') 'MonitorOff.ico'
}
if (-not (Test-Path $Ico)) { throw "Icon not found: $Ico" }
if (-not (Test-Path $Exe)) { throw "Exe not found: $Exe" }
$result = [IcoInjector]::InjectIco($Ico, $Exe, $null)
Write-Output "inject_icon: $result"
if ($result -notlike 'OK:*') { exit 1 }
