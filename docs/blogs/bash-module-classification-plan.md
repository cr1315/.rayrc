# bash/ モジュール分類・再番号付けプラン

`bash/05_tools/` に CLI ツールが 14 個集まり、今後も増える見込みのため、機能別のグループに分割する。
20 番台以降（`20_python` 〜 `90_misc`）は対象外とし、**00〜19 の範囲だけ**を整理する。

---

## 1. 現状

```
bash/
├── 00_bin/            PATH に libs/bin を追加
├── 05_tools/          ← 全 CLI ツールがここに集中
│   ├── 01_eget/  02_httpie/
│   ├── 06_bat/  06_eza/  06_fd/  06_gdu/  06_jq/  06_lf/  06_navi/
│   ├── 06_rg/   06_shfmt/ 06_stu/ 06_yq/
│   └── 08_delta/
├── 10_bash/  10_sudo/
├── 12_fzf/   12_git/   12_vim/
└── 18_atuin/
```

---

## 2. 番号付けの原則

> **他に依存しないもの・他から依存されるものを若い番号に、他を組み合わせて使うものを大きい番号にする。**

ただし「依存」には 3 種類あり、**読み込み順を本当に縛るのは①と②だけ**である。

| 種類 | 内容 | 順序の制約 |
|------|------|-----------|
| ① インストール時の依存 | ある `install.sh` が、同じセッション中に先にインストールされた別ツールを実行する | **あり**（先にインストールされている必要がある） |
| ② 読み込み時の依存 | `main.sh` がシェルの状態（`PROMPT_COMMAND`、`bind`、alias、環境変数）を設定・上書きする | **あり**（後から設定したものが勝つ） |
| ③ 実行時の依存 | コマンドを実行したときに、別ツールを PATH から呼び出す（例: navi → fzf、fzf のプレビュー → bat） | **なし** |

③に制約がないのは、次の理由による。

- バイナリはすべてフラットな `libs/bin/` に置かれ、`00_bin` がシェル起動時の最初に PATH へ追加する。
- ③の呼び出しはユーザーがコマンドを実行した時点で解決されるので、そのときには全ツールがすでに PATH 上にある。

つまりツール間の依存の大半は③で、順序にはほぼ影響しない。
グループを機能別に分けても、それで壊れる依存はない。③については、上の原則に沿って並べると読みやすくなる、という程度の意味合いになる。

---

## 3. 読み込み順の制約（コード調査結果）

`__rayrc_source_facade` は `ls -1` の順（＝番号順、同番号ならアルファベット順）で source する。

| # | 種類 | 制約 | 根拠 |
|---|------|------|------|
| C1 | ② | `00_bin` < 全モジュール | `libs/bin` を PATH に追加する。以降の `command -v` ガードはこれが前提 |
| C2 | ② | `10_bash` < `12_git` | `10_bash/main.sh:21` の `PROMPT_COMMAND=smile_prompt` を `gitstatus.prompt.sh:122` が**代入で上書き**している |
| C3 | ② | `12_git` < `18_atuin` | atuin は内蔵の bash-preexec で `PROMPT_COMMAND` / DEBUG trap にフックする。git が後だと、`PROMPT_COMMAND=gitstatus_prompt_update`（append ではなく代入）で **atuin のフックが消え、履歴が記録されなくなる** |
| C4 | ② | `12_fzf` < `18_atuin` | **Ctrl-R** を両方が bind する（fzf: `key-bindings.bash`、atuin: `atuin init bash`）。atuin を勝たせるには後に置く |
| C5 | ② | `lf` < `yazi`（将来） | **Ctrl-O** を lf が `bind '"\C-o":"lfcd\C-m"'` で使っている（`06_lf/main.sh:49`）。yazi の cd ラッパーも Ctrl-O に割り当てるなら後に置く |

①（インストール時の依存）は、今のところ存在しない。

