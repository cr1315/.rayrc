# rayrc: Unified Module Tree 移行指示書 (v3)

> 対象: Claude Code（VS Code 拡張）。このファイルを作業ツリー直下に置き、フェーズ単位で実行させる。
> 各フェーズ完了時に「受け入れ基準」の結果を報告し、**次フェーズへ進む前にユーザの承認を待つ**こと。

---

## 0. 目的

control plane は `bash/` `zsh/` `powershell/` の 3 ツリーに**シェル単位でパーティション**されている。一方、data plane（`libs/`）は 1 本で、パスは「control plane の相対パスから番号プレフィックスを外したもの」で決まる。主キーが食い違っているため、構造変更のたびに 3 ツリーを手で追従させる必要があり、zsh・PowerShell はすでにドリフトしている。

これを**ツール（モジュール）単位の 1 ツリー**に再パーティションする。

```
Before:  <shell>/<group>/<tool>/<phase>.<ext>      … シェルが主キー
After:   src/<group>/<tool>/<phase>.<ext>      … ツールが主キー、シェルは拡張子（属性）
         libs/<group>/<tool>/...                   … data plane（不変）
```

**戦略: 合流の前に同型化する。** 各ツリーをそれぞれの場所で bash と同じトポロジーに整えてから重ねる。統合フェーズ（P4）自体は、衝突ゼロの単純な重ね合わせにする。

---

## 1. 設計原則（Invariants）

| # | 原則 | 帰結 |
|---|------|------|
| I1 | **ディレクトリ = ツールの同一性。拡張子 = 方言。** `.sh`=bash、`.zsh`=zsh、`.ps1`=PowerShell | 未対応 = ファイルが無いだけ。新シェル = 新拡張子 |
| I2 | control plane は `src/`、data plane は `libs/` の各 1 本。写像規則（各階層の先頭 3 文字を外す）は不変 | `src/04_text/10_bat/` ↔ `libs/text/bat/` |
| I3 | **control plane は 100% git 追跡物のみ**。生成物は data plane に置き、ignore して install 時に動的生成する | `git pull` だけで control plane の移行が完結する |
| I4 | ロード順 = `NN_name` の **ordinal（C ロケール / バイト順）**。全方言で共通 | 番号の意味（C1–C5）は方言をまたいで共有 |
| I5 | **移動コミットに振る舞い変更を混ぜない（逆も同様）** | `git log --follow` と差分レビューが成立する |
| I6 | source される補助ファイルも方言の拡張子を持つ（`functions.sh` / `functions.zsh` / `functions.ps1`） | 同一ディレクトリで名前が衝突しない |
| I7 | 単独実行スクリプト（shebang 付き、source されない）は拡張子自由 | `90_misc/*.sh` 等はそのまま |
| I8 | 方言間で揃えるのは**契約**（ctl/data dir の写像、ロード順、`disabled`、`--filter`）であって**実装機構**ではない | bash の明示 delegate は動的スコープ前提。PS は別機構で同じ契約を満たす |

`.sh` が「POSIX sh」ではなく「bash」を意味するのは既知の命名負債として受け入れ、今回は変更しない。

---

## 2. 決定事項

| ID | 論点 | 決定 |
|----|------|------|
| D1 | control plane ルート名 | `bash/` → **`src/`** ✅ |
| D1' | data plane ルート名 | **`libs/` のまま** ✅（ホスト側に絶対パスが焼き込まれており、リネームのコストが名前の改善に見合わない） |
| D2 | グループ delegate | **bash/zsh は今回は明示 delegate のまま**（同一フォルダに方言別ファイルを置くだけ）✅。暗黙再帰への統一は長期 TODO |
| D2' | PS facade の意味論 | **最初から暗黙再帰**（I8。PS には移行すべき既存 delegate が無い）— 要確認 |
| D3 | 補助ファイル命名 | I6 に従う ✅ |
| D4 | シェル自身のグループ | `08_bash` / `08_zsh` / `powershell/10_powershell` → **`08_shell/`** — 要確認 |
| D5 | PS モジュール配置 | P3b の対応表（★）— 要確認 |
| D6 | 中身が空の PS スタブ | 移行せず削除 — 要確認 |
| D7 | 既存ホストの旧ディレクトリ残骸 | install 時に「追跡ファイル 0 件の旧ディレクトリ」だけ自動削除 — 要確認 |

