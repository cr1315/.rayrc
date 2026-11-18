@echo off
rem lf previewer for Windows (set by src/10_viewer/48_lf/main.ps1)
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
rem
rem   Files over 1 MiB are not previewed, except formats whose listing reads
rem   only a header or an index (git bundle, zip/7z/rar, plain tar).
rem   No goto/labels: they misbehave in batch files with LF line endings.
setlocal

rem --- size: compare the digit count first, because "if GTR" is 32-bit
set "size=%~z1"
if "%size%"=="" set "size=0"
set "big="
if not "%size:~7%"=="" (set "big=1") else if %size% GTR 1048576 set "big=1"

rem --- kind
set "kind=text"
for %%e in (.zip .jar .war .ear .7z .rar .tar) do if /i "%~x1"=="%%e" set "kind=archive"
for %%e in (.tgz .tbz .tbz2 .txz) do if /i "%~x1"=="%%e" set "kind=tarball"
for %%e in (.gz .bz2 .xz) do if /i "%~x1"=="%%e" for %%n in ("%~n1") do if /i "%%~xn"==".tar" set "kind=tarball"
if /i "%~x1"==".bundle" set "kind=bundle"

rem --- git bundle: a ref list followed by a binary pack. Show only the refs
if "%kind%"=="bundle" for %%i in (git.exe) do if not "%%~$PATH:i"=="" (
    "%%~$PATH:i" bundle list-heads "%~1"
    exit /b
)

rem --- archives: list entries with the built-in bsdtar (Windows 10 1803+).
rem     Full path, so Git for Windows' GNU tar (no zip/7z support) is not picked.
rem     Compressed tarballs have no index: listing decompresses the whole file,
rem     so they obey the size limit like plain files.
set "tar=%SystemRoot%\System32\tar.exe"
if "%kind%"=="tarball" if not defined big set "kind=archive"
if "%kind%"=="archive" if exist "%tar%" (
    "%tar%" -tf "%~1"
    exit /b
)

if defined big (
    echo no preview: larger than 1 MiB ^(%size% bytes^)
    exit /b
)

for %%i in (bat.exe) do if not "%%~$PATH:i"=="" (
    "%%~$PATH:i" --color=always --style=plain --paging=never --wrap=never --line-range=:%3 -- "%~1"
    exit /b
)
type "%~1"
