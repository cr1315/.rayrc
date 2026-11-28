######################################################################
#
# Install for PowerShell (same order as src/install.sh)
#
#   1. run each module's install.ps1 through the facade (src/common.ps1)
#        -Filter text,bat : one comma-separated token per hierarchy level,
#                           substring match, "*" matches any (= bash --filter)
#   2. bootstrap .rayrc into the PowerShell profile (idempotent)
#        - managed block (between markers) exists -> replaced in place
#        - legacy unmarked block exists           -> migrated in place
#        - neither                                -> appended to the end
#        - duplicates                             -> collapsed into the first
#        - nothing changed                        -> profile is not touched
#
######################################################################
[CmdletBinding()]
param(
    [string[]]$Filter = @(),
    [string]$ProfilePath = $PROFILE.CurrentUserCurrentHost
)

######################################################################
# 1. modules
######################################################################
# Like bash, a failing module is reported and the rest keep going: no StrictMode,
# non-terminating errors continue. The loop stays at the script top level so that
# the module scripts are dot-sourced into this script's scope (I8); everything
# they define ends with this script, as `&` gives it its own scope.
. "$PSScriptRoot/common.ps1"

$__rayrc_main_dir = $PSScriptRoot
$__rayrc_libs_dir = Join-Path (Split-Path -Parent $PSScriptRoot) 'libs'
$__rayrc_bin_dir  = Join-Path $__rayrc_libs_dir 'bin'
if (-not (Test-Path -LiteralPath $__rayrc_bin_dir)) {
    New-Item -ItemType Directory -Force -Path $__rayrc_bin_dir | Out-Null
}

$__rayrc_ctl_dir  = $__rayrc_main_dir
$__rayrc_data_dir = $__rayrc_libs_dir
$__rayrc_install_filter = @($Filter | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
$__rayrc_stack = [System.Collections.Generic.Stack[object]]::new()

$ErrorActionPreference = 'Continue'
Write-Host ''
foreach ($__rayrc_m in @(__rayrc_list_modules install)) {
    __rayrc_module_enter $__rayrc_m
    try { . $__rayrc_m.Script } catch { __rayrc_module_error $_ } finally { __rayrc_module_leave }
}
Write-Host ''

######################################################################
# 2. profile
######################################################################
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ProfilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ProfilePath)

######################################################################
# block definition
######################################################################
$beginMarker = '## >>> rayrc bootstrap >>>'
$endMarker   = '## <<< rayrc bootstrap <<<'

## the absolute path of main.ps1 is resolved now (install time), so the profile follows
## wherever this checkout lives; written as a single-quoted literal (' doubled)
$mainLiteral = "'" + (Join-Path $PSScriptRoot 'main.ps1').Replace("'", "''") + "'"
$blockLines = @(
    $beginMarker
    '######################################################################'
    '## BOOTSTRAP my .rayrc (managed by .rayrc/src/install.ps1)'
    '######################################################################'
    "if (Test-Path -LiteralPath $mainLiteral) {"
    "  . $mainLiteral"
    '}'
    $endMarker
)

$managedPattern = [regex]::new(
    "(?ms)^$([regex]::Escape($beginMarker)).*?^$([regex]::Escape($endMarker))[^\r\n]*")

## the hand-written block before markers were introduced
$legacyPattern = [regex]::new(
    '(?mi)^#{10,}\r?\n## BOOTSTRAP my \.rayrc[ \t]*\r?\n#{10,}\r?\n' +
    'if \(test-path "\$env:USERPROFILE/\.rayrc"\) \{\r?\n[^\r\n]*\r?\n\}[ \t]*')

######################################################################
# read (keep the original encoding; new file gets UTF-8 BOM for Windows PowerShell 5.1)
######################################################################
$content  = ''
$encoding = [Text.UTF8Encoding]::new($true)
if (Test-Path -LiteralPath $ProfilePath) {
    $reader = [IO.StreamReader]::new($ProfilePath, [Text.UTF8Encoding]::new($false), $true)
    try {
        $content  = $reader.ReadToEnd()
        $encoding = $reader.CurrentEncoding
    } finally {
        $reader.Dispose()
    }
}

$nl    = if ($content -match "`r`n") { "`r`n" } elseif ($content -match "`n") { "`n" } else { "`r`n" }
$block = $blockLines -join $nl

######################################################################
# rebuild
######################################################################
$found = @(@($managedPattern.Matches($content)) + @($legacyPattern.Matches($content)) | Sort-Object Index)

if ($found.Count -eq 0) {
    $sep = if ($content.Length -eq 0) { '' } elseif ($content.EndsWith("`n")) { $nl } else { $nl + $nl }
    $newContent = $content + $sep + $block + $nl
} else {
    $sb     = [Text.StringBuilder]::new()
    $cursor = 0
    for ($i = 0; $i -lt $found.Count; $i++) {
        $m = $found[$i]
        [void]$sb.Append($content.Substring($cursor, $m.Index - $cursor))
        $cursor = $m.Index + $m.Length
        if ($i -eq 0) {
            [void]$sb.Append($block)
        } elseif ($content.Substring($cursor) -match '^\r?\n') {
            $cursor += $Matches[0].Length
        }
    }
    [void]$sb.Append($content.Substring($cursor))
    $newContent = $sb.ToString()
}

######################################################################
# write
######################################################################
if ($newContent -ceq $content) {
    return
}

$profileDir = Split-Path -Parent $ProfilePath
if (-not (Test-Path -LiteralPath $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}
if (Test-Path -LiteralPath $ProfilePath) {
    Copy-Item -LiteralPath $ProfilePath -Destination "$ProfilePath.rayrc.bak" -Force
}

[IO.File]::WriteAllText($ProfilePath, $newContent, $encoding)

Write-Host "[rayrc] profile updated: $ProfilePath"
Write-Host "[rayrc] restart PowerShell (or run: . `$PROFILE) to take effect"