---

## 3. 目標構造（抜粋）

```
.rayrc/
├── install / uninstall / install.ps1 / uninstall.ps1
├── src/                     # control plane（旧 bash/ + zsh/ + powershell/）
│   ├── common.{sh,zsh,ps1}  logger.{sh,zsh}
│   ├── install.{sh,zsh,ps1}  main.{sh,zsh,ps1}  uninstall.{sh,zsh}
│   ├── 00_bin/            install.sh main.sh install.zsh main.zsh install.ps1
│   ├── 04_text/           install.sh main.sh install.zsh main.zsh   ← bash/zsh の明示 delegate（PS 用は無し）
│   │   └── 10_bat/        install.sh main.sh install.zsh main.zsh
│   ├── 08_shell/
│   │   ├── 10_common/     main.sh exports.sh functions.sh | main.zsh alias.zsh functions.zsh | main.ps1 urldecode.ps1
│   │   ├── 10_sudo/       install.sh
│   │   └── 20_ohmyzsh/    draft.zsh
│   ├── 10_viewer/
│   │   ├── 10_fzf/        *.sh | *.zsh | install.ps1 main.ps1 ssh.ps1
│   │   ├── 22_ohmyposh/   install.ps1 main.ps1
│   │   └── 40_yazi/ ...
│   └── ...
└── libs/                        # data plane（不変）
```

---

## 4. フェーズ

### P0 — 作業環境と安全網（コード変更なし）

0.1 **作業はインストール先とは別の worktree で行う。**
```bash
cd ~/.rayrc && git worktree add ../rayrc-refactor -b refactor/unified-module-tree
```
   理由: `~/.rayrc` は稼働中のインストール先。`~/.bashrc` には `bash/main.sh` の絶対パスが入っており、`~/.claude` `~/.vim` は `libs/` 配下へのシンボリックリンク。インストール先で直接作業すると、移動の途中で作業中のシェル環境（と Claude Code 自身の設定）が中途半端な状態になる。

0.2 **ロード順リスター** `.ci/load_order.sh`
   - 引数: `--root <dir> --ext <sh|zsh|ps1> --phase <install|main>`
   - bash/zsh（明示 delegate の意味論）: ディレクトリに `<phase>.<ext>` があり、かつ `disabled` が無ければ列挙する。中身に `__rayrc_source_facade` を含む場合のみ再帰する。
   - ps1（現行）: ルート直下 1 階層の `main.ps1` のみ。ps1（P3b 以降）: 暗黙再帰の意味論（P3b 参照）。
   - 出力: ルートからの相対パスを実行順に 1 行ずつ。列挙は `LC_ALL=C`。

0.3 **ベースライン取得**（元の HEAD で取得し、`.ci/baseline/` に置く。コミット不要）
   - bash / zsh: `install` と `main` それぞれ。ps1: `main`。
   - ランタイムスナップショット（§5）: bash / zsh。

**受け入れ基準**: worktree が作られ、ベースライン 5 種とスナップショット 2 種が揃っていること。

---

### P1 — `.bashrc` 破壊バグの修正（最優先）

`bash/install.sh` が参照する `__rayrc_installed_name` は未定義。そのため `grep -q ""` は常に真になり、`sed '/.*main\.sh/ d'` が **`~/.bashrc` 中の `main.sh` を含む全行を削除する**。移行手順は「install 再実行」なので、放置すると移行のたびに必ず踏む。

- rc への登録を PowerShell と同じ**マーカー付き managed block**方式にする:
  ```
  # >>> rayrc >>>
  [[ -f "<abs>/main.sh" ]] && source "<abs>/main.sh"
  # <<< rayrc <<<
  ```
