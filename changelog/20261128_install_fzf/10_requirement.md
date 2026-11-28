# install --fzf と、macOS の eza / navi（mise）— 10 要件・調査・計画

Nov 28, 2026

> 原文（ユーザー）: install --fzfでfilterはrayrcがつくる、ユーザは上下で移動してselectするだけ

**スコープ**: (A) `source ./install --fzf` で、filter の文字列は rayrc が組み立て、ユーザーは fzf で選ぶだけにする。(B) macOS で eza / navi の取得に失敗する件を、mise を使って直す。

確度の表記: **verified**（実行して確認） / **inferred**（コードやドキュメントを読んだうえでの推論） / **untested**（未検証）

---

## 0. 結論

1. **eza は GitHub release に macOS 向けのバイナリを出していない。navi は最新の v2.24.0 だけ出し忘れている**（v2.23.0 と v2.25.0-beta1 にはある）。どちらも rayrc のバグではない（verified: GitHub API）。
2. **mise を使えば macOS でも取れる**。`mise lock --platform macos-arm64,macos-x64` で URL と sha256 が解決でき、その darwin 向け tarball を実際に落とすと、checksum が一致し、中身は Mach-O arm64 の実行ファイルだった（verified。Mac の上で実行はしていない）。
   - eza: vfox-eza → `cargo-bins/cargo-quickinstall` の `eza-0.23.5-*-apple-darwin.tar.gz`（第三者によるビルド）
   - navi: aqua → 上流の `navi-v2.23.0-*-apple-darwin.tar.gz`（**latest の 2.24.0 は mise でも "not available"**。2.23.0 に落とす必要がある）
3. **落とし穴**: `mise install-into` は vfox plugin が未導入だと自分では入れず、`--yes` / `MISE_YES=1` を付けても失敗する。先に `mise install` を一度通せば plugin が入り、そのあとの `install-into` は通る（verified: Linux で 3 回再現、回避策も確認）。macOS の eza は vfox 経由なので、ここに当たる（inferred）。
4. mise は uv / fnm と同じく、`MISE_DATA_DIR` などで置き場所を rayrc 配下に閉じ込められる（verified）。
5. `--fzf` は小さく作れる。列挙の規則を facade から切り出し、facade と候補作りの両方で使うのが要点（§1.3）。

---

## 1. (A) `install --fzf`

### 1.1 要件（決定済み）

| # | 要件 | 出典 |
|---|------|------|
| R1 | `source ./install --fzf` で fzf を開く。候補（filter として有効なもの）は rayrc が組み立てる | 原文 |
| R2 | 選べるのは **1 つだけ**（上下で動かして Enter）。グループを選べばグループ全体が入る。選んだものを filter にして、普段と同じ install を走らせる | 原文、Q1 |
| R3 | fzf が無ければ help を出して止める（何も入れない） | 会話 |
| R4 | 主な用途は 2 回目以降（更新・再インストール） | 会話 |
| R5 | 照合の規則は今の `--filter` のまま（部分一致）。`lf` を選ぶと `lfscp` も入るのは仕様として受け入れる | Q2 |

### 1.2 今の `--filter` の意味論（inferred: `src/common.{sh,zsh,ps1}` を読んだ）

- 階層 1 段ごとに、カンマ区切りのトークンを 1 つ消費する。そのトークンに**部分一致**する子だけを回す。`*` はすべてに一致する。
- トークンを使い切ったら、その下は全部回る。つまり `text` = text グループ全体、`text,bat` = bat だけ。
- `10_viewer` の下では `lf` が `48_lf` と `48_lfscp` の両方に一致する（R5 で受け入れた）。

### 1.3 設計

**候補**: facade と同じ規則で、install phase の木を辿る。つまり、`install.<ext>` があり、`disabled` が無ければ候補にし、delegate（facade を呼んでいる）なら中へ降りる。並びは load order と同じ。方言ごとに `install.<ext>` があるかどうかが違うので、候補も方言ごとに変わる（今の数: sh 40 / zsh 34 / ps1 39。`.ci/load_order.sh` で確認、verified）。

```
表示              filter に渡すもの（ディレクトリ名そのもの。番号付きの方が照合が狭い）
bin               00_bin
text              04_text
text/bat          04_text,10_bat
filesearch/eza    06_filesearch,10_eza
```

実行前に `--filter 04_text,10_bat` のように 1 行表示する。これで、次からは同じものを手でも書ける。

