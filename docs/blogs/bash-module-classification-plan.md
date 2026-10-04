# bash/ モジュール分類・再番号付けプラン

`bash/05_tools/` に CLI ツールが 14 個集まり、今後も増える見込みのため、機能別のグループに分割する。
あわせて、トップレベルに散らばっているシェル本体・対話系のモジュール（`10_bash`, `10_sudo`, `12_*`, `18_*`, `70_tmux`）もグループにまとめる。
20 番台以降（`20_python` 〜 `90_misc`）は `70_tmux` を除いて対象外とする。

---

## 1. 現状

```
bash/
├── 00_bin/            PATH に libs/bin を追加
├── 05_tools/          ← CLI ツールがここに集中
│   ├── 01_eget/  02_httpie/
│   ├── 06_bat/  06_eza/  06_fd/  06_gdu/  06_jq/  06_lf/  06_navi/
│   ├── 06_rg/   06_shfmt/ 06_stu/ 06_yq/
│   └── 08_delta/
├── 10_bash/  10_sudo/
├── 12_fzf/   12_git/   12_vim/
├── 18_atuin/ 18_yazi/
├── 20_python/  40_docker/  60_iac/  70_claude/  70_niri/
├── 70_tmux/
└── 80_homeassistant/  80_hulft/  90_misc/
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

`__rayrc_source_facade` は `ls -1` の順（＝番号順、**同番号ならアルファベット順**）で source する。

| # | 種類 | 制約（移行後の名前） | 根拠 |
|---|------|------|------|
| C1 | ② | `00_bin` < 全モジュール | `libs/bin` を PATH に追加する。以降の `command -v` ガードはこれが前提 |
| C2 | ② | `08_bash/10_common` < `10_viewer/20_git` | `10_common/main.sh:21` の `PROMPT_COMMAND=smile_prompt` を `gitstatus.prompt.sh:122` が**代入で上書き**している |
| C3 | ② | `10_viewer/20_git` < `10_viewer/30_atuin` | atuin は内蔵の bash-preexec で `PROMPT_COMMAND` / DEBUG trap にフックする。git が後だと、`PROMPT_COMMAND=gitstatus_prompt_update`（append ではなく代入）で **atuin のフックが消え、履歴が記録されなくなる** |
| C4 | ② | `10_viewer/10_fzf` < `10_viewer/30_atuin` | **Ctrl-R** を両方が bind する（fzf: `key-bindings.bash`、atuin: `atuin init bash`）。atuin を勝たせるには後に置く |
| C5 | ② | `10_viewer/40_yazi` < `10_viewer/48_lf` | **Ctrl-O** を lf が `bind '"\C-o":"lfcd\C-m"'` で使っている（`48_lf/main.sh:49`）。**今は lf を勝たせる**ので lf を後に置く。yazi 側の bind は現在コメントアウトしてある（e41959a "tmp lf > yazi"）が、戻しても lf が勝つ |

- C3 があるので、atuin を git と同じ `20_` にしてはいけない。`20_atuin` は `20_git` よりアルファベット順で前になり、C3 に違反する。そのため `30_atuin` にする。
- `05_tools` のツールのうち②を持つのは lf だけである（`bind` を使う）。ほかの `main.sh` は環境変数か alias を設定するだけ。

①（インストール時の依存）は、今のところ存在しない。

- 各 `install.sh` は curl / tar / git などのシステムコマンドしか使っていない。
- 以前は eget が①の基盤だったが、現在は `__rayrc_eget_install` を呼んでいるモジュールはない。
- vim の fzf プラグイン（`plugins.vim:47` の `Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }`）は、vim-plug が自分で fzf を取得する。`10_fzf` には依存しないので、vim を fzf より前（`04_text`）に置いても問題ない。

### 主な③（実行時の依存。順序には影響しない）

| 利用する側 | 利用される側 | 箇所 |
|------------|--------------|------|
| fzf（プレビュー、候補一覧） | bat, fd, shfmt | `10_fzf/main.sh` の `FZF_*` 環境変数 |
| navi | fzf | navi は候補選択に fzf を呼び出す。`main.sh` は `NAVI_CONFIG` / `NAVI_PATH` を export するだけ |
| lf（プレビュー） | bat | `libs/viewer/lf/config/lf/lf-previewer:15`（`command -v bat` でガード済み） |
| yazi | fd, rg, fzf, jq など | yazi の検索・プラグイン機能 |
| `10_common` の `la` / `ll` / `lt` | eza | `command -v eza` で PATH を確認しているだけ |

- fzf ↔ git の間に①②の依存はない。唯一の接点は、`gitstatus_prompt_update` がプロンプトごとに `history -a/-c/-r` を実行し、fzf の Ctrl-R に他セッションの履歴が出る点で、これは③に当たる。

**結論**: ①②の制約 C1〜C5 は、次の 2 つで満たされる。

- グループの間の順序: `00_bin` が最初、`08_bash` が `10_viewer` より前。
- `10_viewer` の中の番号: `10_fzf` < `20_git` < `30_atuin`、`40_yazi` < `48_lf`。

`02_net` / `04_text` / `06_filesearch` の中は、①②の制約がないので順不同でよい。

---

## 4. 分類案

### 4.1 トップレベル（グループ）

| 番号 | グループ | 意味 | libs 側 |
|------|----------|------|---------|
| `02_net` | ネットワーク・転送系 | ダウンロード / アップロード / リモートリソース操作 | `libs/net/` |
| `04_text` | テキスト系 | ファイル内容の表示・差分・加工・整形・編集 | `libs/text/` |
| `06_filesearch` | ファイル検索系 | ファイル・テキスト・コマンドの検索、ファイル一覧、ディスク使用量 | `libs/filesearch/` |
| `08_bash` | シェル本体 | プロンプト・alias・環境変数、sudo の設定 | `libs/bash/` |
| `10_viewer` | 対話 UI 系 | ファジーファインダー、プロンプト、履歴、ファイラ、端末多重化 | `libs/viewer/` |

並び順の理由:

- `net` / `text` / `filesearch` は単機能の CLI で、②を持たない（lf は `10_viewer` に移るので、ここには残らない）。
- `08_bash` は `10_viewer` より前に置く必要がある（C2）。
- `10_viewer` には、キーバインドやプロンプトを取り合うモジュールを集める。どれが勝つかはグループ内の番号で決める（C3〜C5）。また、ほかのグループのツールを③で組み合わせて使う側でもあるので、最後に置くのが原則（§2）にも合う。

その他:

- 奇数番号（`01`, `03`, `05`, `07`, `09`）と `11`〜`19` は将来の追加用に空けておく。
- グループ名は `--filter` の部分一致で衝突しない。`net` / `text` / `filesearch` / `bash` / `viewer` は、ほかのトップレベル名（`20_python`, `40_docker`, `60_iac`, `70_claude`, `70_niri`, `80_*`, `90_misc`）のどれにも含まれない。
- `libs/` 直下には `libs/bash/` がすでにある。これは現在の `10_bash` の data dir（空）で、そのまま `08_bash` グループの data dir として使われる。ほかの 4 つ（`net` / `text` / `filesearch` / `viewer`）はまだない。

### 4.2 サブモジュールの番号ルール

| 帯 | 用途 |
|----|------|
| `0x` | グループ内の他ツールがインストール時に依存する（①）基盤。現状は該当なし |
| `1x` | 独立した単機能 CLI、またはグループの土台。順不同なので同じ番号でよい（同番号はアルファベット順） |
| `2x` 以降 | シェルの状態（②）に触れるもの、ほかを組み合わせて使うもの。後から読み込みたいものほど大きい番号にし、間を空ける |

- **キーが競合するものは、勝たせたい方を大きい番号にする**。今は Ctrl-O を lf に持たせるので、`48_lf` を `40_yazi` より後にする。旧案の「後継ツールは前任より大きい番号」というルールはやめる。
- **②の後勝ちがあるものに、同じ番号を付けない**。同じ番号だとアルファベット順で決まってしまう（`20_atuin` < `20_git` になり C3 に違反する）。

`10_viewer` の番号の内訳:

| 番号 | モジュール | 理由 |
|------|------------|------|
| `10_fzf` | fzf | Ctrl-R / Ctrl-T / Alt-C の土台 |
| `20_git` | gitstatus プロンプト | `PROMPT_COMMAND` を代入する（C2 / C3） |
| `30_atuin` | atuin | git と fzf の後（C3 / C4） |
| `40_yazi` | yazi | lf より前（C5） |
| `48_lf` | lf | Ctrl-O を最後に bind して勝つ（C5） |
| `60_tmux` | tmux | `install.sh` しかなく②を持たないので、順序は自由 |

### 4.3 分類後の全体像

```
bash/
├── 00_bin/                   （変更なし）
├── 02_net/                   ① ネットワーク・転送系
│   ├── 10_eget/              ← 05_tools/01_eget   （バイナリを置いておくだけ。主要な取得手段としては廃止済み）
│   ├── 10_httpie/            ← 05_tools/02_httpie
│   └── 10_stu/               ← 05_tools/06_stu    （S3 TUI ブラウザ）
├── 04_text/                  ② テキスト系
│   ├── 10_bat/               ← 05_tools/06_bat
│   ├── 10_delta/             ← 05_tools/08_delta
│   ├── 10_jq/                ← 05_tools/06_jq
│   ├── 10_shfmt/             ← 05_tools/06_shfmt
│   ├── 10_yq/                ← 05_tools/06_yq
│   └── 20_vim/               ← 12_vim
├── 06_filesearch/            ③ ファイル検索系
│   ├── 10_eza/               ← 05_tools/06_eza
│   ├── 10_fd/                ← 05_tools/06_fd
│   ├── 10_gdu/               ← 05_tools/06_gdu
│   ├── 10_navi/              ← 05_tools/06_navi   （fzf への依存は③なので前に置いてよい）
│   └── 10_rg/                ← 05_tools/06_rg
├── 08_bash/                  ④ シェル本体
│   ├── 10_common/            ← 10_bash
│   └── 10_sudo/              ← 10_sudo
└── 10_viewer/                ⑤ 対話 UI 系
    ├── 10_fzf/               ← 12_fzf
    ├── 20_git/               ← 12_git
    ├── 30_atuin/             ← 18_atuin            （C3: git より後）
    ├── 40_yazi/              ← 18_yazi
    ├── 48_lf/                ← 05_tools/06_lf     （C5: Ctrl-O を lf が取る）
    └── 60_tmux/              ← 70_tmux