- 再実行時の動作: managed block があれば置換する。無ければ旧形式の行（`\.rayrc.*/main\.(sh|zsh)`）を削除してから追記する。
- BSD sed 対策として、zsh の `__rayrc_sed_inplace` を `bash/common.sh` に移植する。zsh 側の bootstrap も同じ方式にする。
- `uninstall` は managed block と旧形式の両方を除去する。
- **zsh で `~/.zshrc` が無いと何も登録されない問題は、ここでは直さない**（長期 TODO 参照）。

**受け入れ基準**: 旧形式の行と、無関係な `source ~/x/main.sh` 行を仕込んだ `~/.bashrc` に対して install を 2 回実行する。結果として、rayrc ブロックがちょうど 1 つあり、無関係な行が残っていること。

---

### P2 — control plane の生成物を data plane へ（I3）

- `10_viewer/10_fzf`: `${__rayrc_ctl_dir}/shell/fzf.{bash,zsh}` → `${__rayrc_data_dir}/shell/`（bash / zsh 両方）。`.gitignore` も data 側へ移す。
- `10_viewer/40_yazi`: `${__rayrc_ctl_dir}/completions/` → `${__rayrc_data_dir}/completions/`。ctl 側の `.gitignore` は削除する。
- data 側の `.gitignore` は `.claude/rules/libs.md` のパターン A に従う。
- 全モジュールを `__rayrc_ctl_dir}/` で grep し、ctl 側へ**書き込む**箇所が他に無いことを確認する。

**受け入れ基準**: Docker のランタイムスナップショットが P0 と一致すること（fzf/yazi の source 元パスの差分のみ許容）。

---

### P3 — 3 ツリーを同型にする（各ツリー内で完結。まだ合流しない）

#### P3a — bash / zsh の整形（移動のみ）
| 操作 | 内容 |
|------|------|
| `bash/08_bash` → `bash/08_shell` | data: `libs/bash`（あれば）→ `libs/shell` |
| `zsh/08_zsh` → `zsh/08_shell` | `libs/zsh/.p10k.zsh` → `libs/shell/ohmyzsh/.p10k.zsh`（現状どこからも参照されていない） |
| `zsh/10_viewer/10_fzf/functions.sh` → `functions.zsh` | `main.zsh` の source 行を更新（**別コミット**） |
| `zsh/08_shell/10_common/functions.sh` → `functions.zsh` | 同上 |
| `zsh/README.md` | `bash/README.md` に統合する |

- 移動には `.ci/mv_util.sh` を使える箇所では使う（bash 側のみ対応）。zsh 側は手動で、同じ data plane 写像に従う。
- `--filter` の衝突チェック: `shell` が他のトップレベル名の部分文字列になっていないこと。

#### P3b — PowerShell facade の新設とネスト化
**設計制約**: PS では、関数の中で dot-source したスクリプトの関数・エイリアス・変数は、その関数スコープに閉じ込められる。bash の「delegate が facade を呼び、その中で source する」パターンは、bash の動的スコープに依存しているため PS では使えない（I8）。
→ **列挙と dot-source を分離し、dot-source はトップレベルのループで行う。**

```powershell
# powershell/main.ps1（P4 後は src/main.ps1。プロファイルからトップレベルで dot-source される）
. "$PSScriptRoot/common.ps1"   # __rayrc_list_modules を定義
foreach ($__rayrc_m in (__rayrc_list_modules -Root $PSScriptRoot -LibsRoot <libs> -Phase main)) {
    $__rayrc_ctl_dir  = $__rayrc_m.CtlDir
    $__rayrc_data_dir = $__rayrc_m.DataDir
    . $__rayrc_m.Script
}
Remove-Item function:__rayrc_list_modules
Remove-Variable __rayrc_m, __rayrc_ctl_dir, __rayrc_data_dir -ErrorAction SilentlyContinue
```