**境界**:
| 置くもの | 場所 | 理由 |
|---------|-----|------|
| 1 段分の列挙（`install.<ext>` がある・`disabled` が無い・ordinal 順）を `__rayrc_list_modules <dir> <phase>` として切り出す | `src/common.{sh,zsh}` | facade と候補作りの**両方**が使う。今の bash / zsh は facade の `for` の中で列挙と実行が一緒になっているので、候補作りを別に書くと規則が 2 つになる。PowerShell は既に `__rayrc_list_modules` で分けてある（`src/common.ps1`）ので、名前も揃えられる |
| 候補を作り、fzf を開き、選ばれたものを `__rayrc_install_filter` に入れる | `src/install.{sh,zsh}` | install でしか使わない。`common.*` は `main.*` からも毎回 source されるので、そこには置かない |
| `--fzf` の解釈 | `__rayrc_parse_args`（`src/common.{sh,zsh}`） | `--filter` と同じ場所に置く |

`.ci/load_order.sh` は CI 用の道具で、control plane の外にある。実行時にはそれに頼らない。

**fzf の探し方**: `${__rayrc_bin_dir}/fzf` → `command -v fzf` の順。install の最中は `libs/bin` が PATH に入っていないことがあるため。

**終わり方**:
| 状況 | 振る舞い |
|------|---------|
| fzf が無い | 「先に `source ./install`（全部）か `--filter viewer,fzf` を実行して」という help を出して `return 8`。何も入れない |
| Esc / Ctrl-C で抜けた | 何も入れずに終わる（`return 0`） |
| `--fzf` と `--filter` を一緒に指定 | エラーにする |

**冪等性**: `--fzf` は filter を決めるだけで、その後は普段の install と同じ経路を通る。2 回目に実行したときの振る舞いは各モジュールで決まり、`--fzf` が新しく持ち込むものは無い（inferred）。

### 1.4 範囲の外

- PowerShell の `-Fzf`（bash / zsh を先にやる。I8 に従い、後で揃える）
- `uninstall --fzf`、fzf の preview、複数選択

---

## 2. (B) macOS で eza / navi が「could not retrieve binary」になる原因（verified: GitHub API、2026-11-28 時点）

| tool | GitHub release の macOS 向け asset | rayrc の今の分岐 |
|------|--------------------------------|---------------|
| eza v0.23.5 | **無い**。linux（gnu / musl / arm）と windows だけ。macOS は以前から出していない | `*)` に落ちて warn を出し、`return 8` |
| navi v2.24.0（latest） | **無い**（この版だけ）。v2.23.0 と v2.25.0-beta1 にはある | 同上（macOS の分岐そのものが無い） |

---

## 3. mise

### 3.1 mise 本体の入れ方（verified: `https://mise.run` を読み、/tmp で実際に入れた）

```bash
curl -fsSL https://mise.run | env MISE_INSTALL_PATH="${__rayrc_bin_dir}/mise" MISE_INSTALL_HELP=0 sh
```

- `MISE_INSTALL_PATH` はファイルのパスで指定する（ディレクトリを渡すとエラーになる）。
- rc ファイルは書き換えない（最後に `activate` の案内を表示するだけで、`MISE_INSTALL_HELP=0` で消せる）。
- checksum を必ず検証する。glibc / musl も自分で判定する。
- 既に入っている版の方が新しければ何もしない。2 回目の実行は no-op になる。勝手に上がることも無い（上げるときは `mise self-update` か `MISE_VERSION`）。
- `.claude/rules/bash.md` の取得方法の優先順位 1（公式 installer。uv と同じ形）にそのまま当てはまる。

### 3.2 置き場所を閉じ込める（uv / fnm と同じ使い方）（verified: Linux）

| env | 役割 | rayrc での置き場所 |
|-----|-----|---------------|
| `MISE_DATA_DIR` | `installs/<tool>/<ver>`、`plugins/`、`shims/`、`downloads/` | `libs/net/mise/data` |
| `MISE_CONFIG_DIR` / `MISE_GLOBAL_CONFIG_FILE` | `mise use -g` が書く global config | `libs/net/mise/config` |
| `MISE_CACHE_DIR` / `MISE_STATE_DIR` | cache / trust の状態など | `libs/net/mise/cache` / `state` |

