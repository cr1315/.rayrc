---
paths:
  - "bash/**"
---

# bash/ Module System

## Module System (Numbered Prefix Convention)

Modules are directories under `bash/` with a numbered prefix that controls load order:

| Prefix | Purpose | Examples |
|--------|---------|---------|
| `00_` | Core binaries/PATH | `00_bin` |
| `05_` | Tool groups (two-level) | `05_tools` |
| `10_` | Shell config (prompt, aliases, env) | `10_bash`, `10_zsh` |
| `12_` | Dev tools (fzf, git, vim) | `12_fzf`, `12_git` |
| `15_` | Terminal multiplexer | `15_tmux` |
| `20_`+ | Language/platform tools | `20_python` |
| `40_`–`63_` | Infrastructure tools | `40_docker`, `60_aws`, `62_kubectl` |
| `80_`–`90_` | Misc/specialized | `80_hulft`, `90_misc` |

Each module can contain:
- **`install.sh`** — one-time setup. Only runs during `source ./install`.
- **`main.sh`** — sourced on every shell startup. Appended to `.bashrc`/`.zshrc`.
- **`disabled`** — sentinel file; if present, the module is skipped.

## Two-Level Module Hierarchy

Modules can contain subdirectories with numeric prefixes (e.g. `05_tools/06_bat/`, `20_python/20_pipx/`). The parent module's `install.sh`/`main.sh` acts as a delegate:

```bash
#!/usr/bin/env bash
__rayrc_install() {
    __rayrc_module_common_setup    # sets __rayrc_ctl_dir to parent dir
    __rayrc_source_facade install  # scans subdirs and sources their install.sh in order
}
__rayrc_install
unset -f __rayrc_install
```

Subdirectory `install.sh`/`main.sh` follow the same define-call-unset pattern. `__rayrc_install` in parent and child can share the name — parent unsets before child runs.

## Control Plane vs Data Plane (libs/)

`bash/` is the **control plane** (logic, aliases, functions). `libs/` is the **data plane** (binaries, configs). The mapping strips the numeric prefix: `__rayrc_data_dir = libs/<name_without_prefix>`. Binaries go to `libs/bin/` which is added to PATH.

Two-level hierarchy mirrors into `libs/` as well: `bash/05_tools/06_bat/` → `libs/tools/bat/`. When adding or renaming a module group, update the corresponding `libs/` structure and `.gitignore` files together.

Some `libs/` subdirs contain tracked config files (e.g. `libs/tools/bat/config/`, `libs/tools/lf/config/`). Do NOT add these directories wholesale to `.gitignore` — only ignore download artifacts (`.tar.gz` etc.) if needed.

## Key Internal Functions (defined in `bash/common.sh`)

- `__rayrc_log_info <message>` — depth-aware logger (defined in `bash/logger.sh`, sourced by `common.sh`); indents by 2 spaces per `__rayrc_source_facade` nesting level
- `__rayrc_github_downloader <repo> <target> <filters...>` — (legacy) downloads latest GitHub release via HTML scraping
- `__rayrc_eget_install <repo> <binary_name> [--asset filters...]` — downloads GitHub release binary via eget
- `__rayrc_module_common_setup` — sets `__rayrc_ctl_dir` and `__rayrc_data_dir` for the current module
- `__rayrc_source_facade <phase>` — scans `__rayrc_ctl_dir` subdirs and sources `<phase>.sh` in numeric order
- `__rayrc_determine_os_type` / `__rayrc_determin_os_distribution` — populates OS facts and package manager variables

## Conventions

- All internal functions/variables use `__rayrc_` prefix to avoid namespace collisions
- Functions are `unset -f` after use to keep the shell environment clean
- Modules should call `__rayrc_module_common_setup` at the start of both `install.sh` and `main.sh`
- `main.sh` files should guard with `command -v <tool> >/dev/null 2>&1 || { return; }` if they depend on an optional binary
- Use exit/return code `8` for failures (project convention)
- During `install`, `libs/bin/` is not yet in PATH; guard sub-modules that depend on a tool installed earlier in the same session using the exported env var (e.g. `[[ -x "${PIPX_BIN_DIR}/pipx" ]]` instead of `command -v pipx`) and invoke via full path (`"${PIPX_BIN_DIR}/pipx" install ...`)
