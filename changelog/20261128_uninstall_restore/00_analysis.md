# install 時のバックアップと uninstall 時の復元 — 00 分析

Nov 28, 2026

**スコープ**: rayrc を入れる**前**からユーザーが持っていた設定を、install 時に 1 度だけ退避し、uninstall 時に戻す。rayrc を再インストールするためのバックアップや、履歴の保存は対象外（ユーザー指定）。

確度の表記: **verified**（実行して確認） / **inferred**（コードを読んだうえでの推論） / **untested**（未検証）

---

## 0. 結論

1. **今の uninstall がしているのは「rc の managed block を消して `rm -rf ~/.rayrc`」だけ。** モジュールの `uninstall.sh` は 1 本も無い。facade は `uninstall` phase を回すが、何も読まない（verified: `find`）。PowerShell には uninstall 自体が無い（`uninstall.ps1` は 0 バイトで、`src/uninstall.ps1` は存在しない）。
2. **退避している箇所は 4 つ。保存先も方式もばらばら**（vim / tmux は data plane の中、claude は `$HOME` 直下にタイムスタンプ付き、PS は `$PROFILE.rayrc.bak`）。しかも vim / tmux の退避先は `libs/` の中にあるので、**uninstall の `rm -rf` で退避したもの自体が消える**。ユーザーが今やっている手順（`rm -rf ~/.rayrc` → clone → install）でも同じく消える。
3. **退避せずに壊している箇所や、2 回目の実行で壊れる箇所がある**（§2 B, C）。
4. 直し方は**モジュールごとの uninstall.sh を書くことではない**。共通の helper と manifest（台帳）を作り、「最初に触った瞬間に 1 度だけ退避して記録する → uninstall は記録を逆順に戻す」に統一する（§3）。

---

## 1. rayrc が `~/.rayrc` の外に残す足跡（棚卸し）

全モジュールの install / main を `$HOME`、`ln -s`、`bak`、`cp`、`git config`、`/etc` で grep し、読んで確認した（inferred。実行はしていない）。

### 1.1 Unix

| # | 足跡 | 書く場所 | 既にあるものの扱い（install） | 現状の uninstall |
|---|------|---------|--------------------------|----------------|
| U1 | `~/.bashrc` / `~/.zshrc` の managed block | `src/install.{sh,zsh}` | ブロック単位で置き換える（ユーザーの行は残る） | ✅ 消す。ただし rc が無いと**何もしない**（`rm -rf` もしない） |
| U2 | `~/.bashrc` の `HISTSIZE=` / `HISTFILESIZE=` の行 | `08_shell/10_common/install.sh` | **退避せずに削除**する（GNU `sed -i` を直接使っている） | ❌ 戻さない |
| U3 | `~/.bash_profile` | `08_shell/10_common/install.sh` | 3 種の profile がどれも無いときだけ作る | ❌ 消さない |
| U4 | `~/.vimrc`（ファイル） | `04_text/20_vim/install.*` | `libs/text/vim/__rayrc_backup/` へ mv する | ❌ 戻さない。退避先ごと消える |
| U5 | `~/.vimrc`（symlink。dotfiles 管理ツールのものなど） | 同上 | **退避せずに `rm -f`** する | ❌ |
| U6 | `~/.vim`（ディレクトリ） | 同上 | `__rayrc_backup/.vim` へ mv する | ❌ 戻さない。消える。`~/.vim` は壊れた symlink として残る |
| U7 | `~/.vim`（ユーザーの symlink） | 同上 | `-L` なので退避の対象から外れ、**`ln -snf` で上書き**される | ❌ |
| U8 | `~/.tmux.conf` | `10_viewer/60_tmux/install.sh` | `__rayrc_backup/` へ mv する（symlink なら `rm -f`） | ❌ |
| U9 | `~/.tmux.conf.local` | 同上 | **退避せずに `cp -f` で上書き**する | ❌ |
| U10 | `~/.tmux`（ディレクトリ） | 同上 | mv する。**rayrc は `~/.tmux` を使わない**ので退避する理由が無い。TPM のプラグインがあれば壊す | ❌ |
| U11 | `~/.claude` | `70_claude/install.{sh,zsh}` | 公式 installer の**前に**、`~/.claude` が rayrc の symlink でなければ（ディレクトリ・ファイル・他人の symlink・壊れた symlink）`~/.claude_rayrc_bkup_<timestamp>` へ mv し、`libs/claude/.claude` へ symlink する（PS の W4 と同じ順）。以前は installer の後に張っていたので、ユーザーの設定が無くても初回は installer が作っただけの `~/.claude` が退避されていた（このホストの `~/.claude_rayrc_bkup_20260911_021012` がそれ。中身は空の `downloads/` / `sessions/` と `backups/` の 1 ファイル）。`~/.claude.json` は `$HOME` 直下のままで対象外 | ❌ 戻さない。`libs/claude/.claude`（**認証情報と履歴**）ごと消える |
| U12 | `~/.local/bin/claude` ほか | 公式 installer | — | ❌（rayrc の管理外。§4 Q4） |
| U13 | `~/.gitconfig` のキー 11 個 | `10_viewer/20_git/install.sh` | 値が未設定のときだけ書く（✅ 壊さない） | ❌ 戻さない。`credential.helper store` によって `~/.git-credentials` が平文で残る |
| U14 | `~/.docker/cli-plugins/docker-compose` | `40_docker/install.sh` | **退避せずに `cp -f`** する | ❌ |
| U15 | `/etc/sudoers.d/9527-ray`（NOPASSWD:ALL） | `08_shell/10_sudo/install.sh` | 上書きする | ❌ **権限が残り続ける** |
| U16 | `~/.cache/lf`、`~/.terraform.d/plugin-cache` | lf install / terraform main | mkdir するだけ | 放置してよい |
| U17 | VS Code 拡張の `extension.js`（+ `.bak`） | `70_claude/main.sh`（シェル起動ごと） | `sed -i.bak` | 放置してよい（拡張を更新すれば元に戻る） |
| U18 | OS のパッケージ（git / curl / grep、pacman） | `00_bin`、`70_niri/70_arch` | — | 対象外が妥当（§4 Q2） |