これら全部を sandbox に向けて `mise use -g navi@latest` を実行すると、`~/.local/share/mise` と `~/.config/mise` は作られなかった（verified）。

PATH への出し方には、`mise activate`（プロンプトごとに hook が走る。`PROMPT_COMMAND` / `precmd` を触るので、C2 / C3 と同じ種類の②の制約が生まれる）と、`shims/` を PATH に足す（hook は不要）の 2 通りがある。**今回はどちらもしない**（eza / navi は `libs/bin` に置くので、要らない）。

### 3.3 macOS での取得経路（verified: `mise lock --platform macos-arm64,macos-x64` と、実際に落としたもので確認）

| 実行するもの | backend | URL | 結果 |
|------------|---------|-----|-----|
| `eza@latest` | `vfox:jdx/vfox-eza`（mise の registry では、aqua の定義が `platforms = ["linux"]` なので、macOS では vfox になる。inferred） | `cargo-bins/cargo-quickinstall/releases/download/eza-0.23.5/eza-0.23.5-{aarch64,x86_64}-apple-darwin.tar.gz` | sha256 が一致。tar の直下に `eza` があり、Mach-O arm64 |
| `navi@latest`（2.24.0） | `aqua:denisidoro/navi` | — | **"not available for macos-arm64, macos-x64"** |
| `navi@2.23.0` | `aqua:denisidoro/navi` | 上流の `navi-v2.23.0-{aarch64,x86_64}-apple-darwin.tar.gz` | sha256 が一致。`./navi` があり、Mach-O arm64 |

### 3.4 `install-into` と plugin（verified: Linux x64、mise 2026.11.14）

| 試したこと（data dir は毎回空から） | 結果 |
|-------------------------------|-----|
| `install-into navi@latest <dir>`（aqua） | 成功。`<dir>/navi` |
| `install-into eza@latest <dir>`（Linux では aqua） | 成功。`<dir>/eza` と `<dir>/.mise-bins/eza` |
| `install-into vfox:jdx/vfox-eza@latest <dir>` | **失敗**（3 回とも）。`asdf plugin vfox-jdx-vfox-eza is not installed` / `run with --yes ...` |
| 同じものに `--yes` / `MISE_YES=1` を付ける | **失敗**（3 回とも）。同じエラー |
| `mise install vfox:jdx/vfox-eza@latest` のあとに `install-into` | **成功**。`plugins/vfox-jdx-vfox-eza` ができ、`<dir>/eza` が置かれた |

→ macOS の eza では、`install-into` の前に `mise install` を一度通す（plugin を入れるため）。`installs/` に 1 部余計に残るが、`MISE_DATA_DIR` は `libs/net/mise/data` の中なので、外には漏れない。

### 3.5 トレードオフ・リスク

| 項目 | 内容 | 確度 |
|------|------|-----|
| 第三者によるビルド | macOS の eza は cargo-quickinstall 経由になる（上流が出していないため。mise を使っても使わなくても同じ） | verified |
| navi の pin | macOS は `2.23.0` に固定する。上流が darwin 版を出し直したら外す。代わりに「latest を試し、だめなら 2.23.0」にすると、上流が直れば勝手に戻る（§5 の案） | inferred |
| GitHub rate limit | vfox-eza は版の一覧を GitHub API で取る（`GITHUB_TOKEN` があれば使う）。今の `__rayrc_github_downloader` は HTML を scrape するので、API の制限を受けない | inferred |
| ①「install-time」の依存が初めて生まれる | `06_filesearch/10_{eza,navi}` の install が `02_net/00_mise` に依存する。ordinal では `02` < `06` なので順序は満たす。`.claude/rules/bash.md` の制約表に C6 として足す。`--filter filesearch,eza` のように mise を含まない filter のときは、mise が無ければ「先に `--filter net,mise`」と warn を出して `return 8` | inferred |
| 置き場所が暫定 | mise は network / transfer の道具ではないが、新しいトップレベルのグループを作らないために `02_net` に置く（ユーザーの判断）。後でグループを作るときは `.ci/mv_util.sh` で動かす | — |
| Linux の挙動 | 変えない。eza の x86_64 は musl 版のまま（mise に任せると gnu 版になり、glibc の古いホストで動かないおそれがある。§3.4 で mise が gnu 版を選んだのを確認した） | verified（mise が選んだもの）/ inferred（動かないおそれ） |

