Set objShell = CreateObject("WScript.Shell")
' 0 はウィンドウを非表示にするというフラグです
' "archlinux" の部分は、あなたのWSLディストリビューション名に合わせてください
objShell.Run "wsl.exe -d archlinux -- bash -lc ""niri""", 0, False
