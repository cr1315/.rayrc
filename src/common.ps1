######################################################################
#
# Facade
#
######################################################################
# __rayrc_list_modules -Root <ctl dir> -LibsRoot <data dir> -Phase <main|install>
#
# 読み込むモジュールを実行順に列挙する（暗黙再帰。D2'）:
#   子ディレクトリを ordinal 順（バイト順。bash/zsh の LC_ALL=C と同じ）に見て
#     - disabled があれば飛ばす
#     - <Phase>.ps1 があれば {Script, CtlDir, DataDir} を出す（それより下へは降りない）
#     - 無く、NN_* で NN_* のサブディレクトリを持てば、その中へ再帰する
#   DataDir は各階層の先頭 3 文字を外したもの（bash の ${__rayrc_package:3} と同じ写像）
#     例: 10_viewer/22_ohmyposh -> libs/viewer/ohmyposh
#
# dot-source はここではせず、呼び出し側（main.ps1 のトップレベル）で行う。
# PowerShell では関数の中で dot-source すると、モジュールが定義した関数・エイリアス・
# 変数がその関数のスコープに閉じ込められるため（bash の動的スコープ前提の delegate は使えない。I8）。
function __rayrc_list_modules {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$LibsRoot,
        [Parameter(Mandatory = $true)][string]$Phase
    )

    [string[]]$names = @(Get-ChildItem -LiteralPath $Root -Directory | ForEach-Object { $_.Name })
    [Array]::Sort($names, [StringComparer]::Ordinal)

    foreach ($name in $names) {
        $ctlDir = Join-Path $Root $name
        if (Test-Path -LiteralPath (Join-Path $ctlDir 'disabled')) { continue }

        $dataDir = Join-Path $LibsRoot $name.Substring([Math]::Min(3, $name.Length))
        $script = Join-Path $ctlDir "$Phase.ps1"

        if (Test-Path -LiteralPath $script -PathType Leaf) {
            [pscustomobject]@{ Script = $script; CtlDir = $ctlDir; DataDir = $dataDir }
        }
        elseif ($name -match '^[0-9][0-9]_' -and
                @(Get-ChildItem -LiteralPath $ctlDir -Directory | Where-Object { $_.Name -match '^[0-9][0-9]_' }).Count -gt 0) {
            __rayrc_list_modules -Root $ctlDir -LibsRoot $dataDir -Phase $Phase
        }
    }
}
