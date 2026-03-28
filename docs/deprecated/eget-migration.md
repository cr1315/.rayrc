# eget Migration: __rayrc_github_downloader の代替ツール調査

## 背景

.rayrc の各モジュール (`06_bat`, `06_fd` 等) は GitHub Releases からバイナリをダウンロードしている。
従来は `bash/common.sh` に定義した自作関数 `__rayrc_github_downloader` を使用していた。

## 現状の課題

1. **HTMLスクレイピング方式** — GitHub releases ページのHTMLをパースしてダウンロードリンクを抽出。GitHubのUI変更（lazy-loading対応等）で壊れるリスクがある
2. **case文のボイラープレート** — 各 `install.sh` で OS/arch の分岐を手書き。1モジュール約40行のうち大半がcase文
3. **checksum検証なし** — ダウンロードしたバイナリの整合性を検証していない
4. **アーカイブ展開が手動** — `tar xf ... --transform ...` を各モジュールが個別に実装

## ツール比較 (2026-03)

GitHub Releases からバイナリをダウンロード・インストールするツールを調査した。

| | eget | dra | stew | bin | aqua | mise |
|---|---|---|---|---|---|---|
| **言語** | Go | Rust | Go | Go | Go | Rust |
| **GitHub** | zyedidia/eget | devmatteini/dra | marwanhawari/stew | marcosnils/bin | aquaproj/aqua | jdx/mise |
| **OS/Arch自動検出** | 優秀 | 良好 | 良好 | 良好 | 良好 | 良好 |
| **アーカイブ自動展開** | tar.gz, tar.bz2, tar.xz, zip | tar, zip, 7z | 自動 | 自動 | 自動 | 自動 |
| **設定ファイル** | TOML (`~/.eget.toml`) | env変数のみ | JSON + Stewfile | JSON (内部) | YAML (宣言的) | TOML (宣言的) |
| **checksum検証** | SHA256自動 (.sha256 ファイルがあれば) | なし | なし | なし | あり | あり |
| **ブートストラップ** | `curl \| sh` で一発 | install.sh スクリプトあり | `go install` が必要 | curl + バイナリ | curl + バイナリ | curl + バイナリ |
| **スコープ** | バイナリDL特化 | バイナリDL特化 | バイナリ管理 | マルチソース対応 | バージョン管理全般 | 開発環境全体 |
| **Stars** | ~1k | ~500 | ~200 | ~700 | ~1.6k | ~10k+ |

### 各ツール詳細

#### eget
- `eget owner/repo --to /path` で OS/arch 自動検出→DL→展開→配置が一発
- `--asset "musl"` でアセット名のフィルタリング可能
- `--file "bat"` でアーカイブ内の特定ファイルを選択可能
- TOML設定ファイルでリポジトリごとのデフォルト設定を定義可能

#### dra
- `dra download -a owner/repo` で自動ダウンロード
- Rustで書かれており軽量
- 公式 install.sh でブートストラップが容易
- ただし宣言的な設定ファイルがない

#### stew
- Stewfile による宣言的なパッケージ管理が可能
- `stew install`, `stew upgrade`, `stew list` 等のサブコマンド
- ブートストラップに `go install` が必要で、Goが入っていない環境では敷居が高い

#### bin
- GitHub以外にもGitLab, Docker, HashiCorp等の複数ソースに対応
- スコアリングベースのアセット選択
- .rayrc の用途にはオーバースペック

#### aqua / mise
- バージョン管理まで含む包括的なツール
- チーム開発・CI向けの機能が充実
- .rayrc の「軽量dotfilesフレームワーク」思想にはオーバースペック

## 選定結果: eget

### 選定理由

1. **DL特化で軽量** — .rayrc の「軽量dotfilesフレームワーク」思想にフィット
2. **OS/arch自動検出** — case文のボイラープレートが不要になり、install.sh が ~5行に
3. **アーカイブ自動展開** — tar/zip の手動展開コードが不要
4. **SHA256自動検証** — セキュリティ面で改善
5. **curlでブートストラップ可能** — `curl https://zyedidia.github.io/eget.sh | sh`
6. **フィルタ機能** — `--asset` でmusl等のビルド選択が可能

### 移行による変化

**Before (例: 06_bat/install.sh, ~50行):**
```bash
case "${__rayrc_facts_os_type}-$(uname -m)" in
    linux-arm* | linux-aarch*)
        __rayrc_github_downloader "sharkdp/bat" "${__rayrc_data_dir}/bat.tar.gz" "arm" "musl"
        ;;
    linux-*64*)
        __rayrc_github_downloader "sharkdp/bat" "${__rayrc_data_dir}/bat.tar.gz" "musl" "x86_64"
        ;;
    # ... 5+ more cases ...
esac
tar xf "${__rayrc_data_dir}/bat.tar.gz" -C "${__rayrc_data_dir}" --transform 's:^[^/]*:bat:'
cp -f "${__rayrc_data_dir}/bat/bat" "${__rayrc_bin_dir}"
rm -rf "${__rayrc_data_dir}/bat"*
```

**After (~5行):**
```bash
__rayrc_eget_install "sharkdp/bat" "bat" --asset "musl" || return 8
```
