# lfscp 指示書（scp-git からの作り直し）

Nov 23, 2026 · @Taihang Lei

## 結論と前提の組み替え

全部できる。止める制約は無い。ただし前提を 2 つ入れ替える。

**1. 処理の主体を移す。** scp-git は「lf は選ぶだけ、作るのは lf の終了後」だった。lfscp は「lf の中で作り、終了後は運ぶだけ」。これで q の差し替え（`%` で選択をファイルに書き出す小細工）が丸ごと消え、Windows 側は中身の形式を一切知らない運送屋になる。

**2. 「Git はアーカイブの一種」は半分だけ正しい。** 実際は軸が 2 本ある。何を入れるか（中身の選び方）と、何に入れるか（容器）。同じリポジトリでも `ta` と `tg` は「何をコミットしたか」と「ディスクに何があるか」という別の問いに答える。

| キー | 中身の選び方 | 容器 | 用途 |
| --- | --- | --- | --- |
| `ta` | HEAD のツリー（追跡ファイルのみ、.git なし） | tar.gz | 綺麗なソースの写し |
| `tb` | 全 ref の履歴 | bundle | 履歴ごと持ち帰る |
| `tg` | ディスク上の現物すべて | tar.gz | そのままの状態 |
| `tj` | 同上 | tar.bz2 | tar の `-j` |
| `tx` | 同上 | tar.xz | tar の `-J`（大文字は Shift になるので x） |
| `tz` | 同上 | zip | Windows で直接開く |
| tt | ファイルそのもの（フォルダは不可） | なし（ファイルのまま） | ファイル一つを取ってきたい時 |

キーを足すときは、どちらの軸を動かすのかを先に決める。両軸の直積で全部キーにすると破綻する（git archive を zip で、などは容器の差なのでキーを増やさない）。

## 利用イメージとコマンド仕様（Windows 側）

位置引数は scp と同じ「接続先 → 遠い側の元 → 手元の先」の順にする。実装は HostFilter / StartDir / To に \[Parameter(Position = 0 / 1 / 2)\] を付ける。

```powershell
lfscp [[-HostFilter] <string>] [[-StartDir] <string>] [[-To] <string>] [-RayrcDir <string>] [-KeepRemote]

lfscp ec2-dev                        # リモートの ~ から開始、カレントへ保存
lfscp ec2-dev ~/work C:\tmp\in       # 開始フォルダと保存先を指定
```

名前は両側とも `lfscp`（1 つの機能名）。PowerShell の動詞-名詞の流儀は別名 `scp-lf`（`Set-Alias scp-lf lfscp`）で満たす。Linux 側は実行ファイル `lfscp` そのものを install.sh で libs/bin にリンクする（関数で包まない）。

| 引数 | 既定 | 仕様 |
| --- | --- | --- |
| `-HostFilter` | なし | 今と同じ `Get-RayrcSshHost`。空なら fzf で選ぶ。関数が無ければ値をそのままホスト名に使う |
| `-StartDir` | `~` | `^[A-Za-z0-9~/._-]+$` のみ（PowerShell 5.1 が `"` を消す問題への対策は今のまま） |
| `-To` | `.` | 別名 `-Destination`。存在するフォルダであること |
| `-RayrcDir` | `~/.rayrc` | 同じ検査 |
| `-KeepRemote` | off | リモートのセッションフォルダを残す（ただし GC で 24 時間後に消える） |

リモートの終了コード（`ssh.exe -t` がそのまま返す）で次の動きを決める。

| コード | 意味 | Windows 側 |
| --- | --- | --- |
| 0 | `out/` に 1 件以上ある | 取得へ |
| 2 | 何も作らずに q | 何もしない |
| 1 | リモートのエラー | エラー表示 |
| 126 / 127 | `lfscp` が無い・実行できない | `git pull` を促す |
| 255 | 接続失敗 | エラー表示 |

旧コード 3（対象のリポジトリなし）は廃止。1 件ごとの失敗はその場で lf の画面に出るので、セッション単位では「できたか、空か」しか要らない。

## 全体の流れとセッションフォルダ

&#91;embedded content: lfscp の流れ · 接続 3 回\]

