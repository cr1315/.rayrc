


ls "${PSScriptRoot}" -directory | %{
    if (test-path "$($_.fullname)/main.ps1") {
        . "$($_.fullname)/main.ps1"
    }
}