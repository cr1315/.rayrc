# 方言パリティ — 10 計画

Nov 28, 2026 · 前提は `00_analysis.md`

## 1. 決定事項

| ID | 論点 | 決定 |
|----|------|------|
| D1 | zsh の install の軸 | **(a) bash と統合しない。** install.zsh は方言ごとに持つ。ただし、展開・配置のように共通化できる処理は `common.{sh,zsh}` の helper にする（P4） |
| D2 | Scoop の扱い | Scoop で入れたものは Scoop に管理させる（`libs/bin` へは寄せない）。rules への明記は今はしない |
| D3 | PS でツールのデータをどこに置くか | 公式の installer と環境変数で場所を指定できるもの（**uv、pnpm**）は data plane に向ける。atuin は PS に移植しないので対象外 |
| D4 | 移植の順番 | 保留（ユーザーが検討中）。下の P5 / P6 の中での順番は仮のもの |
| D5 | `libs/bin` を方言で分けるか | 分けない。実際の運用では、bash（Linux 群）と zsh（自宅の macOS）が同じホストで `libs/bin` を共有することはない。分けるかどうかは将来の検討事項 |
| D6 | PS facade の意味論 | **bash / zsh と同じく、1 階層ずつ列挙する明示 delegate にする**（暗黙再帰はやめる）。I8 を書き換える |
| D7 | G1（`src/install.ps1` から各モジュールの install を呼ぶ） | **このストーリーの最後にする**（P7）。それまでは、PS の install facade は作るが呼ばない |
| D8 | 列挙順の locale 依存（G3） | 対処しない（名前は `NN_` + 英小文字の運用なので差は出ない） |
| D9 | `~/.zshrc` が無い場合（G4） | bash と同じく、無ければ作る |
| D10 | eget | **削除する**（bash からも） |
| D11 | yazi | **`disabled` を置く**（全方言）。スクリプトには触らない |
| D12 | atuin | zsh / PS には移植しない |
| D13 | lfscp | 変更しない |
| D14 | tmux | zsh に移植する（tmux があれば設定する）。PS は対象外 |
| D15 | sudo | zsh も bash と同じ動きにする |
| D16 | 言語・インフラ（§2.3） | 基本は全部そろえる。**70_niri は対象外**（別のストーリーで扱う） |
| D17 | docker | Docker Desktop は入れない（mac / Windows とも）。**zsh: `container`（Apple）がある場合だけ alias を張る。インストールはしない。** PS: 対象外 |
| D18 | PS の git 設定 | `credential.helper` 以外を移植する（Windows の Git Credential Manager を平文保存で上書きしないため） |
| D19 | PS の Claude Code | 公式の installer で入れる。既存の `~/.claude` は退避し、`libs/claude/.claude` へ junction を張る（bash と同じ ad-hoc な退避。uninstall ストーリーで helper に置き換える） |
| D20 | `ll` / `la` / `lt` | 3 方言とも eza モジュールが持つ（bash / zsh は元からそう。PS は `08_shell` の `sal ll ls` を消して移した） |
| D21 | pnpm の bin | 3 方言とも `$PNPM_HOME/bin` を PATH に足す。`$PNPM_HOME/bin` を `libs/bin` への symlink にするのはやめる（install が古いレイアウトを自動で移行する） |
| D22 | httpie の置き場所 | `20_python/24_httpie` へ移す（PS では uv tool で入れるので、uv より後に読まれる必要がある。①） |

### 既定にしたもの（ユーザーが明示していない点。違えば指摘してほしい）