形式の知識は 3 の中に閉じる。Windows が持つのはパスの決定、運搬、片付けだけ。

```
/tmp/lfscp-<user>-<yyyyMMdd-HHmmss>-<乱数4桁>/   (700)
  out/    運ぶもの。完成品だけが入る
  meta/   manifest.tsv と作業中の work/
```

- **パスは Windows が丸ごと決めて `-o` で渡す。** `<user>` は `ssh.exe -G <host>` の `user` 行（取れなければ `$env:USERNAME`）。\[A-Za-z0-9.\_-\] 以外の文字は \_ に置き換える（SSO の user@example のような名前でもリモートの検査を通すため）。ただのラベルなので、リモートのログインユーザーと食い違っても壊れない。scp と rm が同じ文字列を使うので、決める場所は 1 つにする
- **リモートは計算し直さず、検査だけする。** `^/tmp/lfscp-[A-Za-z0-9._-]+$` に合わなければ拒否。`mkdir -m 700`（`-p` なし）で作り、既にあれば失敗させる
- **今の `mkdir -p -m 700` の穴を塞ぐ。** 他のユーザーが先に同名を作っていても黙って成功し、`-m` も効かない。単一ユーザーの EC2 なら実害は小さいが、作り直すついでに直す
- **out と meta を分ける。** 線を越えるのは `out/` だけ。rayrc の control plane / data plane と同じ切り方である。作業中は `meta/work/` に置き、検証が通ったものだけを `mv` で `out/` へ入れる。途中で lf が殺されても、運ばれるのは完成品だけ
- **manifest.tsv** は `名前<TAB>形式<TAB>元の絶対パス`。名前の衝突と置き換えの判断にだけ使う。一覧は `out/` の実物から作る（かごで消したものを数えないため）

## lf セッションとキーマップ

普段の lfrc はそのまま読み、t 系のキーだけをこの起動のときに足す。lfrc は変更しない。

**起動。** `lfscp` は `LFSCP_SESSION`（セッションフォルダ）と `LFSCP_SELF`（自分のフルパス）を export し、今と同じ `XDG_CONFIG_HOME` / `XDG_DATA_HOME` / `TCELL_KEYBOARD_PROTOCOL=legacy` で lf を開く。足すのは `-command` 2 つだけ。

```bash
"$lf_bin" \
    -command "source '${ctl_dir}/session.lfrc'" \
    -command "map go cd '${session}/out'" \
    "$start_dir"
```

`go`（かご＝`out/` へ移動）だけはパスが要るので `-command` で渡す。セッションのパスは検査済みの安全な文字だけなので埋め込んでよい。移動は lf の g 系に揃える。gl は lfrc で /var/log に使っているので go（out）にする。

**session.lfrc（静的ファイル）。**

```
# 既定の t（tag-toggle）を外す。完全一致のキーがあると lf は ta を待たずに t を実行する
map t

# $fx は lfrc の ifs "\n" で改行区切りに割れる。set -f でグロブを止める
cmd lfscp-pack !{{
    set -f
    "$LFSCP_SELF" pack "$1" $fx
}}

map ta :lfscp-pack git-archive; unselect
map tb :lfscp-pack git-bundle; unselect
map tg :lfscp-pack tar-gz; unselect
map tj :lfscp-pack tar-bz2; unselect
map tx :lfscp-pack tar-xz; unselect
map tz :lfscp-pack zip; unselect
map tt :lfscp-pack raw; unselect
map t? !"$LFSCP_SELF" help
```

- **`!` で同期実行する。** 終わるまで待ち、出力を見せてからキー入力で戻る。`&`（非同期）は使わない。作成中に q を押すと、その 1 件が黙って抜け落ちるため。
- **対象は `$fx`。** 選択があればそれ、無ければカーソルの 1 件。作った後に `unselect` して二重に作るのを防ぐ。名前に空白があってもよい。改行入りの名前は扱わない。
- **q は素の quit。** 旧版の q 差し替えと「`$` だと先に quit が走る」問題はまとめて消える。
- **かごは普通のフォルダ。** `go` で入り、要らないものは lf の delete で消し、`''` で元の場所へ戻る。管理用の UI は作らない。lf 自身がそれである。
- 影響範囲は lfscp の起動だけ。普段の lf の `t` は tag-toggle のまま。