### 1.2 Windows

| # | 足跡 | 書く場所 | 既にあるものの扱い | 現状の uninstall |
|---|------|---------|-----------------|----------------|
| W1 | `$PROFILE` の managed block | `src/install.ps1` | 変更するたびに `$PROFILE.rayrc.bak` へ `-Force` でコピーする | ❌ uninstall が無い |

PowerShell の W4 / W5 の退避と junction は `src/common.ps1` の `__rayrc_link_dir` / `__rayrc_backup_item` に集めてある。§3 の helper ができたら、ここを差し替える。
| W2 | Scoop 本体と各パッケージ（dialect_parity §2 の「Scoop」の行すべて。databricks 用に extras bucket も足す） | 各 `install.ps1`（未接続。dialect_parity の G1） | 既に入っていれば何もしない | ❌ |
| W3 | `ExecutionPolicy RemoteSigned`（CurrentUser） | `00_bin/install.ps1` | 上書きする | ❌（§4 Q2） |
| W4 | `~/.claude`（junction → `libs/claude/.claude`） | `70_claude/install.ps1` | U11 と同じ順（退避 → junction → installer） | ❌ |
| W5 | `~/vimfiles`（junction）、`~/_vimrc`、`~/.vimrc` | `04_text/20_vim/install.ps1` | vimfiles は W4 と同じ。`_vimrc` / `.vimrc` は `<name>_rayrc_bkup_<timestamp>` へ退避する | ❌ |
| W6 | `~/.gitconfig` のキー 10 個（`credential.helper` を除く） | `10_viewer/20_git/install.ps1` | 未設定のときだけ書く | ❌（U13 と同じ） |
| W7 | Claude Code の launcher（`~/.local/bin` など）と、それを足すユーザーの PATH | 公式 installer | — | ❌（U12 と同じく管理外） |

---

## 2. 問題の分類

| 分類 | 内容 | 該当 |
|------|------|------|
| **A. 退避先が自壊する** | 退避先が `~/.rayrc` の中にある。uninstall も「消して clone し直す」手順も、退避したものを一緒に消す | U4, U6, U8 |
| **B. 退避せずに壊す** | 削除・上書き・symlink の張り替え | U2, U5, U7, U9, U14 |
| **C. 2 回目の実行で壊れる** | ① vim / tmux: 退避の後でユーザーがまた `~/.vim` を作ってから再 install すると、`mv` が `__rayrc_backup/.vim/.vim` に入れ子にする（ファイルなら前回の退避を上書きする）。② PS: 変更のたびに `.rayrc.bak` を上書きするので、2 回目以降は **rayrc 導入前の状態ではなく、直前の状態**になる | U4, U6, U8, W1 |
| **D. 作ったものを片付けない** | | U3, U13, U14, U15, U6 / U11 の壊れた symlink |
| **E. uninstall の制御** | ① rc が無いと `rm -rf` まで丸ごとスキップする。② 自分自身を source している最中に root を `rm -rf` する。③ uninstall phase がどこにも無い。④ PS にはそもそも無い | `src/uninstall.{sh,zsh}` |
| **F. 既存のバグ** | **F2**: `10_sudo` は `sudo_username` を計算しているのに使わず、`${USER}` を書いている（F1 として挙げた tmux のパスの件は誤認だったので取り下げた。`libs/viewer/tmux/.tmux.conf*` は data dir の直下に追跡されている） | U15 |
| **G. user state が data plane にある** | `libs/claude/.claude`（認証情報）と `libs/viewer/atuin/data`（シェルの履歴）は、作り直せる生成物ではなくユーザーのデータ。今の uninstall も再インストールの手順も、これを消す（前回のストーリー `20261118_unify_module_tree` §7 でも警告済み） | U11, atuin |