### 3.6 Mac で一番安く確かめる方法（zsh。/tmp だけを使い、rayrc は触らない）

```zsh
d=$(mktemp -d)
curl -fsSL https://mise.run | MISE_INSTALL_PATH=$d/mise MISE_INSTALL_HELP=0 sh
export MISE_DATA_DIR=$d/data MISE_CACHE_DIR=$d/cache MISE_CONFIG_DIR=$d/config MISE_STATE_DIR=$d/state MISE_GLOBAL_CONFIG_FILE=$d/config/config.toml
$d/mise install-into eza@latest $d/eza                                          # 失敗する見込み（§3.4）
$d/mise install eza@latest && $d/mise install-into eza@latest $d/eza && $d/eza/eza --version
$d/mise install-into navi@latest $d/navi                                        # 失敗する見込み（§3.3）
$d/mise install-into navi@2.23.0 $d/navi && $d/navi/navi --version
echo $d
```

### 3.7 Mac で実行した結果（verified: ユーザーの Mac、macos-arm64、2026-11-29）

§3.6 の見込みどおりだった。eza は `install-into` を単独で実行すると plugin が無くて失敗し、`mise install` を通したあとは `eza v0.23.5` が動いた。navi は latest が `unsupported env: darwin/arm64` で失敗し、`2.23.0` を指定すると動いた。

→ mise で取ることはできる。ただし eza は 2 手順かかり、navi は版の pin が要る。そこで、mise は入れたうえで、eza / navi は curl で直接取る方法を検討した（§3.8）。

### 3.8 curl で直接取る（Homebrew の bottle / cargo-quickinstall）（verified: Linux 上で落として Mach-O を読んだ。Mac での実行はしていない）

**Homebrew の bottle**: `https://formulae.brew.sh/api/formula/<f>.json` の `bottle.stable.files.<tag>` に、`url`（ghcr.io の blob）と `sha256` がある。ghcr.io からは、`Authorization: Bearer QQ==`（brew 自身が使っている匿名 token）を付ければ curl で落とせた。sha256 も一致した。

| tool | bottle の中のバイナリが読む dylib（LC_LOAD_DYLIB） | curl だけで動くか |
|------|-----------------------------------------|---------------|
| navi 2.24.0 | `/usr/lib/libiconv.2.dylib`、`/usr/lib/libSystem.B.dylib` だけ | **動く見込み**。arm64_sonoma / sequoia / tahoe の各 tag とも `minos 11.0` なので、ホストの macOS のコードネームに合わせて tag を選ぶ必要も無い |
| eza 0.23.5 | **`@@HOMEBREW_PREFIX@@/opt/libgit2/lib/libgit2.1.9.dylib`**（brew が pour するときに書き換える placeholder のまま）と system libs | **動かない**。libgit2 の bottle も取ってきて、`install_name_tool` で書き換え、`codesign` で署名し直す必要がある。簡単とは言えない |

**cargo-quickinstall**（mise の vfox-eza が macOS で使っているもの）:

| tool | 読む dylib | 最低 macOS |
|------|----------|-----------|
| eza 0.23.5（aarch64） | system libs と Security / CoreFoundation framework だけ（**libgit2 は静的リンク**） | 11.0 |

curl 2 回で済む: (1) `https://github.com/<repo>/releases/latest` の redirect 先（`Location`）から版を取る（API を使わないので rate limit に当たらない）、(2) `https://github.com/cargo-bins/cargo-quickinstall/releases/download/<tool>-<ver>/<tool>-<ver>-<arch>-apple-darwin.tar.gz` を落とす。eza / navi とも、aarch64 / x86_64 の両方で 200 が返った（verified）。

**版は cargo-quickinstall 側の tag から決める**（2026-11-29 に決定。上流の latest を使うと、cqi のビルドが追いつくまで 404 になるため）（verified）:
- cqi の `releases/latest` は使えない。repo 全体で最後に出た release を指すだけで、今は `dioxus-cli-0.7.11` だった。
- `git ls-remote --tags --refs https://github.com/cargo-bins/cargo-quickinstall 'refs/tags/<crate>-*'` で、その crate の tag だけが 0.5 秒前後で取れる。git protocol v2 の ref-prefix で server 側が絞るので、API の rate limit にも当たらない。git は `00_bin` が保証している。
- **tag があっても darwin の asset が無いことがある**: `eza-0.18.24` と `navi-2.23.0` は、aarch64 / x86_64 とも 404 だった。なので、新しい版から順に HEAD を打ち、200 が返った最初のものを使う（試す数には上限を付ける）。
- `<crate>-*` は別の crate（`navi-foo-1.0` など）にも一致しうる。`^<crate>-[0-9]+\.[0-9]+\.[0-9]+$` で絞る（今は一致するものが無かった）。
- 版の並べ替えは `sort -V` を使わず、`sort -t. -k1,1n -k2,2n -k3,3n` にする（macOS の sort に `-V` があるかは未確認なので）。

