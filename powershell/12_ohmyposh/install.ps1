# oh-my-posh は Scoop で管理する（既に入っていれば Scoop が警告を出すだけで何もしない）
scoop install oh-my-posh

# # テーマは shell 非依存なので libs/ohmyposh/config で管理する
# # repo にコミット済みのテーマ（手編集）を上書きしないよう、無い時だけコピーする
# $ompConfigDir = [System.IO.Path]::GetFullPath("$PSScriptRoot\..\..\libs\ohmyposh\config")
# $ompTheme = Join-Path $ompConfigDir "catppuccin.omp.json"

# # streaming: 常駐 serve プロセスで描画し、毎プロンプトのプロセス起動コストを除く（v29.22.0+）
# $ompStreamingMs = 100

# if (-not (Test-Path $ompTheme)) {
#     New-Item -ItemType Directory -Force $ompConfigDir | Out-Null

#     # Scoop の manifest が themes.zip を <prefix>\themes に展開している
#     $ompSrc = Join-Path (scoop prefix oh-my-posh) "themes\catppuccin.omp.json"

#     # コピーと同時にトップレベルへ streaming を追加する
#     if (Get-Command jq -ErrorAction SilentlyContinue) {
#         # PowerShell 7.4+ はネイティブコマンドの > でバイト列をそのまま書き出す（文字化けしない）
#         jq --argjson ms $ompStreamingMs '.streaming = $ms' $ompSrc > $ompTheme
#         $ompOk = $LASTEXITCODE -eq 0
#     } else {
#         try {
#             $ompJson = Get-Content -Raw -Encoding utf8 $ompSrc | ConvertFrom-Json
#             $ompJson | Add-Member -NotePropertyName streaming -NotePropertyValue $ompStreamingMs -Force
#             # -Depth 既定値(2)だと深い階層が文字列化されてテーマが壊れる
#             $ompJson | ConvertTo-Json -Depth 100 | Set-Content -Encoding utf8NoBOM $ompTheme
#             $ompOk = $true
#         } catch {
#             $ompOk = $false
#         }
#     }

#     # 中途半端なファイルが残ると次回以降コピーされなくなるので消す
#     if (-not $ompOk) {
#         Remove-Item -Force -ErrorAction SilentlyContinue $ompTheme
#         Write-Warning "failed to setup oh-my-posh theme: $ompTheme"
#     }
# }
# Remove-Variable ompConfigDir, ompTheme, ompStreamingMs, ompSrc, ompJson, ompOk -ErrorAction SilentlyContinue
