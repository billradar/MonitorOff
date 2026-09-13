@echo off
rem ============================================================
rem  MonitorOff - C# build (uses csc.exe shipped with Windows)
rem  No Visual Studio required. Output goes to project root.
rem ============================================================
setlocal
cd /d "%~dp0"

set "CSC=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if not exist "%CSC%" set "CSC=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if not exist "%CSC%" (
    echo [ERROR] .NET Framework 4.x csc.exe not found.
    pause
    exit /b 1
)

"%CSC%" /nologo /target:winexe /platform:x86 /optimize+ ^
    /win32icon:"%~dp0..\..\assets\MonitorOff.ico" ^
    /out:"%~dp0MonitorOff.exe" ^
    "%~dp0MonitorOff.cs"

if errorlevel 1 (
    echo [FAILED] build error.
    pause
    exit /b 1
)

copy /y "%~dp0MonitorOff.exe" "%~dp0..\..\MonitorOff.exe" >nul
echo [OK] Built and copied to project root.
pause