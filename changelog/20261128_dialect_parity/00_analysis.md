# 方言パリティ: bash のツールを zsh / PowerShell へ — 00 分析

Nov 28, 2026（最終更新: Nov 28, 2026。進捗の詳細は `10_plan.md` §3）

方針（ユーザー指定）: PowerShell は基本 Scoop で入れる。zsh は bash と同じく GitHub Releases や公式の installer から取る。

確度の表記: **verified**（実行して確認） / **inferred**（コードを読んだうえでの推論） / **untested**（未検証）

凡例: ✅ 移植済み / — 対象外（理由はメモ欄）

---

## 0. 結論（現状）

1. **制御層は 3 方言とも同じ意味論になった**: 1 階層ずつ列挙し、明示 delegate のあるグループにだけ降りる（I8）。PowerShell の暗黙再帰はやめた（verified: pwsh 7 のコンテナ。PS 5.1 は untested）。
2. **移植は §2 の対象をすべて終えた**: zsh は Linux 上の zsh で、PowerShell は pwsh コンテナと偽の scoop で確認した。**macOS / Windows の実機では untested**。
3. **G1 も配線した**: `src/install.ps1` が各モジュールの `install.ps1` を facade 経由で走らせてから profile に登録する（`-Filter` 付き）。残りは実機での確認（`10_plan.md` §3）。

---

## 1. 前提: 制御層の同型性

### 1.1 契約ごとの比較

| 契約 | bash | zsh | PowerShell | 状態 |
|------|------|-----|-----------|------|
| 階層の深さ | 任意（delegate の連鎖） | 同左 | 同左（delegate の `foreach` の入れ子） | ✅ verified |
| data dir の写像（各階層の先頭 3 文字を外す） | `${__rayrc_package:3}` | 同左 | `__rayrc_module_enter` が 1 段ずつ積む | ✅ verified |
| 列挙の順序 | `ls -1`（locale 依存） | glob（locale 依存） | ordinal | 対処しない（D8） |
| 子へ降りる条件 | group の `<phase>.sh` が facade を呼ぶとき | 同左 | group の `<phase>.ps1` が `__rayrc_list_modules` のループを持つとき | ✅ 同じ意味論（D6） |
| `disabled` | ✅ | ✅ | ✅ | ✅ |
| `--filter` | ✅ | ✅ | ✅ `-Filter text,bat` | ✅ |
| install phase | ✅ | ✅ | ✅ `src/install.ps1` が facade を回す | ✅ |
| data dir の作成 | `__rayrc_module_common_setup` | 同左 | `__rayrc_module_enter` | ✅ |
| rc への登録 | `~/.bashrc` が無ければ作る | 同左（G4 で修正） | `$PROFILE` が無ければ作る | ✅ |

### 1.2 移植の前に潰すべきだった差

| # | 差 | 状態 |
|---|----|------|
| G1 | PowerShell の install phase が呼ばれない | ✅ P7 で配線した |
| G2 | 子へ降りる条件が方言で逆だった | ✅ P2 で解消（PS も明示 delegate）。足りなかった zsh / PS の delegate も追加した |
| G3 | bash / zsh の列挙順が locale 依存 | 対処しない（D8） |
| G4 | zsh: `~/.zshrc` が無いと登録されない | ✅ P3 で修正 |

---

## 2. 移植の対象と状態

### 2.1 単機能 CLI

| モジュール | zsh | PowerShell | メモ |
|-----------|:-:|:-:|------|
| `02_net/10_eget` | — | — | 削除した（D10） |
| `02_net/10_stu` | ✅ | — | PS: Windows 向けの release asset が無く、Scoop にも無い |
| `04_text/10_bat` | ✅ | ✅ Scoop | PS は `BAT_CONFIG_PATH` だけ（`MANPAGER` と常時の色付けは持ってこない） |
| `04_text/10_delta` | ✅ | ✅ Scoop | |
| `04_text/10_jq` | ✅ | ✅ Scoop | |
| `04_text/10_shfmt` | ✅ | — | PS: shfmt は PowerShell を整形できない |
| `04_text/10_yq` | ✅ | ✅ Scoop | |
| `04_text/20_vim` | ✅ | ✅ Scoop | PS: `~/vimfiles` を junction にし、`~/_vimrc` / `~/.vimrc` を退避する |
| `06_filesearch/10_eza` | ✅ | ✅ Scoop | `ll` / `la` / `lt` は 3 方言ともこのモジュールが持つ |
| `06_filesearch/10_fd` | ✅ | ✅ Scoop | |
| `06_filesearch/10_gdu` | ✅ | ✅ Scoop | |
| `06_filesearch/10_navi` | ✅ | ✅ Scoop | |
| `06_filesearch/10_rg` | ✅ | ✅ Scoop | |

