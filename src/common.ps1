######################################################################
#
# Facade — bash / zsh の __rayrc_source_facade と同じ意味論（1 階層ずつ、明示 delegate）
#
######################################################################
# delegate（グループの <phase>.ps1。src/main.ps1 のトップレベルも同じ形）:
#
#   foreach ($__rayrc_m in @(__rayrc_list_modules main)) {
#       __rayrc_module_enter $__rayrc_m
#       try { . $__rayrc_m.Script } catch { __rayrc_module_error $_ } finally { __rayrc_module_leave }
#   }
#
# __rayrc_list_modules <phase>
#   $__rayrc_ctl_dir の子ディレクトリを ordinal 順に見て、<phase>.ps1 があり、disabled が無いものを返す。
#   子の中へは自分から降りない。降りるのは、子の <phase>.ps1 自身が上のループを持つ（delegate である）ときだけ。
#   $__rayrc_install_filter が空でなければ、その先頭のトークンに部分一致しない子は飛ばす（"*" はすべてに一致）。
#
# __rayrc_module_enter / __rayrc_module_leave
#   bash の facade が 1 回の繰り返しごとに行うこと（呼び出し元の状態の退避と復元、
#   __rayrc_module_common_setup による ctl / data dir の設定、filter を 1 段消費すること）を、
#   $__rayrc_stack に積んで行う。data dir は各階層の先頭 3 文字を外したもの（${__rayrc_package:3} と同じ）。
#
# なぜループを関数にしないか（I8）:
#   PowerShell では、関数の中で dot-source すると、モジュールが定義した関数・エイリアス・変数が
#   その関数のスコープに閉じ込められる。dot-source は必ずスクリプトのトップレベルで行う。
#   enter / leave は呼び出し元のスコープ（= dot-source している側）の変数を -Scope 1 で書き換える。

function __rayrc_list_modules {
    param([Parameter(Mandatory = $true)][string]$Phase)

    $scanDir = $__rayrc_ctl_dir
    $script  = "$Phase.ps1"
    $token   = if (@($__rayrc_install_filter).Count -gt 0) { @($__rayrc_install_filter)[0] } else { $null }

    [string[]]$names = @(Get-ChildItem -LiteralPath $scanDir -Directory | ForEach-Object { $_.Name })
    [Array]::Sort($names, [StringComparer]::Ordinal)

    foreach ($name in $names) {
        $ctlDir = Join-Path $scanDir $name
        $path   = Join-Path $ctlDir $script
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
        if (Test-Path -LiteralPath (Join-Path $ctlDir 'disabled')) { continue }
        if ($null -ne $token -and $token -ne '*' -and -not $name.Contains($token)) { continue }

        [pscustomobject]@{
            Name    = $name
            Phase   = $Phase
            Script  = $path
            CtlDir  = $ctlDir
            DataDir = Join-Path $__rayrc_data_dir $name.Substring([Math]::Min(3, $name.Length))
        }
    }
}

function __rayrc_module_enter {
    param([Parameter(Mandatory = $true)]$Module)

    $__rayrc_stack.Push([pscustomobject]@{
        CtlDir  = $__rayrc_ctl_dir
        DataDir = $__rayrc_data_dir
        Filter  = @($__rayrc_install_filter)
    })

    if ($Module.Phase -eq 'install') {
        Write-Host ('  ' * ($__rayrc_stack.Count - 1) + "[rayrc] setting up for $($Module.Name.Substring(3)).." )
    }

    if (-not (Test-Path -LiteralPath $Module.DataDir)) {
        New-Item -ItemType Directory -Path $Module.DataDir -Force | Out-Null
    }

    Set-Variable -Scope 1 -Name __rayrc_ctl_dir  -Value $Module.CtlDir
    Set-Variable -Scope 1 -Name __rayrc_data_dir -Value $Module.DataDir
    Set-Variable -Scope 1 -Name __rayrc_install_filter -Value @(@($__rayrc_install_filter) | Select-Object -Skip 1)
}

function __rayrc_module_leave {
    $saved = $__rayrc_stack.Pop()
    Set-Variable -Scope 1 -Name __rayrc_ctl_dir  -Value $saved.CtlDir
    Set-Variable -Scope 1 -Name __rayrc_data_dir -Value $saved.DataDir
    Set-Variable -Scope 1 -Name __rayrc_install_filter -Value $saved.Filter
}