| 対象 | 既定 | 理由 |
|------|------|------|
| shfmt（PS） | 入れない | shfmt が整形できるのは sh / bash / mksh / bats / zsh で、PowerShell は整形できない（PowerShell の整形は PSScriptAnalyzer の `Invoke-Formatter` が担う） |
| stu（PS） | 入れない | Windows 向けの release asset が無く、Scoop にも無い（verified） |
| httpie の取得方法 | bash / zsh は今のまま（Linux は公式バイナリ、macOS は brew）。PS は `uv tool install httpie` | D22 は移動だけで、bash / zsh の振る舞いは変えていない。3 方言を uv tool にそろえるかは未決 |
| pipx / poetry / glances（PS） | `uv tool install` | bash と同じ取得方法（契約を合わせる） |
| ansible（PS） | 入れない | Windows は control node として非対応 |
| fnm（PS） | Scoop で入れ、`FNM_DIR` は data plane に向ける | bash と同じ契約。fnm には PS 用の公式 installer が無い |
| aws / terraform / kubectl / databricks（PS） | Scoop（databricks は Extras の `databricks-cli`） | |
| vim（PS） | 入れる。`~/vimfiles` は claude と同じく、退避してから junction を張る | D19 と同じ扱い |
| 80_homeassistant | zsh に移植する。PS は対象外 | |
| 90_misc（`per_project_*`） | zsh は `~/per_project_*.zsh` を読む | bash 用の `.sh` を zsh で読むと壊れるおそれがある |
| 80_hulft | 対象外 | サーバー側の `utladmin` 専用 |
| 解凍の共通化（D1） | `__rayrc_install_binary <file> <name>...` を `common.{sh,zsh}` に置く。展開して名前で探すので、`--transform` / `--strip-components` の違いが無くなる | P4 |

## 2. フェーズ

各フェーズの終わりに受け入れ基準の結果を報告する。コミットは I5 に沿って分ける。

| P | 内容 | 受け入れ基準 |
|---|------|-------------|
| **P1** | eget を削除する（`src/02_net/10_eget`、`libs/net/eget`、`bash.md` の記述）。yazi に `disabled` を置く | `load_order.sh` の出力から eget と yazi が消え、それ以外に差分が無いこと |
| **P2** | PS facade を明示 delegate にする（`common.ps1` / `main.ps1`、グループの `main.ps1` / `install.ps1` delegate）。`load_order.sh` の ps1 を sh / zsh と同じ walker にする。`mv_util.sh` が `.ps1` の delegate も作るようにする。I8 と `bash.md` を書き換える | pwsh コンテナで、(1) 全 `.ps1` の構文エラーが 0 件、(2) fixture tree での実行順が `load_order.sh` と一致すること（多階層、`disabled`、delegate の無いグループ、`-Filter`）、(3) 実際の `src/main.ps1` の読み込み順が P1 の後の `load_order.sh --ext ps1 --phase main` と一致すること |
| **P3** | zsh の `~/.zshrc` を作るようにする（G4）。バグ修正: sudo（F2） | Docker で、`~/.zshrc` が無い状態から zsh で install すると managed block が 1 つできること。2 回実行しても 1 つのままであること |
| **P4** | `__rayrc_install_binary` を作り、既存の bash / zsh の install をこれに置き換える | Docker で bash / zsh の install 後の `libs/bin` の中身（名前と実行属性）が P3 の後と一致すること |
| **P5** | zsh へ移植する: httpie, stu, sudo, tmux, fnm, pnpm, uv, pipx, poetry, glances, ansible, docker（alias のみ）, 60_iac ×4, claude, homeassistant, 90_misc。足りないグループ delegate を足す | Docker（Linux 上の zsh）で install → `zsh -ic` で各ツールの env / alias / 関数が bash と同じになること（`.ci/snapshot.sh` の差分）。macOS での確認はユーザーに依頼する |
| **P6** | PS へ移植する: 単機能 CLI（Scoop）、fzf install、git 設定、00_bin の PATH、uv / pnpm（公式 installer）、fnm、pipx / poetry / glances / httpie（uv tool）、aws / terraform / kubectl / databricks、claude、vim | pwsh コンテナで構文チェックと main の読み込み（バイナリが無いとガードで素通りすること）。Windows 実機の確認リストをユーザーに渡す |
| **P7** | G1: `src/install.ps1` から install facade を呼ぶ。`-Filter` を受け付ける | pwsh コンテナで、`-Filter` で絞った実行順が `load_order.sh` と一致すること。Windows 実機での確認はユーザーに依頼する |

## 3. 進捗（Nov 28, 2026 時点。すべてコミット済み）