`__rayrc_list_modules` の意味論（D2'、暗黙再帰）:
```
for each child (ordinal sort: [Array]::Sort($names, [StringComparer]::Ordinal)) of dir:
    skip unless directory; skip if it contains `disabled`
    if child/<phase>.ps1 exists        → emit {Script, CtlDir, DataDir}   # 自動再帰しない
    elif child is NN_* and has NN_* subdirs → recurse (CtlDir/DataDir を 1 段 push)
```
- data dir 写像は bash と同一（各階層の先頭 3 文字を外す）。`--filter` は PS install が module を走らせていない現状では未使用なので、今は実装しない。
- モジュール側の規約: キーハンドラなど**遅延実行される scriptblock の中で `$__rayrc_*` を参照しない**（ループ後に消える）。ロード時に値を確定させる（`$env:...` に入れる、または `.GetNewClosure()`）。
- `$PSScriptRoot\..\..\libs\...` のハードコード（`12_ohmyposh/main.ps1`、`20_yazi/main.ps1`、`12_ohmyposh/install.ps1` のコメント内）を `$__rayrc_data_dir` に置換する。
- Windows 専用モジュールのガードには `$env:OS -eq 'Windows_NT'` を使う。**`$IsWindows` は PS 5.1 では未定義（`$null`）なので使わない。**
- `.editorconfig` の `utf-8-bom` を維持する。

配置対応表（★は要確認）:

| 現在 | 移行先（powershell/ 内） | data plane | 備考 |
|------|------------------------|-----------|------|
| `00_bin/` | `00_bin/` | — | scoop bootstrap |
| `05_chocolatey/` | ★削除（空） | — | D6 |
| `05_windows_terminal/` | ★`05_terminal/10_windows_terminal/` | `libs/windows_terminal` → `libs/terminal/windows_terminal` | `libs/iterm2` も `libs/terminal/iterm2` に寄せるか要確認 |
| `07_vscode/` | ★`07_editor/10_vscode/` | — | 中身はコメント 1 行 |
| `10_powershell/` | `08_shell/10_common/` | — | `bkup/` → `docs/deprecated/powershell_profiles/`。`functions.ps1` は現在どこからも読まれていない（要確認） |
| `12_ohmyposh/` | ★`10_viewer/22_ohmyposh/` | `libs/ohmyposh` → `libs/viewer/ohmyposh` | 22 = git の後、atuin の前（将来 bash で使う場合の C3 対策） |
| `15_fzf/` | `10_viewer/10_fzf/` | — | |
| `20_yazi/` | `10_viewer/40_yazi/` | （既に `libs/viewer/yazi`） | |
| `60_rainmeter/` | ★削除（空） | — | D6 |
| `70_niri/`, `80_regedit_remediation/`, `80_vpn/`, `90_misc/` | 同名 | — | |

ロード順の意図的な変化: 旧 `10_powershell → 12_ohmyposh → 15_fzf → 20_yazi → 70_niri → 80_vpn` は、新 `08_shell/10_common → 10_viewer/10_fzf → 10_viewer/22_ohmyposh → 10_viewer/40_yazi → 70_niri → 80_vpn` になる。fzf と ohmyposh の間に ①② の依存は無い（Enter ハンドラと Ctrl+R で衝突しない）。

**P3 受け入れ基準**
- bash / zsh: `load_order.sh` の出力がベースラインと、`08_bash|08_zsh` ↔ `08_shell` の置換を除いて完全一致すること。ランタイムスナップショットも一致すること。
- PS: `mcr.microsoft.com/powershell` コンテナで全 `.ps1` を `Parser::ParseFile()` にかけて構文エラーが 0 件であること。`load_order.sh --ext ps1` の結果が上記の新ロード順と一致すること。
- **同型性チェック**: 3 ツリーの相対ファイルパス集合の積集合が空であること（`comm -12` を 3 ペアで実行）。空でなければ停止して報告する。
- Windows 実機確認チェックリストをユーザ向けに出力すること（PS 5.1 / 7 の両方）。項目は、プロファイル読み込みでエラーが出ないこと、ohmyposh、Ctrl+R の fzf、Ctrl+O の yazi と移動後の再描画、`ll` / `grep` エイリアス。

---

### P4 — `src/` への統合（純粋な重ね合わせ）