## 形式ハンドラーの契約と各形式

共通の手順は `lfscp pack` が持ち、形式ごとの差は `formats/<形式>.sh` の関数だけに閉じる。新しい形式は 1 ファイル足して session.lfrc に 1 行足せば済む。

**pack の手順（全形式共通）。** `lfscp pack <形式> <パス>...`

1. `formats/<形式>.sh` を source する。無ければエラー
2. `__lfscp_fmt_requires` のコマンドが揃っているか確かめる。欠けていれば名前を出して終了 1（`out/` には触れない）
3. パスごとに `__lfscp_fmt_resolve` で元を決める（リポジトリでない等は理由を出して飛ばす）。同じ呼び出しの中で重複を除く
4. 名前を決める：`__lfscp_fmt_name` → 先頭の `.` を外す（raw 以外。展開したフォルダが隠しフォルダになるのを避けるため。旧来の scp グロブ対策という理由はもう無い） → manifest に同じ（形式, 元）があればその古いファイルを置き換え対象にする（その名前は空いているものとして扱う） → 別の元と名前が重なれば `<親>_<名前>`、それでも重なれば `_2`, `_3`
5. `__lfscp_fmt_info`（任意）：ブランチ、未コミットの件数などを表示
6. `__lfscp_fmt_create <元> <作業ファイル>`：作業ファイルは `meta/work/<最終名>`（拡張子付き）。事前に消しておく
7. `__lfscp_fmt_verify <作業ファイル>`（任意）：NG なら消して次へ
8. `mv` で `out/<最終名>` へ（同じファイルシステムなので原子的）。置き換え対象の古いファイルはここで初めて消す（名前が同じなら mv の上書きで済む）。作成や検証に失敗したときは古い方がそのまま残り、運ばれる。manifest を更新
9. `名前  サイズ` を 1 行表示。1 件でも失敗があれば終了 1

共通の部品（リポジトリの割り出し、サイズ表記、未コミットの要約）は `lib.sh` に置き、今の `rayrc-git-bundle` から移す。

| 形式 | キー | 元 | 名前 | 作り方 | 検証 | 注意 |
| --- | --- | --- | --- | --- | --- | --- |
| git-archive | `ta` | リポジトリの最上位（リポジトリのフォルダ・中のサブフォルダ・中のファイルのどれを選んでも） | `<repo>-<短い sha>.tar.gz` | `git -C <top> archive --format=tar.gz --prefix=<stem>/ HEAD` | `gzip -t` | 未コミット・未追跡は入らない（件数を警告）。サブモジュールの中身と LFS の実体も入らない（`.gitmodules` / `filter=lfs` を見て警告） |
| git-bundle | `tb` | リポジトリの最上位 | `<repo>.bundle` | `bundle create --all` | `bundle verify` | 今のロジックをそのまま移す。コミットが無いと失敗 |
| tar-gz | `tg` | パスそのもの（ファイルでもフォルダでも） | `<base>.tar.gz` | `tar -C <親> -czf <作業> -- <base>` | `gzip -t` | GNU tar の終了 1（読み取り中に変化）は警告、2 は失敗 |
| tar-bz2 | `tj` | 同上 | `<base>.tar.bz2` | `-cjf` | `bzip2 -t` | bzip2 が要る |
| tar-xz | `tx` | 同上 | `<base>.tar.xz` | `-cJf` | `xz -t` | xz が要る |
| zip | `tz` | 同上 | `<base>.zip` | `cd <親> && zip -r -q -y <作業> <base>` | `unzip -tq` | zip が無い環境あり → `python3 -m zipfile -c` に退避 |
| raw | `tt` | 通常ファイルだけ。フォルダは理由を出して飛ばす（tg などで包む） | 元の名前のまま（先頭の . も残す） | `cp -pL -- <元> <作業>` | `cmp <元> <作業>` | 容器の軸では「なし」。シンボリックリンクは実体をコピーする。大きいファイルは圧縮しないぶん転送が重い |