## モジュールが終了エラーを投げても、残りのモジュールは読み続ける（bash の source と同じ）
function __rayrc_module_error {
    param($ErrorRecord)
    Write-Warning "[rayrc] $($ErrorRecord.InvocationInfo.ScriptName): $ErrorRecord"
}

######################################################################
#
# Helpers（main.ps1 / install.ps1 のどちらからでも使える。読み込みの最後に __rayrc_* ごと消える）
#
######################################################################

## __rayrc_path_prepend <dir>: PATH の先頭に足す。既にあれば何もしない（冪等）
function __rayrc_path_prepend {
    param([Parameter(Mandatory = $true)][string]$Dir)
    $sep = [IO.Path]::PathSeparator
    if (@($env:PATH -split [regex]::Escape($sep)) -notcontains $Dir) {
        $env:PATH = $Dir + $sep + $env:PATH
    }
}

## __rayrc_scoop_install <app> [-Bucket <name>]
##   取得は Scoop に任せる（D2）。Scoop は、既に入っているアプリには警告を出すだけで何もしない
function __rayrc_scoop_install {
    param([Parameter(Mandatory = $true)][string]$App, [string]$Bucket)
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Warning "[rayrc] scoop not found; skipped $App"
        return
    }
    if ($Bucket -and -not (@(scoop bucket list) | Where-Object { $_.Name -eq $Bucket })) {
        scoop bucket add $Bucket | Out-Null
    }
    scoop install $App
}

## __rayrc_run_installer <Url> [-Environment @{ NAME = 'value' }]
##   公式の PowerShell installer（irm <url> | iex で使う前提のもの）を子プロセスで実行し、成否を返す。
##   installer の exit / Set-StrictMode / 変数がこのセッションに漏れない（claude の installer は失敗時に exit する）。
##   -Environment はその子プロセスにだけ渡す。出力は bash の `>&/dev/null` と同じく捨てる
function __rayrc_run_installer {
    param([Parameter(Mandatory = $true)][string]$Url, [hashtable]$Environment = @{})
    $saved = @{}
    foreach ($name in $Environment.Keys) {
        $saved[$name] = [Environment]::GetEnvironmentVariable($name)
        [Environment]::SetEnvironmentVariable($name, [string]$Environment[$name])
    }
    try {
        & (Get-Process -Id $PID).Path -NoProfile -ExecutionPolicy Bypass `
            -Command "Invoke-RestMethod -Uri '$Url' | Invoke-Expression" *> $null
        $LASTEXITCODE -eq 0
    }
    finally {
        foreach ($name in $saved.Keys) {
            [Environment]::SetEnvironmentVariable($name, $saved[$name])
        }
    }
}

## __rayrc_link_dir <Link> <Target>
##   <Link> を <Target> への junction にする（Windows 以外の pwsh では symlink。テスト用）。
##   既に <Target> を指していれば何もしない。rayrc 以外のものがあれば __rayrc_backup_item で退避する。
##   bash の 70_claude / 20_vim と同じ ad-hoc な退避。uninstall ストーリーで共通の退避 helper に置き換える
function __rayrc_link_dir {
    param([Parameter(Mandatory = $true)][string]$Link, [Parameter(Mandatory = $true)][string]$Target)
    New-Item -ItemType Directory -Force -Path $Target | Out-Null
    $item = Get-Item -LiteralPath $Link -Force -ErrorAction SilentlyContinue
    if ($item) {
        if ($item.LinkType -and @($item.Target)[0] -eq $Target) { return }
        __rayrc_backup_item $Link
    }
    $type = if ($env:OS -eq 'Windows_NT') { 'Junction' } else { 'SymbolicLink' }
    New-Item -ItemType $type -Path $Link -Target $Target | Out-Null
}

## __rayrc_backup_item <Path>: <Path>_rayrc_bkup_<timestamp> へ移す（無ければ何もしない）
function __rayrc_backup_item {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue)) { return }
    $dest = "${Path}_rayrc_bkup_$(Get-Date -Format yyyyMMdd_HHmmss)"
    Move-Item -LiteralPath $Path -Destination $dest
    Write-Host "[rayrc] backed up $Path -> $dest"
}
