# Scoop 本体（D2）。Windows 専用。既に入っていれば何もしない
# installer は子プロセスで実行する（__rayrc_run_installer）。irm | iex のままだと、installer は
# エラー時（「既に入っている」も含む）に break を使い、その break が facade の foreach ごと抜けて、
# 後続のモジュールがすべて飛ばされる
if ($env:OS -ne 'Windows_NT') { return }
if (Get-Command scoop -ErrorAction SilentlyContinue) { return }

try {
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop
}
catch {
  ## GPO などで上書きされている場合は変えられない。Scoop が動くかどうかは installer が判定する
  Write-Warning "[rayrc] could not set ExecutionPolicy: $_"
}

if (-not (__rayrc_run_installer 'https://get.scoop.sh')) {
  Write-Warning "[rayrc] failed to install scoop (it refuses to run as administrator)"
  return
}

## installer がユーザーの PATH に足した shims は、このセッションには入らない。後続の __rayrc_scoop_install のために足す
$__rayrc_scoop_root = if ($env:SCOOP) { $env:SCOOP } else { Join-Path $HOME 'scoop' }
__rayrc_path_prepend (Join-Path $__rayrc_scoop_root 'shims')