細かい落とし穴を 3 つ。

- **zip は既存ファイルに追記する。** 作業ファイルが残っていると前回の中身と混ざる。手順 6 で必ず消す。また拡張子の無い名前には `.zip` を勝手に足すので、作業ファイルは最終名（`.zip` 付き）にする
- **git archive の `--prefix`。** GitHub の `repo-sha/` と同じく 1 段のフォルダに包む。展開先を散らかさないため
- **名前に sha が入る。** 新しいコミット後に `ta` を押し直すと名前が変わるので、名前でなく（形式, 元）で古いものを探して置き換える（手順 4）

## 取得と後片付け

`out/` をフォルダごと、まだ無い名前のステージングへ `scp -r` で運び、そこから保存先へ移す。ワイルドカードを使わない。

```powershell
& scp.exe -r "${sshHost}:$session/out" (Join-Path $destFull ".lfscp-$id")
```

1. **取得。** コピー先が存在しないと scp はそのフォルダを作って `out/` の中身を入れる。リモート側のグロブ展開も、旧版の「`*` が `.` 始まりに一致しない」問題も無くなる。今の「取る前の更新日時と比べて今回の分を割り出す」推測も要らない。ステージングの中身がそのまま今回の分である
2. **移動。** 中身を 1 件ずつ `-To` へ `Move-Item`。同名があれば上書きし、一覧で「上書き」と示す。最後にステージングを消す
3. **失敗時。** scp が失敗したらステージングを消し、数秒待って取り直す（計 3 回まで）。3 回とも失敗したらリモートは残し（`rm` しない）、取り直し用の `scp.exe` コマンドを表示する
4. **後片付け。** 成功時は `finally` で `ssh.exe <host> 'rm -rf -- <session>'`。lf の中で Ctrl-C しても走る
5. **一覧。** 名前・サイズ・上書きの印。`.bundle` だけは今と同じく `git bundle list-heads` で refs の数を出す。ほかの形式は手元で検証し直さない。リモートで検証済みで、転送中の破損は SSH の MAC が弾くので、再検証は何も足さない

**リモートの GC。** 起動モードの最初に、自分の古いセッションを消す。ネットワークが 2 と 4 の間で切れたときの保険である。

```bash
find /tmp -maxdepth 1 -name 'lfscp-*' -user "$(id -u)" -mmin +1440 -exec rm -rf -- {} +
```

**rsync は今はやらない。** 理由は 4 つ。

- 中身はすでに圧縮済みなので `-z` は効かない
- 保存先は毎回まっさらなので差分転送も効かない
- Windows には標準の rsync が無い。cwRsync や MSYS2 の rsync と Windows の OpenSSH の組み合わせはパイプとパスで揉める。リモートにも rsync が要る
- 残る利点は数 GB を不安定な回線で送るときの `--partial`（再開）くらい

その痛みが出たら足す。取得は `Invoke-LfscpFetch` 1 つに閉じておき、差し替えをその関数の中だけの変更にする。

## ファイル配置・移行・コミット計画

lf の部品ではなく lf を使う機能なので、lf と同じ階層に独立モジュール `48_lfscp` を作り、`20_git` と `10_fzf` から移す。`48_lf` には触らない。

```
src/10_viewer/48_lfscp/      # 48_lf と同じ階層の独立モジュール
  lfscp                     # 実行ファイル本体：起動 / pack / help
  install.sh                # libs/bin/lfscp へ ln -snf（70_claude と同じ作法、冪等）
  main.ps1                  # Windows の lfscp と別名 scp-lf
  session.lfrc              # t 系のキー
  lib.sh                    # 名前付け・manifest・リポジトリ解決・サイズ表記
  formats/
    git-archive.sh  git-bundle.sh
    tar-gz.sh  tar-bz2.sh  tar-xz.sh  zip.sh  raw.sh
test/lfscp/lfscp.sh
```