| P | 状態 | 結果 |
|---|------|------|
| P1 | 済 | verified: `load_order.sh` の差分は eget と yazi の行だけ |
| P2 | 済 | verified（pwsh 7 / Linux コンテナ）: 構文、fixture（多階層・`disabled`・delegate の無いグループ・filter・スコープの保持・例外のあとも続くこと・後片付け）、実際の tree の読み込み順が `load_order.sh` と一致。**PS 5.1 は untested** |
| P3 | 済 | verified（Docker / zsh）: `~/.zshrc` が無い状態から 2 回 install しても block は 1 つ。F2 は root で `$USER` が空のとき、sudoers に壊れた行を書いて sudo 全体を壊しうるものだった |
| P4 | 済 | verified（Docker / bash・zsh）: `libs/bin` の名前・権限・`--version` が置き換え前と完全に一致し、残骸も無い。**macOS（bsdtar / BSD mktemp）は untested** |
| P5 | 済 | verified（Docker / Linux の zsh）: 全体の install が rc=0。`libs/bin` は bash から atuin / lfscp（対象外）を除いたものと一致。P5 で増えた env は bash と同じ値。compinit がある場合の completion は uv / fnm / pnpm で確認（aws / kubectl はイメージに無く untested）。**macOS は untested** |
| P6 | 済 | verified（pwsh 7 / Linux コンテナ）: 構文、ツール無しでの main の読み込み（表示される警告・エラーは 0）、helper（退避・link・冪等・子プロセスへの env）、偽の scoop での install facade の呼び出し順。**Windows 実機は untested** |
| D21 | 済 | verified（Docker / bash・zsh）: 新規 install、古いレイアウトからの移行、2 回目の実行。`pnpm bin -g` は `$PNPM_HOME/bin` で、PATH には 1 回だけ入る |
| D22 | 済 | verified: 3 方言のロード順で httpie が uv の後に来る。pwsh コンテナの install facade で、警告なしで httpie に到達する |
| P7 | 未着手 | ユーザーの判断待ち（D7） |

### 既存ホストで次の install 時に自動で起きること

- pnpm: `libs/nodejs/pnpm/bin` が `libs/bin` への symlink なら、それと `libs/bin/{pnpm,pnpx,pn,pnx}` を消して入れ直す（このホストも該当する）
- httpie: data plane は `mv_util.sh` が `libs/net/httpie` → `libs/python/httpie` へ移した。ほかのホストでは `git pull` の後、`libs/net/httpie`（設定が入っていれば）を手で `libs/python/httpie` へ移す必要がある（`HTTPIE_CONFIG_DIR` が変わるため）

### P5 / P6 で移植しなかったもの

| 対象 | 方言 | 理由 |
|------|------|------|
| `22_glances/main` | zsh / PS | 中身が Synology の TERMINFO 対策だけ |
| `40_docker/install`（compose plugin） | zsh / PS | D17 |
| `62_kubernetes` の `k.conf` | PS | 中で呼ぶ `aws.iac`（`60_aws/iac.sh`）が、どの方言でも読み込まれていない（既存の不整合） |
| `63_databricks/main` | PS | `~/.databricksenv`（sh の構文）を読むだけ |
| `04_text/10_bat` の `MANPAGER` / `--color always` alias | PS | man が無い。常時の色付けはパイプ先を汚す |

### 実機での確認（ユーザーに依頼）

**macOS（zsh）**
1. `source ./install`（`~/.zshrc` を消した状態でも可）→ 末尾の managed block が 1 つだけであること
2. `ls ~/.rayrc/libs/bin` に bat / delta / eza / fd / gdu / navi / rg / jq / yq / shfmt / fzf / lf / stu / uv / fnm / pipx / poetry / glances / ansible / claude があり、`ls ~/.rayrc/libs/nodejs/pnpm/bin` に pnpm があること（bsdtar での展開の確認）
3. 新しい zsh で `echo $FNM_DIR $PNPM_HOME $UV_TOOL_DIR`、`type ha_api`（`HASS_TOKEN` を設定した場合）、Apple の `container` を入れている場合は `type docker`
4. `http --version`（brew の httpie）

**Windows（PowerShell 5.1 と 7 の両方）**
1. プロファイルの読み込みでエラーが出ないこと（ツールが入っていない状態で）
2. ohmyposh、Ctrl+R の fzf、Ctrl+O の lf が今までどおり動くこと（facade の差し替えの回帰確認）
3. `ll`（eza があれば eza、無ければ Get-ChildItem）
4. 各モジュールの `install.ps1` は facade の変数（`$__rayrc_data_dir` など）に依存しているので、単体では実行できない。install の確認は P7 で配線してから行う
