if (Get-Command pipx -CommandType Application -ErrorAction SilentlyContinue) {
  $env:PIPX_HOME    = Join-Path $__rayrc_data_dir 'run'
  $env:PIPX_BIN_DIR = $__rayrc_bin_dir

  ## argcomplete は pipx と同じ venv に入っている（bash と同じく、その register-python-argcomplete を使う）。
  ## Windows の uv tool の shim は symlink ではなく exe なので、bash のように realpath では辿れない。
  ## venv の場所は uv の公開の設定 UV_TOOL_DIR（20_python/01_uv が設定する）から求める
  $__rayrc_argcomplete = if ($env:UV_TOOL_DIR) {
    Get-ChildItem -Path (Join-Path $env:UV_TOOL_DIR 'pipx') -Recurse -Filter 'register-python-argcomplete*' `
      -ErrorAction SilentlyContinue | Select-Object -First 1
  }
  if ($__rayrc_argcomplete) {
    ## completion is optional: a venv that cannot run (e.g. moved) must not break the profile
    try { & $__rayrc_argcomplete.FullName --shell powershell pipx 2>$null | Out-String | Invoke-Expression } catch { }
  }
}