| 種別 | ファイル | 内容 |
| --- | --- | --- |
| 新規 | `48_lfscp/install.sh` | `libs/bin/lfscp` に実体へのリンクを張る。PATH（00\_bin）に乗るので、対話・navi・lf から `lfscp` で呼べる。関数は作らない。`git-bundle-pick` の後継はこのリンクそのもの |
| 新規 | `48_lfscp/main.ps1` | Windows 側の `lfscp` 関数と `Set-Alias scp-lf lfscp`。独立モジュールなので lf.exe の有無に関係なく読まれ、48\_lf の早期 `return` を気にしなくてよい |
| 変更 | `libs/filesearch/navi/cheats/shell.cheat` | `git-bundle-pick` の項を `lfscp` に |
| 削除 | `10_fzf/scp-git.ps1` と `10_fzf/main.ps1` の dot-source | 旧レイアウトへのフォールバック（TODO 2027-Q2）も一緒に消える |
| 削除 | `20_git/rayrc-git-bundle`、`20_git/main.sh` の `git-bundle-pick` と `__RAYRC_GIT_CTL_DIR` |  |
| 削除 | `test/git_bundle/` | `test/lfscp/` に移す |

`lfscp` は `20_git` と同じ深さにあるので、`libs/` の割り出し（`../../..`）は今のまま使える。ただしリンク経由で呼ばれるので、BASH\_SOURCE を readlink -f で実体に解いてから数える（cd -P はフォルダのリンクしか解かない）。Windows の ssh -t はリンクではなく src の実体をフルパスで呼ぶ（\<RayrcDir>/src/10\_viewer/48\_lfscp/lfscp -o \<session> -s \<start>）。非対話では PATH が効かず、install 前の git pull 直後でも動かすため。`Get-RayrcSshHost` は `10_fzf` にあり、`48_lf` より先に読まれる。無ければ `-HostFilter` をそのままホスト名に使う。読み込み順は bash の ls、PowerShell の Ordinal ソートとも 48\_lf → 48\_lfscp。注意が 2 つ：install のフィルターは部分一致なので install.sh lf は 48\_lfscp にも当たる（リンクを張り直すだけで冪等なので実害なし）。common\_setup が空の libs/viewer/lfscp/ を作る（lfscp が見る lf の設定は libs/viewer/lf のまま）。install.zsh は今回は作らない（EC2 は bash。macOS の zsh で要るなら同じ ln の 1 行）。

**コミットの順。** 移動と振る舞いの変更を混ぜない。新しいものを並べて動かしてから古いものを消す。

1. `feat(lfscp): add lfscp with the git-bundle format`：起動モード、pack、session.lfrc、install.sh のリンク、git-bundle 形式（今のロジックの移植）、テスト。旧版はそのまま
2. `feat(lfscp): add git-archive, tar and zip formats`：残りの形式とテスト
3. `feat(lfscp): add the Windows lfscp`：scp-git には触れない
4. 実機確認：EC2 で `git pull` → Windows から `lfscp` で全形式を一通り
5. `refactor: remove scp-git and rayrc-git-bundle`：削除と navi の更新

3 は 1〜2 が EC2 に届いてから使う。新しいパスは `src/` レイアウトにしか無いので、旧版のような 2 段構えのフォールバックは要らない。

## テストと受け入れ条件

lf を使わずに `pack` を直接叩けるのが、この分割のいちばんの見返り。今の `test/git_bundle` と同じく、パスを引数で渡して確かめる。

**自動（`test/lfscp/lfscp.sh`、`LFSCP_SESSION` を一時フォルダに向ける）**

- [ ] 全形式：`out/` に 1 件でき、検証が通り、`meta/work/` に何も残らない
- [ ] git-archive：リポジトリ・サブフォルダ・中のファイルのどれでもリポジトリ全体が `--prefix` の下に入り、同じ呼び出しなら 1 件にまとまる。未コミットがあると警告。リポジトリでないパスは飛ばす
- [ ] 置き換え：2 回目の作成が失敗したら 1 回目の完成品が残る
- [ ] 名前：同じ元を 2 回 → 1 件（置き換え）。別の元で同じ base → `<親>_` 付き。先頭の `.` は外れる（raw は残る）
- [ ] git-archive：コミットを足して押し直す → 古い sha のファイルが消え、新しい 1 件だけ残る
- [ ] zip：2 回作っても項目数が増えない（追記されない）
- [ ] 必要なコマンドが無い（PATH から bzip2 を外す）→ 終了 1、名前を表示、`out/` は無傷
- [ ] セッションのパス：パターン外を拒否。既に存在するフォルダは失敗（`-p` を使っていない）
- [ ] 起動モード（`LFSCP_LF` で偽の lf を渡し、端末は `script` で用意する）：`out/` が空なら終了 2。24 時間より古い自分のセッション（`touch -d`）は GC で消え、他人のものと新しいものは残る

