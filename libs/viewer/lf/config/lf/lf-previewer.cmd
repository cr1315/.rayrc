@echo off
rem lf previewer for Windows (set by powershell/21_lf/main.ps1)
rem
rem   lf-previewer (sh) cannot run on Windows, so this is a minimal substitute.
rem   Written in cmd on purpose: it is spawned on every cursor move, and
rem   starting pwsh each time is far too slow.
rem
rem   args: %1 file, %2 width, %3 height, %4 x, %5 y, %6 mode
rem
rem   Windows has no SIGPIPE, so a previewer is not stopped once the pane is
rem   full. Let bat read only the lines that fit (--line-range).
rem   "%%~$PATH:i" looks bat.exe up in PATH without spawning where.exe.

for %%i in (bat.exe) do if not "%%~$PATH:i"=="" (
    "%%~$PATH:i" --color=always --style=plain --paging=never --wrap=never --line-range=:%3 -- "%~1"
    exit /b
)
type "%~1"
