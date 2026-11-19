######################################################################
#
# Main
#
######################################################################
# プロファイルからトップレベルで dot-source される。
# 各モジュールの main.ps1 もこのループで（関数の外で）dot-source するので、
# モジュールが定義した関数・エイリアス・変数はそのままセッションに残る。
#
# モジュール側の規約:
#   - $__rayrc_ctl_dir / $__rayrc_data_dir はロード中だけ有効（ループの後で消す）。
#     キーハンドラなど後から実行される scriptblock の中では参照せず、
#     ロード時に値を確定させる（$env:... に入れる、.GetNewClosure() で閉じ込める）
#   - Windows 専用の処理は $env:OS -eq 'Windows_NT' でガードする
#     （$IsWindows は Windows PowerShell 5.1 では未定義）
. "$PSScriptRoot/common.ps1"

foreach ($__rayrc_m in (__rayrc_list_modules -Root $PSScriptRoot -LibsRoot (Join-Path (Split-Path -Parent $PSScriptRoot) 'libs') -Phase main)) {
    $__rayrc_ctl_dir  = $__rayrc_m.CtlDir
    $__rayrc_data_dir = $__rayrc_m.DataDir
    . $__rayrc_m.Script
}

Remove-Item function:__rayrc_list_modules
Remove-Variable __rayrc_m, __rayrc_ctl_dir, __rayrc_data_dir -ErrorAction SilentlyContinue

cls
