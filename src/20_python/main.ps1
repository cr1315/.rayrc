## group delegate: 配下のモジュールの main.ps1 を順に読む（bash / zsh の main.sh と同じ意味論。src/common.ps1 を参照）
foreach ($__rayrc_m in @(__rayrc_list_modules main)) {
    __rayrc_module_enter $__rayrc_m
    try { . $__rayrc_m.Script } catch { __rayrc_module_error $_ } finally { __rayrc_module_leave }
}