```

- 移行後の読み込み順は `bin → net → text → filesearch → bash(common → sudo) → viewer(fzf → git → atuin → yazi → lf → tmux) → python …` になる。C1〜C5 はすべて満たされる。
- **eget** は、主要な取得手段としては廃止済み（GitHub Releases からの取得は `__rayrc_github_downloader`、公式インストーラがあるものはそちらを使う）。ただし手作業で使う可能性に備えて、バイナリは引き続きインストールする。
  - `01_eget/install.sh` が定義している `__rayrc_eget_install` ヘルパーは、呼び出し元がないまま残る。
  - 今回はモジュールの中身には手を入れず、移動だけにする。
- **`10_bash` は中身を分解せず**、そのまま `08_bash/10_common` に移す。

### 4.4 旧案から変えた点: シェル本体・対話系のグループ化

旧案では、`12_*` / `18_atuin` を `10_bash` の下にまとめる案を「data plane の移行コストが大きい」として見送っていた。
今回は `08_bash` と `10_viewer` に分けてグループ化する。コストには次のように対処する。

| 旧案で挙げたコスト | 今回の対処 |
|---------------------|------------|
| atuin の履歴 DB（`libs/atuin/data/`）の移行 | `.ci/mv_util.sh` はディレクトリごと移動するので、作業するホストでは ignore された実行時データも一緒に移る（§6）。ほかの既存ホストは §6 Step 3 で手作業で移す |
| `~/.vim` シンボリックリンクが切れる | `mv_util.sh` が警告を出す。`ln -snf` で張り直すか、install を再実行する |
| gitstatus / fzf の clone 先が変わる | clone ごと移動するので、取り直す必要はない |
| `10_bash` を分解する必要がある | 分解しない。中身をそのまま `08_bash/10_common` に移す |
| `--filter` の指定が変わる | §5.5 のとおり変わる。受け入れる |

---

## 5. 影響範囲

### 5.1 control plane（`bash/`）

- 各グループの delegate 用 `install.sh` / `main.sh` は、`mv_util.sh` がグループを作るときに自動で生成する。中身は現在の `05_tools/{install,main}.sh` と同じ。
- `05_tools` は最後に delegate だけが残るので削除する。
- サブモジュール内のスクリプトは `__rayrc_data_dir` だけでパスを組み立てているので、**動作上の修正は不要**。ただし、古いパスを書いたコメントは §5.4 で直す。

### 5.2 data plane（`libs/`）

`__rayrc_package:3` で番号プレフィックスを外すため、グループ名が `libs/` のパスに直接反映される。

| 移動元 | 移動先 | 追跡ファイル | 追跡外（ignore）の実行時データ |
|--------|--------|--------------|--------------------------------|
| `libs/tools/{eget,httpie}/` | `libs/net/{eget,httpie}/` | なし | （httpie の設定が入ることがある） |
| `libs/tools/stu/` | `libs/net/stu/` | `config/*.toml`, `.gitignore` | `config/*.log` |
| `libs/tools/bat/` | `libs/text/bat/` | `config/bat.conf` | — |
| `libs/tools/{delta,jq,shfmt,yq}/` | `libs/text/…` | なし | — |
| `libs/vim/` | `libs/text/vim/` | `vimfiles/**` | `vimfiles/{plugged,autoload,viminfo}`, `__rayrc_backup/` |
| `libs/tools/navi/` | `libs/filesearch/navi/` | `cheats/*.cheat`, `config/config.yaml` | — |
| `libs/tools/{eza,fd,gdu,rg}/` | `libs/filesearch/…` | なし | — |
| `libs/bash/` | `libs/bash/common/` | なし（空） | — |
| `libs/sudo/` | `libs/bash/sudo/` | なし（空） | — |
| `libs/fzf/` | `libs/viewer/fzf/` | `.gitignore`, `README.md` | `fzf/`（clone） |
| `libs/git/` | `libs/viewer/git/` | `.gitignore`, `gitstatus.prompt.sh` | `gitstatus/`（clone） |
| `libs/atuin/` | `libs/viewer/atuin/` | `config/`, `.gitignore` | **`data/`（履歴 DB）** |
| `libs/yazi/` | `libs/viewer/yazi/` | `config/` | — |
| `libs/tools/lf/` | `libs/viewer/lf/` | `config/**`, `.gitignore` | `data/`（ブックマーク・履歴） |
| `libs/tmux/` | `libs/viewer/tmux/` | `.tmux.conf`, `.tmux.conf.local`, `templates/` | `__rayrc_backup/` |

- `bash/18_yazi/completions/`（ignore されている。install のときに生成される）も、`bash/10_viewer/40_yazi/` へ一緒に移る。
- `libs/bin/` はフラット構成なので影響なし。
- `.bashrc` に書かれる `bash/main.sh` のパスも変わらない。
- `~/.vim` → `libs/vim/vimfiles` のシンボリックリンクは切れる。`~/.tmux.conf` はコピーなので影響しない。`~/.claude` は `70_claude` が対象外なので影響しない。
- **起動中のシェル**は、`ATUIN_DATA_DIR` / `GITSTATUS_DIR` / `__RAYRC_LF_DATA_DIR` / `YAZI_CONFIG_HOME` / `BAT_CONFIG_PATH` / `NAVI_PATH` などに古いパスを持ったままになる。特に atuin は、古い `ATUIN_DATA_DIR` に新しい DB を作ってしまうおそれがある。**移行作業の前に、ほかのシェル（tmux のペインを含む）は閉じておく**。

### 5.3 bash 以外からの参照

`libs/` は bash 専用ではないので、ほかのシェルからの参照にも影響する。

- **PowerShell**: `powershell/20_yazi/main.ps1:2` が `libs\yazi\config` を直接参照している。`libs\viewer\yazi\config` に直さないと、Windows 側の yazi が設定を読めなくなる（**要修正**）。
- **zsh**（今回は対象外。ただし次の点が壊れる）:
  - `zsh/11_fzf` と `zsh/15_vim` は、`__rayrc_data_dir` を通じて bash と同じ `libs/fzf` / `libs/vim` を使っている。
  - 移行後に zsh で install すると、`libs/fzf/fzf` に clone される。ところが `libs/fzf/.gitignore` は移動済みなので、clone が untracked として見えてしまう。
  - `libs/vim/vimfiles` の追跡ファイル（vimrc や `plugins.vim` など）は `libs/text/vim/` に移っている。そのため、zsh 側で張られる `~/.vim` は設定のない vimfiles を指すことになる。
  - zsh を使う予定があるなら、zsh 側も同じ構成に揃えるなどの対応が別途必要になる。`zsh/06_bat`、`06_lf` はすでに `libs/bat`、`libs/lf` を参照していて、bash 側とずれている。

### 5.4 ドキュメント・ルール・コメント

`mv_util.sh` は、移動前のパスを参照している箇所を警告として表示する（`docs/` は除く）。主なものは次のとおり。

- `.claude/rules/bash.md`
  - プレフィックス表の `05_` / `10_` / `12_` / `15_` の行を、`02_net` / `04_text` / `06_filesearch` / `08_bash` / `10_viewer` の各グループに書き換える。
  - 「Two-Level Module Hierarchy」のパス例（`05_tools/06_bat` → `libs/tools/bat` など）を更新する。
  - 「Adding a New Tool Module under `05_tools/`」節を更新する（グループの選び方と §4.2 の番号ルール）。
  - `__rayrc_eget_install` の説明に「主要な取得手段としては廃止済み・現在は未使用」と明記する。
  - §2 の依存の 3 分類と、§3 の制約 C1〜C5 を追記し、再発を防ぐ。
- `.claude/rules/libs.md`: パス例（`libs/git/`, `libs/fzf/`, `libs/vim/`, `libs/tools/lf/`）を新しいパスに更新する。
- `10_viewer/10_fzf/main.sh:3`: 根拠のないコメント「should come before git and vim」を、C4 を説明するコメントに置き換える。
- `10_viewer/30_atuin/{install,main}.sh`: コメント中の `libs/atuin` を `libs/viewer/atuin` にする。
- `10_viewer/40_yazi/main.sh:32`: コメント中の `05_tools/06_lf` を直す。lf を勝たせる方針（C5）も書き添える。
- `powershell/20_yazi/main.ps1:1`: コメント中の `bash/18_yazi/main.sh` / `libs/yazi/config` を直す（2 行目は §5.3 で修正する）。
- `libs/viewer/lf/config/lf/lfrc:54`: コメントアウトされた古いパスを更新する（任意）。

### 5.5 `--filter` の指定方法

| 対象 | 変更前 | 変更後 |
|------|--------|--------|
| bat | `--filter tools,bat` | `--filter text,bat` |
| fzf | `--filter fzf` | `--filter viewer,fzf` |
| bash 本体 | `--filter bash` | `--filter bash,common`（`--filter bash` だけだと sudo も含む） |

CI（`.github/workflows/`）は `--filter` を使っていないので影響しない。

### 5.6 対象外

- `zsh/`（§5.3 の影響は残る）
- `20_python` 以降のモジュール（`70_tmux` を除く）

---

## 6. 移行ステップ

コミットは 2 つに分ける。リネームだけのコミットを独立させ、git の rename 検出と履歴を保つ。

### Step 1: グループへの分割 — `refactor: reorganize bash modules into net/text/filesearch/bash/viewer groups`

0. ほかのシェルと tmux のペインを閉じる（§5.2）。

1. `.ci/mv_util.sh` で、モジュールごとに control plane と data plane を一緒に移動する。

   ```bash
   M=.ci/mv_util.sh
   $M --from 05_tools/01_eget   --to 02_net/10_eget
   $M --from 05_tools/02_httpie --to 02_net/10_httpie
   $M --from 05_tools/06_stu    --to 02_net/10_stu
   $M --from 05_tools/06_bat    --to 04_text/10_bat
   $M --from 05_tools/08_delta  --to 04_text/10_delta
   $M --from 05_tools/06_jq     --to 04_text/10_jq
   $M --from 05_tools/06_shfmt  --to 04_text/10_shfmt
   $M --from 05_tools/06_yq     --to 04_text/10_yq
   $M --from 12_vim             --to 04_text/20_vim
   $M --from 05_tools/06_eza    --to 06_filesearch/10_eza
   $M --from 05_tools/06_fd     --to 06_filesearch/10_fd
   $M --from 05_tools/06_gdu    --to 06_filesearch/10_gdu
   $M --from 05_tools/06_navi   --to 06_filesearch/10_navi
   $M --from 05_tools/06_rg     --to 06_filesearch/10_rg
   $M --from 10_bash            --to 08_bash/10_common    # 10_sudo より先に
   $M --from 10_sudo            --to 08_bash/10_sudo
   $M --from 12_fzf             --to 10_viewer/10_fzf
   $M --from 12_git             --to 10_viewer/20_git
   $M --from 18_atuin           --to 10_viewer/30_atuin
   $M --from 18_yazi            --to 10_viewer/40_yazi
   $M --from 05_tools/06_lf     --to 10_viewer/48_lf
   $M --from 70_tmux            --to 10_viewer/60_tmux
   ```

   `mv_util.sh` は次のように動く。

   - 移動先のグループがなければ作り、delegate 用の `install.sh` / `main.sh` を生成して `git add` する。
   - 追跡ファイルを含むディレクトリは `git mv` で移す。ignore された実行時データもディレクトリごと移る。追跡ファイルがなければ `mv` で移す。
   - `10_bash` → `08_bash/10_common` は data plane が `libs/bash` → `libs/bash/common` と自分自身の配下に移るので、一時的な名前を経由して移す。
     - `10_sudo` を先に移すと `libs/bash/sudo` が `common` の中に巻き込まれる。そのためスクリプトはエラーで止まる。**`10_bash` を先に実行する**。
   - 実行後に、次の点を警告として表示する。
     - 空になった元グループ（`05_tools`）と `libs/tools`
     - 切れたシンボリックリンク（`~/.vim`）
     - 古いパスを参照している箇所

2. 空になったものを削除する。

   ```bash
   git rm -r bash/05_tools     # delegate だけが残っている
   rmdir libs/tools            # 空（追跡ファイルなし）
   ```

3. `~/.vim` を張り直す（`ln -snf ~/.rayrc/libs/text/vim/vimfiles ~/.vim`、または `source ./install --filter text,vim`）。

### Step 2: 参照とドキュメントの更新 — `docs: update module layout and path references`

- §5.3 の PowerShell の参照と、§5.4 の各ファイルを更新する。

### Step 3: ほかの既存ホストでの移行（1 回だけ手作業）

`git pull` で追跡ファイルは移動するが、**追跡外の実行時データは古い場所に残る**。

```bash
cd ~/.rayrc/libs
## 取り直せないデータ
[[ -d atuin/data ]]          && mv atuin/data viewer/atuin/
[[ -d tools/lf/data ]]       && mv tools/lf/data viewer/lf/
[[ -d tools/httpie/httpie ]] && mkdir -p net/httpie && mv tools/httpie/httpie net/httpie/
ls tools/stu/config/*.log 2>/dev/null && mv tools/stu/config/*.log net/stu/config/
## install を再実行すれば取り直せるが、移せば通信が要らない
[[ -d fzf/fzf ]]             && mv fzf/fzf viewer/fzf/
[[ -d git/gitstatus ]]       && mv git/gitstatus viewer/git/
for d in plugged autoload viminfo; do
    [[ -e vim/vimfiles/$d ]] && mv "vim/vimfiles/$d" text/vim/vimfiles/
done
[[ -d vim/__rayrc_backup ]]  && mv vim/__rayrc_backup text/vim/
[[ -d tmux/__rayrc_backup ]] && mv tmux/__rayrc_backup viewer/tmux/
[[ -d ../bash/18_yazi/completions ]] && mv ../bash/18_yazi/completions ../bash/10_viewer/40_yazi/
ln -snf ~/.rayrc/libs/text/vim/vimfiles ~/.vim

## 残骸。中身を確認してから削除する
ls -A tools atuin fzf git vim tmux yazi sudo ../bash/{05_tools,10_bash,10_sudo,12_fzf,12_git,12_vim,18_atuin,18_yazi,70_tmux} 2>/dev/null
```

- バイナリ（`libs/bin/`）と `.bashrc` はそのままでよい。新しいシェルを開けば新しいパスが使われる。
- ついでに、以前の構成の残骸である `libs/gdu/`, `libs/jq/`（`libs/.gitignore` で無視されている）も削除できる。
- Docker や新しいホストでは、この作業は要らない。

---

## 7. 決定事項

| # | 論点 | 決定 |
|---|------|------|
| D1 | eget | 主要な取得手段としては廃止済み。バイナリは引き続き入れる（`02_net/10_eget`） |
| D2 | グループ構成 | `02_net` / `04_text` / `06_filesearch` / `08_bash` / `10_viewer` の 5 つ（§4.3） |
| D3 | グループの並び | 単機能 CLI のグループ（net / text / filesearch）→ bash → viewer |
| D4 | stu | `02_net`（リモートストレージの転送・操作） |
| D5 | fzf ↔ gitstatus | ①②の依存はない。コメントだけ整理する |
| D6 | 競合キー | Ctrl-R は fzf / atuin（atuin を勝たせる）、Ctrl-O は lf / yazi（lf を勝たせる） |
| D7 | navi を fzf より前に置くか | 問題ない（依存は③のみ） |
| D8 | `10_bash` のサブグループ化 | 採用する（旧案での見送りを撤回）。中身は分解せず `08_bash/10_common` に移す |
| D9 | atuin の番号 | `30_atuin`。`20_atuin` だと `20_git` よりアルファベット順で前になり、C3 に違反する |
| D10 | lf / yazi の番号 | `40_yazi` < `48_lf`。当面は lf を勝たせる |
| D11 | vim の置き場所 | `04_text/20_vim`。fzf.vim は vim-plug が自分で fzf を取得するので、`10_fzf` より前でよい |
| D12 | tmux | `10_viewer/60_tmux`。`install.sh` しかなく、②を持たない |
| D13 | 移動の手段 | `.ci/mv_util.sh`。グループと delegate は自動作成、空になった元グループとシンボリックリンクは警告だけ出す |

---

## 8. 検証

1. 構文チェック: `for f in bash/**/*.sh; do bash -n "$f"; done`
2. クリーン環境: `/rayrc-docker-test` でフルインストールする。次の 2 点を確認する。
   - ログが `net → text → filesearch → bash → viewer → python …` の順に出る。`viewer` の中は `fzf → git → atuin → yazi → lf → tmux` の順。
   - エラーがない。
3. 部分インストール: `source ./install --filter text,bat` が bat だけを入れること。
4. 対話シェルでの確認:

   ```bash
   bind -p | grep -E '"\\C-(r|o)"'        # Ctrl-R → atuin, Ctrl-O → lfcd
   echo "$PROMPT_COMMAND"                  # gitstatus_prompt_update と __bp_precmd_invoke_cmd の両方がある
   ls -d "$BAT_CONFIG_PATH" "$NAVI_PATH" "$STU_ROOT_DIR" "$__RAYRC_LF_DATA_DIR" \
         "$ATUIN_DATA_DIR" "$YAZI_CONFIG_HOME" "$GITSTATUS_DIR"   # すべて新しいパスに存在する
   readlink ~/.vim                         # libs/text/vim/vimfiles
   atuin history list | tail               # 移行前の履歴が見える
   navi                                    # fzf の選択画面が開く（③が解決されている）
   ```

5. 既存ホストで §6 Step 3 を実施したあと、lf のブックマークや履歴（`data/`）と atuin の履歴が引き継がれていること。
6. Windows: PowerShell で yazi が `libs\viewer\yazi\config` を読むこと。

---

## 9. 今後: yazi への切り替え

- 今は lf が Ctrl-O を持っている（`48_lf` > `40_yazi`）。yazi の `y` ラッパーは使えるが、Ctrl-O は lf のまま。
- yazi を主にする段階では、次のどちらかにする。
  - lf をやめる: `10_viewer/48_lf/disabled` を置くか、ディレクトリごと削除し、yazi の `main.sh` の bind のコメントアウトを戻す。
  - lf を残したまま yazi を勝たせる: lf を 40 より小さい番号に移し（例: `mv_util.sh --from 10_viewer/48_lf --to 10_viewer/38_lf`）、yazi の bind を戻す。同じグループ内の番号変更では data plane のパス（`libs/viewer/lf`）は変わらない。
- yazi は fd、rg、fzf、jq を実行時に使う（③）。これらは yazi より前のグループか、同じグループの前の番号にあり、原則（§2）にも合う。
