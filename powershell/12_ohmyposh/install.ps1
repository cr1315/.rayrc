# oh-my-posh は Scoop で管理する（既に入っていれば Scoop が警告を出すだけで何もしない）
scoop install oh-my-posh

# テーマは shell 非依存なので libs/ohmyposh/config で管理する
# repo にコミット済みのテーマ（streaming 追加などの手編集）を上書きしないよう、無い時だけコピー
$ompConfigDir = [System.IO.Path]::GetFullPath("$PSScriptRoot\..\..\libs\ohmyposh\config")
$ompTheme = Join-Path $ompConfigDir "catppuccin.omp.json"
if (-not (Test-Path $ompTheme)) {
    # Scoop の manifest が themes.zip を <prefix>\themes に展開している
    New-Item -ItemType Directory -Force $ompConfigDir | Out-Null
    Copy-Item (Join-Path (scoop prefix oh-my-posh) "themes\catppuccin.omp.json") $ompTheme
}
Remove-Variable ompConfigDir, ompTheme
