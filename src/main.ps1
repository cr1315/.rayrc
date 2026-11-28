######################################################################
#
# Main
#
######################################################################
# プロファイルからトップレベルで dot-source される。
# 各モジュールの main.ps1 もこのループ（とグループの delegate の同じループ）の中で、
# 関数の外で dot-source するので、モジュールが定義した関数・エイリアス・変数はそのままセッションに残る。
#
# モジュール側の規約:
#   - $__rayrc_ctl_dir / $__rayrc_data_dir / $__rayrc_bin_dir はロード中だけ有効（最後に消す）。
#     キーハンドラなど後から実行される scriptblock の中では参照せず、
#     ロード時に値を確定させる（$env:... に入れる、.GetNewClosure() で閉じ込める）
#   - Windows 専用の処理は $env:OS -eq 'Windows_NT' でガードする
#     （$IsWindows は Windows PowerShell 5.1 では未定義）
. "$PSScriptRoot/common.ps1"

$__rayrc_main_dir = $PSScriptRoot
$__rayrc_libs_dir = Join-Path (Split-Path -Parent $PSScriptRoot) 'libs'
$__rayrc_bin_dir  = Join-Path $__rayrc_libs_dir 'bin'

## facade の状態（bash の __rayrc_delegate_entry の local と同じ役割）
$__rayrc_ctl_dir  = $__rayrc_main_dir
$__rayrc_data_dir = $__rayrc_libs_dir
$__rayrc_install_filter = @()
$__rayrc_stack = [System.Collections.Generic.Stack[object]]::new()

foreach ($__rayrc_m in @(__rayrc_list_modules main)) {
    __rayrc_module_enter $__rayrc_m
    try { . $__rayrc_m.Script } catch { __rayrc_module_error $_ } finally { __rayrc_module_leave }
}

## __rayrc_ はロード中だけのもの（モジュールも、後に残す関数・変数にこの接頭辞を使わない）
Get-ChildItem function:__rayrc_* | Remove-Item
Remove-Variable __rayrc_* -ErrorAction SilentlyContinue

cls
