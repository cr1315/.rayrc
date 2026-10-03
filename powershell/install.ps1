######################################################################
#
# Bootstrap .rayrc into the PowerShell profile (idempotent)
#
#   - managed block (between markers) exists -> replaced in place
#   - legacy unmarked block exists           -> migrated in place
#   - neither                                -> appended to the end
#   - duplicates                             -> collapsed into the first
#   - nothing changed                        -> profile is not touched
#
# TODO: delegate to each module's install.ps1 once they are stable
#
######################################################################
[CmdletBinding()]
param(
    [string]$ProfilePath = $PROFILE.CurrentUserCurrentHost
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ProfilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ProfilePath)

######################################################################
# block definition
######################################################################
$beginMarker = '## >>> rayrc bootstrap >>>'
$endMarker   = '## <<< rayrc bootstrap <<<'

## single-quoted on purpose: $env:USERPROFILE must be expanded at profile load time
$blockLines = @(
    $beginMarker
    '######################################################################'
    '## BOOTSTRAP my .rayrc (managed by .rayrc/powershell/install.ps1)'
    '######################################################################'
    'if (Test-Path "$env:USERPROFILE/.rayrc/powershell/main.ps1") {'
    '  . "$env:USERPROFILE/.rayrc/powershell/main.ps1"'
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
    Write-Host "[rayrc] profile already up to date: $ProfilePath"
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