4.1 移動（コミット 1、rename のみ）: `bash/*` と `zsh/*` と `powershell/*` を `src/` へ移す。P3 の同型性チェックが通っているので上書きは起きない。念のため、移動先が存在したら即中止するスクリプトで実行する。

4.2 参照更新（コミット 2）:
- `install` / `uninstall`: dispatch 先を `src/` に変更する。
- `src/install.ps1`: managed block の中身を `$env:USERPROFILE/.rayrc/...` 固定から、**install 時に解決した絶対パス**に変える。マーカーが同じなので、既存のブロックはその場で置換される。ルートの `install.ps1`（0 バイト）からはここへ委譲する。
- `.ci/mv_util.sh`: `CTL_ROOT="src"` にし、引数から剥がすプレフィックスも `src/` にする。`write_delegate` は `.sh` 版に加えて `.zsh` 版も書く（PS 用は不要）。`validate_parent_groups` は `.sh` / `.zsh` の両方を検査する。
- `.claude/rules/bash.md` の `paths:` を `src/**` にする。`.claude/CLAUDE.md` から「Keep the two trees in sync」を削除し、I1–I8 の要約を載せる。
- `README.md`、`Dockerfile`、`.claude/skills/rayrc-docker-test/SKILL.md`（§5 のローカルマウント方式に書き換え）。
- `git grep -nE '\b(bash|zsh|powershell)/' -- ':!docs/' ':!libs/'` で残った参照を確認し、意図したものだけであること。

4.3 `.gitattributes` を追加する（同一ディレクトリに Windows で編集されるファイルが混在し始めるため）:
```
* text=auto eol=lf
install   text eol=lf
uninstall text eol=lf
*.png binary
```
`git add --renormalize .` の差分が 0 であること（現状は全ファイル LF）。

4.4 旧ディレクトリの自動掃除（D7）: `src/install.{sh,zsh}` の先頭で、`<root>/{bash,zsh,powershell}` が存在し、かつ `git ls-files` が空なら削除してログを出す。`## TODO(remove after 2026-Q2)` を付けておく。

**受け入れ基準**
- `load_order.sh --root src` の 3 方言の出力が、P3 の出力とルートの置換を除いて完全一致すること。
- Docker のランタイムスナップショット（bash / zsh）が P3 と一致すること。
- 移動コミットの `git show --stat -M` が rename のみであること。

---

---

## 5. 検証環境（push 不要のローカル Docker）

```bash
docker build -t rayrc-test .

# bash
docker run --rm -v "$PWD":/work:ro rayrc-test bash -c '
  cp -a /work /root/.rayrc && cd /root && source .rayrc/install &&
  bash -ic "alias -p; declare -F; env | sort; echo PC=\$PROMPT_COMMAND"' > /tmp/snap_bash.txt

# zsh
docker run --rm -v "$PWD":/work:ro rayrc-test bash -c '
  apt-get update -qq && apt-get install -y -qq zsh >/dev/null &&
  cp -a /work /root/.rayrc && cd /root && touch .zshrc && zsh -c "source .rayrc/install" &&
  zsh -ic "alias; print -l \${(k)functions}; env | sort; bindkey"' > /tmp/snap_zsh.txt
```
- 比較前に、パス中の `bash/` `zsh/` `powershell/` `src/` を `<CTL>/` に正規化する。`PWD` `SHLVL` `_` `OLDPWD` は除外する。
- GitHub からダウンロードするため、連続実行でレート制限に当たったら間隔を空ける。
- `git push` は deny 済み。既存の clone 方式の skill は使わない。

---

## 6. 長期 TODO（今回は実施しない）

