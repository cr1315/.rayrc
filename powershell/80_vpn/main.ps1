######################################################################
## Cisco Anyconnect custom functions
######################################################################
# function iswfpack {
#   rm *.zip
#   $pwdName = (gi $pwd).name
#   ls -directory | %{Compress-Archive $_.name ($_.name+".zip")}
#   ls -file | Compress-Archive -dest ($pwdName+".zip")
# }

# function restart-anyconnect {
#   cat "C:\Users\taihang.lei\AppData\Local\Cisco\Cisco AnyConnect Secure Mobility Client\connect.txt" | & "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpncli.exe" '-s'
# }
