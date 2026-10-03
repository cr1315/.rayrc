---
paths:
  - "libs/**"
---

# libs/ 配下の .gitignore の書き方

`libs/` 以下の各モジュールは「自分で管理する設定・スクリプト」と「インストール時に取得される成果物（クローンしたリポジトリ・ダウンロードしたバイナリ・ランタイム生成物）」が同居する。`.gitignore` の役割は後者をコミット対象から外し、前者だけをバージョン管理することにある。

用途に応じて次の 4 パターンを使い分ける。

## パターン一覧

| パターン | 用途 | 例 |
|---------|------|-----|
| A. ディレクトリ名を列挙して無視 | 取得物が入る配下ディレクトリを名前指定で除外 | `libs/.gitignore`, `libs/git/.gitignore`, `libs/fzf/.gitignore`, `libs/vim/vimfiles/.gitignore`, `libs/tools/lf/.gitignore` |
| B. `*` で全無視 | ディレクトリごとランタイム専用。中身も `.gitignore` 自身も追跡しない | `libs/python/uv/**/.gitignore` |
| C. 全無視 + `!` で許可 | 大半はランタイム管理だが一部ファイルだけ版管理したい | `libs/claude/.gitignore` |
| D. 第三者リポジトリ由来 | クローン元が持つ `.gitignore`。**我々は編集しない** | `libs/blesh/.gitignore`, `libs/fzf/fzf/.gitignore`, `libs/git/gitstatus/.gitignore`, `libs/vim/vimfiles/plugged/*/.gitignore` |

## A. ディレクトリ名を列挙して無視（最も基本）

インストール時にクローン／ダウンロードされるディレクトリを、名前で列挙して除外する。モジュール自身の `install.sh` / `main.sh` などは追跡したまま、取得ペイロードだけを外せる。

```gitignore
# libs/.gitignore … トップ階層で取得物ディレクトリをまとめて無視
bin
blesh
gdu
jq
pipx
```

```gitignore
# libs/git/.gitignore … クローンした第三者リポジトリのディレクトリ名
gitstatus
```

```gitignore
# libs/fzf/.gitignore
fzf
```

```gitignore
# libs/vim/vimfiles/.gitignore … プラグインマネージャの生成物・実行時状態
autoload
plugged
viminfo
.netrwhist
```

```gitignore
# libs/tools/lf/.gitignore … 実行時データディレクトリだけを無視（config/ は追跡）
data
```

**指針**: 除外したい対象が「特定のサブディレクトリ／ファイル」で、同階層に版管理したいものが残るなら、このパターンを使う。

## B. `*` で全無視（ディレクトリごとランタイム専用）

そのディレクトリが完全にランタイムのインストール先で、中身を一切コミットしない場合。`*` は `.gitignore` 自身にもマッチするため、この `.gitignore` 自体も追跡されない（`git ls-files` に現れない、ランタイム生成マーカー）。ディレクトリを安定した設置先として残しつつ、中身を丸ごと除外できる。

```gitignore
# libs/python/uv/tools/.gitignore, libs/python/uv/python/.gitignore など
*
```

**指針**: uv 管理の Python やツールのように、配下すべてがインストーラ／ツールに管理され、版管理する自作ファイルが 1 つも無いディレクトリで使う。逆に 1 つでも残したいファイルがあるならパターン C にする。

## C. 全無視 + `!` で明示的に許可（ブロックリスト方式）

大半がランタイム／マシン管理だが、一部の設定ファイルだけを版管理したいディレクトリ向け。「まず全部無視 → 必要なものを `!` で復活」の順で書く。一度許可した親ディレクトリの下を再び無視したい場合は、その親の直後にネストで再無視する。

```gitignore
# libs/claude/.gitignore
# ignore everything under .claude/
.claude/*

# keep these explicitly
!.claude/CLAUDE.md
!.claude/settings.json
!.claude/statusline-command.sh
!.claude/plugins/
.claude/plugins/*
# !.claude/plugins/installed_plugins.json

## __rayrc personal memories
!.claude/personal-memories/
```

**書き方の要点**:
- 先頭で `dir/*`（`dir` ではなく `dir/*`）を無視する。`dir` 自体を無視するとその下を `!` で復活できないため、必ず `/*` を付ける。
- 残したいものを `!` で列挙する。ディレクトリを許可（`!.claude/plugins/`）した上でその中身を絞り込みたいときは、直後に `.claude/plugins/*` と再無視し、さらに必要な中身を `!` で拾う。
- コメントで「なぜ残す／なぜ無視する」を残しておく。

## D. 第三者リポジトリ由来（編集対象外）

`libs/blesh/`, `libs/fzf/fzf/`, `libs/git/gitstatus/`, `libs/vim/vimfiles/plugged/*/` などにある `.gitignore` は、クローン元リポジトリが同梱しているもの。**我々の管理対象ではないので編集しない**。これらは親モジュールのパターン A（ディレクトリ名指定）によって丸ごと無視されているため、そもそもリポジトリには追跡されない。

## 追加・変更時のチェックリスト

- [ ] 除外対象が「取得物・ランタイム生成物」であり、自作の設定／スクリプトを誤って外していないか
- [ ] 残したいファイルが 1 つも無いなら B（`*`）、あるなら A か C を選んだか
- [ ] C を使うなら `dir/*`（`/*` 付き）で無視し、`!` で個別許可しているか
- [ ] 追加したエントリが第三者リポジトリ側の `.gitignore` と重複／干渉していないか
- [ ] `git check-ignore -v <path>` で意図どおり無視されるか確認したか