| # | 項目 | メモ |
|---|------|------|
| T1 | **ssh() の正しい仕様を 1 本決め、bash / zsh を合わせる** | 現状: bash は `ssh -v host` のように 2 引数以上だと素通しになり、fzf 選択が効かない。zsh は 2 引数以上で `echo "parameters"` するだけで**実行しない**（デバッグの残骸）。0 件マッチ時の挙動も両者で異なる。要件: `ssh -v <pattern>` で fzf 選択と `-v` を両立する。注意: `-p 22` `-i key` `-L ...` のような**引数を取るオプション**があるため、OpenSSH の optstring に沿ってパースしないとホスト名の位置を誤判定する |
| T2 | facade の暗黙再帰化（bash / zsh を PS と同じ意味論へ） | 純粋なボイラープレート delegate を削除する。ガード付き（`70_niri/install.sh`）は残す。`60_iac/60_aws/install.sh` が到達可能になる（中身は空）。列挙のみ `LC_ALL=C` で行い、sourced モジュールに漏らさない。`mv_util.sh` の delegate 生成も廃止する |
| T3 | install を OS 軸の 2 本（Unix=bash / Windows=ps1）へ | `install.sh` と `install.zsh` の差分はほぼ GNU/BSD 差（`tar --transform` など）。シェル別に必要なのは main とシェル統合の生成物（`fzf --bash/--zsh`）のみ。前提として、bash 版 install の macOS 対応（`--transform` → `--strip-components`、bash 3.2 互換）が要る |
| T4 | zsh: `~/.zshrc` 不在時に作成して登録する | zsh は `.profile` / `.bash_profile` を読まない。起動順は `.zshenv` → `.zprofile`(login) → `.zshrc`(interactive) → `.zlogin`。対話的なログインシェルでも `.zshrc` を読むので、bash の `.bash_profile → .bashrc` のような橋渡しは不要。作成すれば `zsh-newuser-install` ウィザードも回避できる |
| T5 | CI の修復 | 現状、matrix は `ubuntu-22.04` なのに各 step の `if:` が `ubuntu-20.04` / `macos-11` を見ており、全 step がスキップされて常に緑。案: `shell: bash {0}`（`-e` を付けない）での install、`load_order.sh` の差分チェック、macOS での zsh、Windows での pwsh 構文チェック |
| T6 | `.claude/rules/` の方言別分割 | `src.md`（方言非依存）/ `dialect-zsh.md`（`**/*.zsh`）/ `dialect-ps1.md`（`**/*.ps1`） |
| T7 | `.ci/matrix.sh` | モジュール × {sh, zsh, ps1} × {install, main} の対応表を出す。統合後は「未移植」と「対象外」の区別が ls では見えなくなるため |
| T8 | PS install の facade 化 | モジュールの `install.ps1` を走らせる（現状 TODO）。`--filter` もここで実装する |
| T9 | 不要コードの整理 | `old.sh`、読まれていない `functions.ps1` |

---

## 7. 既存ホストの移行手順（README に追記する）

```bash
# Unix（bash / zsh 共通）— P4 の後
cd ~/.rayrc && git pull && source ./install
```
```powershell
# Windows
cd $env:USERPROFILE\.rayrc; git pull; . .\install.ps1
```
**注意**: 「クローンし直して入れ直す」方式は `libs/claude/.claude` の ignore 済みの中身（認証情報・履歴）を失うので使わない。将来 data plane を作り直す場合も、この 1 ディレクトリだけは退避すること。

install を再実行しない限り、旧 rc 行は `[[ -f 旧パス ]]` ガードによって**黙って何もしない**（エラーは出ないが環境が読み込まれない）。README の冒頭で告知すること。

---

## 8. Claude Code への作業ルール

- 作業は P0 で作った worktree の中だけで行う。`~/.rayrc`（インストール先）には触れない。
- フェーズごとに、変更概要 → 受け入れ基準の実行結果（差分そのもの）→ 想定外の差分、の順で報告し、承認を待つ。
- 受け入れ基準で**想定外の差分が 1 行でも**出たら、自分で辻褄を合わせず停止して報告する。
- コミット粒度は I5 に従い、`refactor(move):` / `refactor(ref):` / `fix:` / `feat(facade):` で区別する。
- 第三者由来のファイル（`gitstatus/`、`plugged/*` など）は触らない。
- 番号を付け替える必要が出たら、I4 と `.claude/rules/bash.md` の C1–C5 を再確認し、根拠をコミットメッセージに書く。
