# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A "pluggable terminal rc platform" — a portable dotfiles framework that automates shell environment setup across workstations. Installs to `$HOME/.rayrc` and supports both bash and zsh. Everything lives self-contained within the `.rayrc` folder.

## Installation & Testing

```bash
# Full install (detects shell automatically)
source ./install

# Install specific packages only
source ./install --install bat,fzf

# Enable a disabled package and install it
source ./install --enable eza --install eza

# Disable a package
source ./install --disable eza

# Uninstall
source ./uninstall
```

CI runs on push/PR via `.github/workflows/successful-install-on-every-platform.yml` (currently ubuntu-22.04). There is also a Docker-based tester in `test/docker_bash_tester/`.

### Docker Testing (clean environment)

```bash
docker build --no-cache -t rayrc-test .
```

Dockerfile is at project root. Clones from remote (dev_docker branch), so commit & push before building.
Note: Consecutive builds may hit GitHub API rate limits (eget uses GitHub API).

## Architecture

### Shell Detection & Dispatch

The top-level `install` and `uninstall` scripts detect whether bash or zsh is running, then delegate to the appropriate shell-specific entry point (`bash/install.sh` or `zsh/install.zsh`).

### Module System (Numbered Prefix Convention)

Modules are directories under `bash/` or `zsh/` with a numbered prefix that controls load order:

| Prefix | Purpose | Examples |
|--------|---------|---------|
| `00_` | Core binaries/PATH | `00_bin` |
| `01_` | Bootstrap tools | `01_eget` |
| `06_` | CLI tool installation | `06_bat`, `06_eza`, `06_fd`, `06_rg` |
| `10_` | Shell config (prompt, aliases, env) | `10_bash`, `10_zsh` |
| `12_` | Dev tools (fzf, git, vim) | `12_fzf`, `12_git` |
| `15_` | Terminal multiplexer | `15_tmux` |
| `20_`+ | Language/platform tools | `20_pipx` |
| `40_`–`63_` | Infrastructure tools | `40_docker`, `60_aws`, `62_kubectl` |
| `80_`–`90_` | Misc/specialized | `80_hulft`, `90_misc` |

Each module can contain:
- **`install.sh`** — one-time setup (download binaries, configure). Only runs during `source ./install`.
- **`main.sh`** — sourced on every shell startup (aliases, env vars, functions). Appended to `.bashrc`/`.zshrc`.
- **`disabled`** — sentinel file; if present, the module is skipped.

### Control Plane vs Data Plane (libs/)

`bash/` and `zsh/` directories are the **control plane** (logic, aliases, functions). `libs/` is the **data plane** (binaries, configs, templates). The control plane module `06_bat` stores its logic in `bash/06_bat/`, but downloaded binaries and config files go to `libs/bat/`. The mapping strips the numeric prefix: `__rayrc_data_dir = libs/<package_name_without_prefix>`.

Binaries are placed in `libs/bin/` which gets added to PATH.

### Key Internal Functions (defined in `bash/common.sh`)

- `__rayrc_github_downloader <repo> <target> <filters...>` — (legacy) downloads latest GitHub release via HTML scraping
- `__rayrc_eget_install <repo> <binary_name> [--asset filters...]` — downloads GitHub release binary via eget
- `__rayrc_module_common_setup` — sets `__rayrc_ctl_dir` and `__rayrc_data_dir` for the current module
- `__rayrc_determine_os_type` / `__rayrc_determin_os_distribution` — populates OS facts and package manager variables

### OS Support

Linux (Ubuntu, Amazon Linux, RHEL, Debian, CentOS, Photon, Arch, Alpine, OpenWrt, Synology) and macOS. Windows support is in-progress via `powershell/`.

## Conventions

- All internal functions/variables use `__rayrc_` prefix to avoid namespace collisions
- Functions are `unset -f` after use to keep the shell environment clean
- Modules should call `__rayrc_module_common_setup` at the start of both `install.sh` and `main.sh`
- `main.sh` files should guard with `command -v <tool> >/dev/null 2>&1 || { return; }` if they depend on an optional binary
- Use exit/return code `8` for failures (project convention)