- 各 `install.sh` は curl / tar / git などのシステムコマンドしか使っていない。
- 以前は eget が①の基盤だったが、現在は `__rayrc_eget_install` を呼んでいるモジュールはない。

### 主な③（実行時の依存。順序には影響しない）

| 利用する側 | 利用される側 | 箇所 |
|------------|--------------|------|
| fzf（プレビュー、候補一覧） | bat, fd, shfmt | `12_fzf/main.sh` の `FZF_*` 環境変数 |
| navi | fzf | navi は候補選択に fzf を呼び出す。`main.sh` は `NAVI_CONFIG` / `NAVI_PATH` を export するだけ |
| lf（プレビュー） | bat | `libs/tools/lf/config/lf/lf-previewer:15`（`command -v bat` でガード済み） |
| yazi（将来） | fd, rg, fzf, jq など | yazi の検索・プラグイン機能 |
| `10_bash` の `la` / `ll` / `lt` | eza | `command -v eza` で PATH を確認しているだけ |

- **navi は fzf より前（`04_search`）に置いても問題ない**。navi は install も main も fzf に触らず、実行時に PATH 上の fzf を呼ぶだけだからである。
- fzf ↔ git の間に①②の依存はない。唯一の接点は、`gitstatus_prompt_update` がプロンプトごとに `history -a/-c/-r` を実行し、fzf の Ctrl-R に他セッションの履歴が出る点で、これは③に当たる。

**結論**: ①②の制約 C1〜C5 はすべて `10_bash` / `12_*` / `18_atuin` / lf→yazi の間で閉じている。**`10_bash`、`10_sudo`、`12_*`、`18_atuin` は番号を変えず**、`05_tools` の分割だけを行う。

---

## 4. 分類案

### 4.1 トップレベル（グループ）

| 番号 | グループ | 意味 | libs 側 |
|------|----------|------|---------|
| `02_net` | ネットワーク・転送系 | ダウンロード / アップロード / リモートリソース操作 | `libs/net/` |
| `04_search` | 検索系 | ファイル・テキスト・コマンドの検索 | `libs/search/` |
| `06_text` | 加工・整形系 | JSON / YAML の加工、コード整形 | `libs/text/` |
| `14_view` | 表示系 | ファイル・差分・ディスク使用量の表示、ファイラ | `libs/view/` |

**search と text を view より前**に置く理由:

- search と text は単機能で、他のツールに依存しない。
- view（特に lf や yazi のようなファイラ）は、bat、fzf、fd、rg、jq などを組み合わせて使う側である。

**view を `14_` にする**理由:

- view は fzf（`12_fzf`）も組み合わせて使う側なので、原則（§2）どおり fzf より後に置く。
- `18_atuin` との間に①②の制約はない。atuin は Ctrl-O を bind しない。

その他:

- 奇数番号（`01`, `03`, `05`, `07`, `09`, `11`, `13`, `15`〜`17`, `19`）は将来の追加用に空けておく。
- グループ名は `--filter` の部分一致で衝突しない（`net` / `search` / `text` / `view` は、既存のどのトップレベル名にも含まれない）。
- `libs/` 直下に同じ名前のディレクトリはまだない。

### 4.2 サブモジュールの番号ルール

| 帯 | 用途 |
|----|------|
| `0x` | グループ内の他ツールがインストール時に依存する（①）基盤。現状は該当なし |
| `1x` | 独立した単機能 CLI。順不同なので同じ番号でよい（同番号はアルファベット順） |
| `5x` | シェルにキーバインドや関数を登録するもの（②）。後勝ちを制御したいので間隔を空ける |
| 後継ツール | 前任より大きい番号にする（例: `50_lf` → `60_yazi`） |

### 4.3 分類後の全体像

