# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A "pluggable terminal rc platform" — a portable dotfiles framework that automates shell environment setup across workstations. Installs to `$HOME/.rayrc` and supports bash and zsh (PowerShell in progress). Everything lives self-contained within the `.rayrc` folder.

## Installation & Testing

```bash
# Full install (detects shell automatically)
source ./install

# Install specific packages only
# one comma-separated token per hierarchy level, substring match ("*" matches any)
source ./install --filter text,bat

# Pick one module or group with fzf; the filter is built from it (needs fzf, so from the 2nd install on)
source ./install --fzf

# Uninstall
source ./uninstall
```

CI runs on push/PR via `.github/workflows/successful-install-on-every-platform.yml` (currently ubuntu-22.04). There is also a Docker-based tester in `test/docker_bash_tester/`.

### Docker Testing (clean environment)

The local work tree is mounted read-only and copied into a clean container, so no commit / push is needed:

```bash
docker build -t rayrc-test -f .claude/skills/rayrc-docker-test/Dockerfile .
docker run --rm -v "$PWD":/work:ro rayrc-test bash -c "cp -a /work /root/.rayrc && cd /root && source .rayrc/install"

# runtime state (aliases / functions / env / key bindings), normalized for diffing
.ci/snapshot.sh bash /tmp/snap_bash   # or: zsh
```

Note: Consecutive runs may hit GitHub rate limits (installs download releases from GitHub).
Tip: use `/rayrc-docker-test` skill to run the above automatically.

## Architecture

### Module Tree

`src/` is the one control plane (logic, aliases, functions) for every shell; `libs/` is the data plane (binaries, configs). Invariants:

- **I1** A directory is a module (a tool); the extension is the dialect: `.sh` = bash, `.zsh` = zsh, `.ps1` = PowerShell. Not supported in a dialect = that file is absent.
- **I2** `src/<NN_group>/<NN_tool>/` ↔ `libs/<group>/<tool>/` (the first 3 chars of each level are stripped).
- **I3** The control plane holds tracked files only. Generated files go to the data plane (gitignored, created at install), so `git pull` alone migrates the control plane.
- **I4** Load order = ordinal (C locale / byte order) of `NN_name`, the same in every dialect. Numbering constraints (C1–C5) are in `.claude/rules/bash.md`.
- **I5** Move commits carry no behavior change, and vice versa (`refactor(move):` / `refactor(ref):` / `fix:` / `feat(...):`).
- **I6** Sourced helpers carry the dialect's extension (`functions.sh` / `functions.zsh` / `functions.ps1`).
- **I7** Standalone scripts (shebang, not sourced) may use any extension.
- **I8** Every dialect follows the same semantics: the facade enumerates one level (ordinal), skips `disabled`, consumes one `--filter` token per level, and descends only through an explicit group delegate `<phase>.<ext>`. bash/zsh delegates call `__rayrc_source_facade`; PowerShell delegates run a top-level `foreach` over `__rayrc_list_modules` with `__rayrc_module_enter` / `__rayrc_module_leave` (`src/common.ps1`), because dot-sourcing inside a function would trap module definitions in that function's scope.

Move or renumber a module with `.ci/mv_util.sh --from <module> --to <module>` (moves every dialect and the data plane together). `.ci/load_order.sh` lists the load order statically.

### Shell Detection & Dispatch

The top-level `install` and `uninstall` scripts detect whether bash or zsh is running, then delegate to `src/install.sh` or `src/install.zsh` (and the `uninstall` counterparts). They register `main.sh` / `main.zsh` in `~/.bashrc` / `~/.zshrc` as a marker-delimited managed block. On Windows, `install.ps1` delegates to `src/install.ps1`, which runs each module's `install.ps1` through the same facade (`-Filter text,bat` = bash `--filter`, `-Fzf` = bash `--fzf`) and then registers `main.ps1` in `$PROFILE` the same way.

Module system details, key internal functions, and bash conventions are in `.claude/rules/bash.md` (auto-loaded when editing `src/**`). zsh follows the same conventions with `<phase>.zsh` and its own facade (`src/common.zsh`, `src/logger.zsh`); zsh is currently used on macOS only, and its `install.zsh` acquires tools the same way as bash (GitHub releases / official installers; brew only where a module says so). bash and zsh never share one `libs/bin` in practice (Linux hosts run bash, the Mac runs zsh). PowerShell acquires tools via Scoop (left to Scoop's own management), except uv / pnpm / claude, which use their official installers into the data plane.

### OS Support

Linux (Ubuntu, Amazon Linux, RHEL, Debian, CentOS, Photon, Arch, Alpine, OpenWrt, Synology) and macOS. Windows support is in-progress via the `*.ps1` modules.
