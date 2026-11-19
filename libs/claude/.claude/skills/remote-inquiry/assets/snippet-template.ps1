# 情報聞き込みの、ハブ（Windows の PowerShell）で貼るコマンドの並びのひな形。
# <...> をすべて実際の値に置き換えてから、ユーザーに渡す。変数は使わない（1 行ずつ単独で貼り直せるように）。
#
#   <A>       このセッション（スポーク A）の SSH のエイリアス
#   <B>       調べる先（スポーク B）の SSH のエイリアス
#   <script>  A の /tmp に置いたスクリプトのファイル名（例: check-xxx.sh）
#   <result>  結果のファイル名。日時を先頭に置き、区切りはすべて _（例: 20250101_120000_check_xxx.txt。名前の順が時刻の順になるように）
#   <dest>    結果を戻す、A 上の Git 管理外のフォルダの絶対パス（例: /home/<user>/<repo>/logs/）
#   <env>     B で付ける環境変数（例: SKIP_KEYS=1 ENVS=stg）。要らなければ消す
#
# ssh / scp ではなく ssh.exe / scp.exe と書く（ssh を独自の関数・エイリアスで包んでいても、OpenSSH の本体が呼ばれるように）。
# スクリプトが複数なら、1〜2 行目と 6〜7 行目を、ファイルごとに 1 行ずつ増やす。

scp.exe <A>:/tmp/<script> $env:TEMP\
scp.exe $env:TEMP\<script> <B>:
ssh.exe <B> "<env> OUT=<result> bash <script>"
scp.exe <B>:<result> $env:TEMP\
scp.exe $env:TEMP\<result> <A>:<dest>
ssh.exe <B> "rm -f <script> <result>"
Remove-Item $env:TEMP\<script>, $env:TEMP\<result>