```
bash/
├── 00_bin/                   （変更なし）
├── 02_net/                   ① ネットワーク・転送系
│   ├── 10_eget/              ← 01_eget   （バイナリを置いておくだけ。主要な取得手段としては廃止済み）
│   ├── 10_httpie/            ← 02_httpie
│   └── 10_stu/               ← 06_stu    （S3 TUI ブラウザ）
├── 04_search/                ② 検索系
│   ├── 10_fd/                ← 06_fd
│   ├── 10_navi/              ← 06_navi   （fzf への依存は③なので前に置いてよい）
│   └── 10_rg/                ← 06_rg
├── 06_text/                  ③ 加工・整形系
│   ├── 10_jq/                ← 06_jq
│   ├── 10_shfmt/             ← 06_shfmt
│   └── 10_yq/                ← 06_yq
├── 10_bash/  10_sudo/        （変更なし）
├── 12_fzf/  12_git/  12_vim/ （変更なし — C2/C3/C4）
├── 14_view/                  ④ 表示系
│   ├── 10_bat/               ← 06_bat
│   ├── 10_delta/             ← 08_delta
│   ├── 10_eza/               ← 06_eza
│   ├── 10_gdu/               ← 06_gdu
│   ├── 50_lf/                ← 06_lf     （Ctrl-O）
│   └── 60_yazi/              （将来追加。Ctrl-O を lf より後に bind → C5）
└── 18_atuin/                 （変更なし — C3/C4）
```

- 移行後の読み込み順は `bin → net → search → text → bash → sudo → fzf → git → vim → view → atuin` になる。C1〜C5 はすべて満たされる。
- **eget** は、主要な取得手段としては廃止済み（GitHub Releases からの取得は `__rayrc_github_downloader`、公式インストーラがあるものはそちらを使う）。ただし手作業で使う可能性に備えて、バイナリは引き続きインストールする。
  - `01_eget/install.sh` が定義している `__rayrc_eget_install` ヘルパーは、呼び出し元がないまま残る。
  - 今回はモジュールの中身には手を入れず、移動だけにする。
- **fzf** は機能としては検索系だが、C4（キーバインドの後勝ち）の都合で `12_fzf` のまま残す。

### 4.4 検討して見送った案: `10_bash` のサブグループ化

`12_fzf` / `12_git` / `12_vim` / `18_atuin` を `10_bash/` の下のサブモジュールにまとめ、11〜19 を拡張用に予約する案。
見た目は整うが、今回は見送る。

- **順序の面での得がない**: C2〜C4 は今の番号ですでに満たされている。
- **data plane の移行コストが大きい**: `libs/{fzf,git,vim,atuin}` が `libs/bash/{fzf,git,vim,atuin}` に移ることになる。
  - atuin の履歴 DB（`libs/atuin/data/history.db` ほか）を既存ホストごとに移す必要がある。
  - `~/.vim` シンボリックリンク（→ `libs/vim/vimfiles`）が、再インストールするまで切れる。
  - gitstatus と fzf の clone 先も変わる。
- **`10_bash` 自体を分解する必要がある**: 現在は `main.sh` などを直接持つ末端のモジュールなので、中身を `10_bash/01_core/` のようなサブモジュールに移す必要がある。
- **`--filter` の指定が変わる**: `--filter fzf` が `--filter bash,fzf` になる。

将来この案を採用する場合でも、`14_view` がトップレベルに 1 枠使うだけなので、11〜19 の大半は空いたまま残る。

---

## 5. 影響範囲

### 5.1 control plane（`bash/`）

- 各グループに delegate 用の `install.sh` / `main.sh` を置く。中身は現在の `05_tools/{install,main}.sh` と同じ。
- サブモジュール内のスクリプトは `__rayrc_data_dir` だけでパスを組み立てているので、**中身の修正は不要**。

### 5.2 data plane（`libs/`）

`__rayrc_package:3` で番号プレフィックスを外すため、グループ名が `libs/` のパスに直接反映される。