リスク（上流の latest を使った場合。上のやり方で回避する）: cargo-quickinstall は上流の release を追いかけて後からビルドする。eza 0.23.5 は上流の 10 日後に出ている（上流 2026-07-09、cqi 2026-07-19）。その間は 404 になる（既存のバイナリは置き換えないので、壊れはしない）。checksum は無く、minisign の `.sig` だけがある（今の `__rayrc_github_downloader` も検証していないので、それと同じ水準）。

---

## 4. 決定事項

| # | 質問 | 決定 |
|---|-----|------|
| Q1 | fzf で選べるのは 1 つか、複数か | 1 つだけ |
| Q2 | 部分一致のせいで `lf` が `lfscp` にも一致する件 | そのまま（R5） |
| Q3 | mise の置き場所 | `src/02_net/00_mise/`（data は `libs/net/mise/`）。暫定 |
| Q4 | mise を何に使うか | ~~ひとまず macOS の eza / navi だけ~~ → mise 本体は入れる。eza / navi は curl で直接取る方向で検討し直す（§3.8、2026-11-29） |
| Q5 | mise 本体を入れる先 | Linux / macOS / **PowerShell** のすべて |
| Q6 | PowerShell の `-Fzf` | できれば今回一緒に入れる |
| Q7 | `src/install.sh` が `__rayrc_parse_args` を unset していない件 | 直す |
| Q8 | macOS の eza / navi の取り方 | 両方とも cargo-quickinstall。版は cqi の tag から決める（§3.8）。取得用の関数は `__rayrc_github_downloader` とは別に作る |

---

## 5. 計画

コミットは I5 に従い、振る舞いを変えないものと変えるものを分ける。

| # | commit | 内容 | 確かめ方 |
|---|--------|-----|---------|
2026-11-29 に組み直した（Q5〜Q8 を反映）。eza / navi は mise を使わなくなったので、mise は install のときに env を必要としない。なので、`functions.{sh,zsh}` と C6（mise を eza / navi より先に入れる）は要らなくなった。

| # | commit | 内容 | 確かめ方 |
|---|--------|-----|---------|
| P0 | `fix: unset __rayrc_parse_args in bash entries` | bash の `src/{install,main,uninstall}.sh` が `__rayrc_parse_args` を unset していない（zsh はしている）。Q7 は install.sh についてだったが、main.sh / uninstall.sh も同じ漏れ方をしている（main.sh はシェルを起動するたびに漏らす） | Docker で、install の後に `declare -F` の結果に残っていないこと |
| P1 | `refactor(ref): split module listing out of the facade (sh/zsh)` | `__rayrc_list_modules <dir> <phase>`（`src/common.{sh,zsh}`）を切り出し、facade がそれを使うようにする。振る舞いは変えない | 切り出す前後の facade で、同じ木を回したときの順番が同じであること。Docker で install を回し、`.ci/snapshot.sh` の結果が同じであること |
| P2 | `feat(install): --fzf picks the filter with fzf (sh/zsh/ps1)` | §1.3。候補作りと fzf は `src/install.{sh,zsh,ps1}`、`--fzf` の解釈は `__rayrc_parse_args`。ps1 は `-Fzf` switch で、既にある `__rayrc_list_modules` を使う | Docker で、`FZF_DEFAULT_OPTS='--filter=...'` を使って TTY 無しで回す。fzf が無い場合、Esc で抜けた場合、`--fzf` と `--filter` を一緒に指定した場合も試す。ps1 は pwsh のコンテナで parse と候補作りを試す |
| P3 | `feat(mise): add 02_net/00_mise` | sh / zsh: 公式 installer で `libs/bin/mise` に入れる。ps1: `__rayrc_scoop_install mise`（Scoop の main bucket にある）。main は `MISE_DATA_DIR` / `MISE_CONFIG_DIR` / `MISE_GLOBAL_CONFIG_FILE` / `MISE_CACHE_DIR` / `MISE_STATE_DIR` を `libs/net/mise/*` に向けるだけにする（`activate` / shims は、使い方を決めるときまで入れない） | Docker で 2 回回し、2 回目が no-op であること。`~/.local/share/mise` と `~/.config/mise` ができていないこと |
| P4 | `fix(eza,navi): fetch the macOS binaries from cargo-quickinstall (sh/zsh)` | `__rayrc_cqi_downloader <crate> <target> <file>` を `src/common.{sh,zsh}` に足す（同じ本文。§3.8 の手順）。eza / navi の install に `macos-*)` の分岐を足し、落とした後は `__rayrc_install_binary` に渡す | Linux 上で、bash と zsh から `__rayrc_cqi_downloader` を呼んで darwin 版を落とし、Mach-O であること。**Mac での実行はユーザーに頼む** |
| P5 | `docs: --fzf, mise, cargo-quickinstall` | `.claude/CLAUDE.md` の Installation の節、`.claude/rules/bash.md` の group の表と関数の一覧 | — |

