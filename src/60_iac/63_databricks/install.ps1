# databricks CLI は Scoop の extras bucket にある（databricks-cli）
# main は移植しない: bash / zsh の main は ~/.databricksenv（sh の構文）を source するだけで、PowerShell では読めない
__rayrc_scoop_install databricks-cli -Bucket extras