| 移動元 | 移動先 | 追跡ファイル |
|--------|--------|--------------|
| `libs/tools/bat/` | `libs/view/bat/` | `config/bat.conf` |
| `libs/tools/lf/` | `libs/view/lf/` | `config/**`, `.gitignore`（`data` を無視） |
| `libs/tools/navi/` | `libs/search/navi/` | `cheats/*.cheat`, `config/config.yaml` |
| `libs/tools/stu/` | `libs/net/stu/` | `config/*.toml`, `.gitignore` |
| `libs/tools/{delta,eget,eza,fd,gdu,httpie,jq,rg,shfmt,yq}/` | （新しい場所に自動作成される） | なし（空、または実行時データのみ） |

- `libs/bin/` はフラット構成なので影響なし。
- `.bashrc` に書かれる `bash/main.sh` のパスも変わらない。

### 5.3 ドキュメント・ルール

- `.claude/rules/bash.md`
  - プレフィックス表の `05_` 行を、`02`〜`06` と `14` のグループに書き換える。
  - 「Adding a New Tool Module under `05_tools/`」節を更新する（グループの選び方と §4.2 の番号ルール）。
  - パス例（`05_tools/06_bat` → `libs/tools/bat` など）を更新する。
  - `__rayrc_eget_install` の説明に「主要な取得手段としては廃止済み・現在は未使用」と明記する。
  - §2 の依存の 3 分類と、§3 の制約 C1〜C5 を追記し、再発を防ぐ。
- `.claude/rules/libs.md`: `libs/tools/lf/.gitignore` の例を `libs/view/lf/.gitignore` にする。
- `libs/view/lf/config/lf/lfrc:54`: コメントアウトされた古いパスを更新する（任意）。
- `12_fzf/main.sh:3`: 根拠のないコメント「should come before git and vim」を、C4 を説明するコメントに置き換える。

### 5.4 `--filter` の指定方法

- 部分インストールの指定が `--filter tools,bat` から `--filter view,bat` に変わる。

### 5.5 対象外

- `zsh/` は独自の構成（`06_bat`, `06_lf`, `11_fzf` …、データは `libs/bat` などを参照）で、すでに bash 側と揃っていない。今回は触らない。

---

## 6. 移行ステップ

コミットは 2 つに分ける。リネームだけのコミットを独立させ、git の rename 検出と履歴を保つ。

### Step 1: グループへの分割 — `refactor: split 05_tools into net/search/text/view groups`

1. グループ用の delegate スクリプトを作る。`14_view` には `05_tools` のものを移動し（履歴が残る）、ほかの 3 グループにはコピーする。

   ```bash
   mkdir -p bash/{02_net,04_search,06_text,14_view}
   git mv bash/05_tools/install.sh bash/05_tools/main.sh bash/14_view/
   for g in 02_net 04_search 06_text; do
       cp bash/14_view/install.sh bash/14_view/main.sh "bash/$g/"
   done
   ```

2. サブモジュールを `git mv` する（§4.3 の対応表どおり）。

   ```bash
   git mv bash/05_tools/01_eget   bash/02_net/10_eget
   git mv bash/05_tools/02_httpie bash/02_net/10_httpie
   git mv bash/05_tools/06_stu    bash/02_net/10_stu
   git mv bash/05_tools/06_fd     bash/04_search/10_fd
   git mv bash/05_tools/06_navi   bash/04_search/10_navi
   git mv bash/05_tools/06_rg     bash/04_search/10_rg
   git mv bash/05_tools/06_jq     bash/06_text/10_jq
   git mv bash/05_tools/06_shfmt  bash/06_text/10_shfmt
   git mv bash/05_tools/06_yq     bash/06_text/10_yq
   git mv bash/05_tools/06_bat    bash/14_view/10_bat
   git mv bash/05_tools/08_delta  bash/14_view/10_delta
   git mv bash/05_tools/06_eza    bash/14_view/10_eza
   git mv bash/05_tools/06_gdu    bash/14_view/10_gdu
   git mv bash/05_tools/06_lf     bash/14_view/50_lf
   ```