---

## 3. あるべき契約（案・要合意）

### 3.1 振る舞い

1. **退避は「rayrc 導入前の状態」を 1 世代だけ持つ。** 対象のパスを rayrc が初めて触る瞬間に 1 度だけ取る。既に記録があれば取らない。rayrc 自身が置いたもの（自分の root を指す symlink、自分の managed block）は退避しない。
2. **manifest に記録する。** 1 行 = `{path, kind, origin}`。kind は `moved`（退避した） / `created`（rayrc が新しく作った） / `rc-block` / `git-config`（キーと、元の値の有無）など。
3. **uninstall は manifest を逆順に戻す。** 戻す前に、**今そこにあるのが rayrc の置いたものか**を確かめる（symlink の向き先、managed block かどうか）。違っていれば、ユーザーがその後に手を入れたとみなして触らず、警告だけ出す。戻せた行は manifest から消すので、途中で失敗しても再実行で続きから戻せる（self-healing）。
4. **退避先は `~/.rayrc` の外に置く**（候補: `${XDG_STATE_HOME:-$HOME/.local/state}/rayrc/`。Windows は `$env:LOCALAPPDATA\rayrc\`）。こうすると、`rm -rf ~/.rayrc` → clone し直しても退避が残る。そして再 install 時には、`~/.vim` などは rayrc の（壊れた）symlink なので、**再び退避されることなく**元の 1 世代が保たれる。
   - これは I3（生成物は data plane へ）の例外になる。その理由は「data plane は rayrc と一緒に消えるが、退避は rayrc より長く残らなければならない」から。
5. **user state は「消さない」を既定にする**（G）。uninstall は `libs/` の中で user state に当たるパスだけを残すか、退避先へ移す。どれが user state かは、モジュールが宣言する（例: data dir の中に `.rayrc-state` を置いて列挙する）。

### 3.2 構造

- **共通の helper**（`common.sh` / `common.zsh` / `common.ps1`）:
  - `__rayrc_place_link <target> <link>`: 退避 → 記録 → `ln -snf`（vim / claude / 将来の dotfiles）
  - `__rayrc_place_copy <src> <dest>`: 退避 → 記録 → cp（tmux / docker-compose）
  - `__rayrc_record_created <path>`: `.bash_profile` / sudoers など
  - `__rayrc_git_config_ensure` を 20_git から common に上げ、自分が書いたキーを記録する
- **モジュールの uninstall.sh は、manifest で表せないものだけに書く**（scoop で入れたパッケージのうち rayrc が入れたもの、など）。facade の uninstall phase は今のまま使える。
- **トップレベルの uninstall**: manifest を逆順に戻す → rc block を消す → user state を逃がす → root を消す。root の削除は、source している自分自身を消すことになるので最後に回す。

### 3.3 個別の修正（契約とは別にコミットする。I5）

- F2（sudo の変数）。dialect_parity の P3 で修正する
- U2: `HISTSIZE` の行を消す代わりに、rayrc 側で後から上書きできているかを確認する。消さないで済むなら消さない（未確認）
- U10: `~/.tmux` を退避の対象から外す

---

## 4. 決めてほしいこと

| ID | 論点 | 選択肢 / 推奨 |
|----|------|-------------|
| **Q1** | 退避先 | **`~/.local/state/rayrc/`（推奨）** / `~/.rayrc.backup/` / data plane のまま |
| **Q2** | host 全体に及ぶ変更（OS のパッケージ、`/etc/sudoers.d`、Scoop 本体、ExecutionPolicy）も uninstall で戻すか | 推奨: **sudoers だけは戻す**（権限が残るため）。パッケージは戻さず、一覧を表示するだけにする |
| **Q3** | rayrc が書いた `git config --global` のキーを uninstall で消すか | 推奨: 消す（rayrc が書いたと記録されているものだけ） |
| **Q4** | claude の公式 installer が入れたもの（`~/.local/bin/claude` ほか）を対象に含めるか | 推奨: 含めない（rayrc は呼んだだけ） |
| **Q5** | user state（claude の認証情報、atuin の履歴）を uninstall でどう扱うか | **残して、どこに置いたかを表示する（推奨）** / 確認してから消す / 消す |
| **Q6** | 今のユーザーの再インストール手順（`rm -rf` → clone → install）を残すか、代わりの手段を用意するか | 推奨: install は冪等なので `git pull && source ./install` で足りる。データを作り直したいときのために `uninstall --keep-state` を用意する |
| **Q7** | 既存ホストの移行 | manifest が導入される前に退避されたもの（`libs/text/vim/__rayrc_backup/`、`~/.claude_rayrc_bkup_*`、`$PROFILE.rayrc.bak`）を、初回の install で新しい退避先へ取り込むか |