---

## 6. 進捗（2026-11-29）

P0〜P5 を実装した（未 commit）。

| # | 確かめたこと | 結果 |
|---|------------|-----|
| P0 | 全 install の snapshot を HEAD と比べる | bash の `declare -f __rayrc_parse_args` だけが消えた（verified） |
| P1 | 小さな木（disabled、script が無いもの、ファイル、入れ子の delegate、`lf` / `lfscp`）を、HEAD と変更後の facade で filter 6 通り回す | bash / zsh とも、出力（各 46 行）が一致した（verified） |
| P2 | Docker（bash / zsh）、pwsh のコンテナ（ps1） | fzf が無い場合 → help を出して止まる。`--fzf` と `--filter` を一緒に指定 → エラー。TTY が無い場合 → `fzf failed (exit 2)`。何も選ばない場合 → 何も入れない。`text/jq` → jq だけ、`python` → グループ全体が入る。候補（sh 40 / zsh 34 / ps1 39）は `.ci/load_order.sh` と一致した（verified。Windows PowerShell 5.1 では未確認） |
| P3 | Docker（bash / zsh） | `libs/bin/mise` が入る。2 回目は 0.03 秒の no-op。`MISE_*` は `libs/net/mise/*` を指し、`mise use -g jq@latest` を実行しても `~/.local/share/mise` と `~/.config/mise` は作られない（verified）。ps1 は parse だけ確認した（Scoop が無いので、install そのものは untested） |
| P4 | Docker（bash / zsh）。`__rayrc_cqi_downloader` を直接呼び、さらに OS を `macos` に見せかけて eza / navi の install を通す（コンテナは x86_64 なので、`macos-x86_64` の分岐が走る） | `libs/bin/{eza,navi}` は Mach-O x86_64。crate が無い場合と、target 向けのビルドが無い場合は、warn を出して 8 を返し、途中のファイルは残らない（verified）。**Mac の上での実行は untested** |
| 全体 | 全 install の snapshot（`.ci/snapshot.sh`）を HEAD と比べる | 差分は P0 の 1 行、`MISE_*` の 5 行、ログの `setting up for mise..` だけ（verified） |

実装中に見つけて直したもの:
- `--fzf` と `--filter` を一緒に指定したときなどの早期 `return` で、facts の関数（`__rayrc_determine_os_type` など）がシェルに残っていた。→ 引数の解釈と fzf での選択を facts の後ろに移した。
- fzf のエラー（exit 2）を「選ばずに抜けた」と区別していなかった。→ 1 / 130 だけを中断とみなすようにした。
- zsh の `__rayrc_list_modules` は、`$(...)` の fork を避けるために `reply` 配列で返す（main.zsh はシェルの起動ごとに回るので）。bash はもともと `$(ls -1)` で fork しているので、出力で返す。

前からあったもの（直していない）:
- `source ./install` の戻り値は、最後の `unset -f` のものになるので、中で `return 8` しても常に 0 になる。
- `__rayrc_github_downloader` / `__rayrc_log_info` / `__rayrc_log_warn` は、どの entry でも unset されず、シェルに残る。
- `src/install.ps1` と トップの `install.ps1` には BOM が無い（今は ASCII だけなので、5.1 でも問題は出ない）。