3. `libs/` 側を `git mv` する（§5.2）。

   ```bash
   mkdir -p libs/{net,search,text,view}
   git mv libs/tools/stu  libs/net/stu
   git mv libs/tools/navi libs/search/navi
   git mv libs/tools/bat  libs/view/bat
   git mv libs/tools/lf   libs/view/lf
   ```

4. 空になった `bash/05_tools/` を削除する。`libs/tools/` は Step 3 で扱う。

### Step 2: ドキュメント更新 — `docs: update module numbering rules`

- §5.3 の各ファイルを更新する。

### Step 3: 既存ホストでの移行（1 回だけ手作業）

`git pull` で追跡ファイルは移動するが、**追跡外の実行時データは `libs/tools/` に残る**。

```bash
cd ~/.rayrc/libs
[[ -d tools/lf/data ]]       && mv tools/lf/data view/lf/
[[ -d tools/httpie/httpie ]] && mkdir -p net/httpie && mv tools/httpie/httpie net/httpie/
ls tools/stu/config/*.log 2>/dev/null && mv tools/stu/config/*.log net/stu/config/
rm -rf tools   # 中身を確認してから
```

- バイナリ（`libs/bin/`）と `.bashrc` はそのままでよい。新しいシェルを開けば新しいパスが使われる。
- ついでに、以前の構成の残骸である `libs/gdu/`, `libs/jq/`（`libs/.gitignore` で無視されている）も削除できる。

---

## 7. 決定事項

| # | 論点 | 決定 |
|---|------|------|
| D1 | eget | 主要な取得手段としては廃止済み。バイナリは引き続き入れる（`02_net/10_eget`） |
| D2 | jq / yq / shfmt | `06_text` を新設する |
| D3 | net / search / text / view の並び | search と text を view より前に置く。view は fzf の後の `14_view` にする |
| D4 | stu | `02_net`（リモートストレージの転送・操作） |
| D5 | fzf ↔ gitstatus | ①②の依存はない。番号は据え置き、コメントだけ整理する |
| D6 | fzf / atuin の競合キー | Ctrl-R（Ctrl-O は lf / yazi のみが使う） |
| D7 | navi を fzf より前に置くか | 問題ない（依存は③のみ） |
| D8 | `10_bash` のサブグループ化 | 今回は見送る（§4.4） |

---

## 8. 検証

1. 構文チェック: `for f in bash/**/*.sh; do bash -n "$f"; done`
2. クリーン環境: `/rayrc-docker-test` でフルインストールする。ログが `net → search → text → bash … → view → atuin` の順に出ること、エラーがないことを確認する。
3. 部分インストール: `source ./install --filter view,bat` が bat だけを入れること。
4. 対話シェルでの確認:

   ```bash
   bind -p | grep -E '"\\C-(r|o)"'        # Ctrl-R → atuin, Ctrl-O → lfcd
   echo "$PROMPT_COMMAND"                  # gitstatus_prompt_update と __bp_precmd_invoke_cmd の両方がある
   ls -d "$BAT_CONFIG_PATH" "$NAVI_PATH" "$STU_ROOT_DIR" "$__RAYRC_LF_DATA_DIR"   # すべて新しいパスに存在する
   navi                                    # fzf の選択画面が開く（③が解決されている）
   ```

5. 既存ホストで §6 Step 3 を実施したあと、lf のブックマークや履歴（`data/`）が引き継がれていること。

---

## 9. 今後: yazi の追加

- `bash/14_view/60_yazi/` として追加し、Ctrl-O を bind する（C5 により lf より後なので yazi が勝つ）。
- yazi は fd、rg、fzf、jq を実行時に使う（③）。これらはすべて yazi より前のグループにあり、原則（§2）にも合う。
- 移行期間は lf を残せる。完全に切り替える段階で `14_view/50_lf/disabled` を置くか、ディレクトリごと削除する。
- 設定は `libs/view/yazi/config/` に置き、`YAZI_CONFIG_HOME` で参照する（lf の `XDG_CONFIG_HOME` 方式と同じ考え方）。
