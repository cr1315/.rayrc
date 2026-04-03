
## ツール使用ルール

- ファイルの変更には可能な限りEditツールまたはWriteツールを使用すること
- sed, awk, perl, python等によるBash経由のファイル変更は**基本禁止**
- ファイルの読み取りにはReadツールを使用し、cat, head, tail, less等のBash経由の読み取りは避けること
- ファイル検索にはGlob、テキスト検索にはGrepツールを使用すること（find, grep等のBashコマンドより優先）
- built-inツールが存在する操作では、常にBashツールよりbuilt-inツールを優先すること