* [ ] raw：ファイルがそのまま入り `cmp` が一致する。フォルダを渡すと飛ばして理由を出す。`.env` のような名前も変わらない
* [ ] 実行ビット：48\_lfscp/lfscp が git ls-files -s で 100755。Windows から commit するなら git update-index --chmod=+x。無いと Windows 側は 126 になる（formats/\*.sh は source するので不要）

**手動（lf と Windows が要る）**

- [ ] `t` → `a` で `ta` に届く（tag-toggle が外れている）。普段の lf では `t` が tag-toggle のまま
- [ ] 空白入りの名前を複数選んで `tg`：1 件ずつできる
- [ ] `!` の出力が見え、キーで戻ると選択が外れている
- [ ] `go` でかごへ入り、lf で 1 件消す → Windows の一覧にも出ない
- [ ] `scp.exe -r` のステージング展開が手元の OpenSSH（`ssh -V`）で期待どおり
- [ ] 同名の上書きで「上書き」と出る。scp 失敗時はリモートが残り、取り直しのコマンドが出る
- [ ] lf の中で Ctrl-C → リモートのセッションが消える

## こちらで決めたこと（違えば直す）

| 項目 | 決めたこと | 理由 |
| --- | --- | --- |
| bundle のキー | `tb` | 音声入力で「TB」が「TP」に化けたと判断。P（pack）の意図なら `tp` に戻す |
| `tz` = zip | 採用 | ただし tar の `-z` は gzip。`tar czf` に慣れた指は `tz` を tar.gz と読む。指が迷うなら zip を別の字へ移す |
| `tx` = tar.xz | 追加 | `-J` は Shift になるので x |
| 手元の同名 | 上書きして印を付ける | 取り直しは新しい方が欲しい場合が多い |
| リモートのコマンド名 | 実行ファイル `lfscp`（libs/bin にリンク。対話用の関数は作らない） | 1 つの名前に 1 つの実体。PATH で呼べるので関数の包みが要らない |
| rsync | 後回し | 取得とその後の節のとおり |
| `tA`（HEAD ＋作業ツリーの変更） | 後回し | `git archive $(git stash create \|\| echo HEAD)` で追跡ファイルの変更まで入る。未追跡は入らない。需要が出たら 1 形式として足す |
| 普段の lf でも t 系を使う | 後回し | ハンドラーは出力先を `LFSCP_SESSION` で受けるので、カレントに出す形で後から流用できる |
| tt とかごへの移動 | tt はファイルそのまま、かごへの移動は go | 移動は lf の g 系（gg / gh / g/ / ge）に揃える。gl は /var/log と重なる |
| `ta` の対象（11/23 確認） | 選んだものが属するリポジトリ全体 | サブパスだけを取る使い方は今は無い。要るようになったら足す |
| 置き換えの順（11/23 確認） | 新しい方が `out/` に入ってから古い方を消す | 2 回目が失敗しても 1 回目の完成品が残る |
| 取得のリトライ（11/23 確認） | 計 3 回 | 全部失敗したらリモートを残してコマンドを表示 |
| lf の差し替え口 | 環境変数 `LFSCP_LF` | 起動モードの自動テスト用。本番では設定しない |
| 起動モードの PATH | `<libs>/bin` を先頭に足す | 非対話の ssh では PATH に無く、lfrc の `lf-previewer` などが見つからないため |
| Windows が呼ぶパス | src の実体（libs/bin のリンクではない） | git pull だけで動く。運用で「install 忘れ」と「配置変更で壊れる」のどちらが多いかを見て再検討。リンクを公開の入口にし、実体へフォールバックする 1 行案もある |