### 2.2 シェルの状態に触るもの

| モジュール | zsh | PowerShell | メモ |
|-----------|:-:|:-:|------|
| `08_shell/10_common` | ✅ | ✅ | bash の install（`.bashrc` 専用の処理）は対象外 |
| `08_shell/10_sudo` | ✅ | — | |
| `10_viewer/10_fzf` | ✅ | ✅ Scoop | |
| `10_viewer/20_git` | ✅ | ✅（設定だけ） | PS: `credential.helper` を除く（D18）。プロンプトは ohmyposh |
| `10_viewer/30_atuin` | — | — | D12 |
| `10_viewer/40_yazi` | — | — | `disabled`（D11） |
| `10_viewer/48_lf` | ✅ | ✅ Scoop | |
| `10_viewer/48_lfscp` | — | ✅（既存） | D13 |
| `10_viewer/60_tmux` | ✅ | — | |

### 2.3 言語・インフラ・その他

| モジュール | zsh | PowerShell | メモ |
|-----------|:-:|:-:|------|
| `20_nodejs/10_fnm` | ✅ | ✅ Scoop | `FNM_DIR` は data plane |
| `20_nodejs/10_pnpm` | ✅ | ✅ 公式 installer | 3 方言とも `$PNPM_HOME/bin` を PATH に足す（D21） |
| `20_python/01_uv` | ✅ | ✅ 公式 installer | `libs/bin` に置く |
| `20_python/02_pipx` | ✅ | ✅ uv tool | |
| `20_python/21_poetry` | ✅ | ✅ uv tool | |
| `20_python/22_glances` | ✅（install） | ✅ uv tool | main は Synology 専用なので zsh / PS には持ってこない |
| `20_python/23_ansible` | ✅ | — | PS: Windows は control node として非対応 |
| `20_python/24_httpie` | ✅ uv tool | ✅ uv tool | `02_net` から移し、3 方言とも uv tool にした（bash も。D22） |
| `40_docker` | ✅（alias だけ） | — | zsh: docker が無ければ Apple の `container` に alias（D17） |
| `60_iac/60_aws` | ✅ | ✅ Scoop | `ecs.exec` も移植 |
| `60_iac/61_terraform` | ✅ | ✅ Scoop | |
| `60_iac/62_kubernetes` | ✅ | ✅ Scoop | PS: `k.conf` は移植しない（下の既存の不整合） |
| `60_iac/63_databricks` | ✅ | ✅（install だけ） | PS: main は sh の構文のファイルを読むだけ |
| `70_claude` | ✅ | ✅ 公式 installer | 3 方言とも、`~/.claude` の link を installer より先に張る（PS は junction。D19） |
| `70_niri` | — | — | D16（別のストーリー） |
| `80_homeassistant` | ✅ | — | |
| `80_hulft` | — | — | サーバー側の `utladmin` 専用 |
| `90_misc` | ✅ | — | zsh は `~/per_project_*.zsh` を読む |

逆方向の差（このストーリーの対象外）: `80_confluence` は zsh / PS にしかない。

### 2.4 既存の不整合（記録のみ。今は直さない）

- `60_iac/60_aws/iac.sh`（`aws.iac` を定義）はどの方言でも読み込まれていないので、`k.conf` から `aws.iac` を呼ぶと失敗する。使うときに直す（ユーザー判断）。
- 古いパスの submodule の登録（gitlink）は 2f6c053 で消したので、もう無い。
