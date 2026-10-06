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
| `02_` | Network / transfer tools (group) | `02_net` (eget, httpie, stu) |
| `04_` | Text tools: view, diff, process, format, edit (group) | `04_text` (bat, delta, jq, shfmt, yq, vim) |
| `06_` | File search tools: find, list, disk usage (group) | `06_filesearch` (eza, fd, gdu, navi, rg) |
| `08_` | Shell itself: prompt, aliases, env, sudo (group) | `08_bash` (common, sudo) |
| `10_` | Interactive UI: fuzzy finder, prompt, history, file manager, multiplexer (group) | `10_viewer` (fzf, git, atuin, yazi, lf, tmux) |
| `20_`+ | Language/platform tools | `20_python` |
| `40_`–`63_` | Infrastructure tools | `40_docker`, `60_aws`, `62_kubectl` |
| `80_`–`90_` | Misc/specialized | `80_hulft`, `90_misc` |

Odd numbers (`01`, `03`, `05`, `07`, `09`) and `11`–`19` are left free for future groups. Group names must not collide under `--filter` substring matching with any other top-level name.

Each module can contain:
- **`install.sh`** — one-time setup. Only runs during `source ./install`.
- **`main.sh`** — sourced on every shell startup. Appended to `.bashrc`/`.zshrc`.
- **`disabled`** — sentinel file; if present, the module is skipped.

## Two-Level Module Hierarchy

Modules can contain subdirectories with numeric prefixes (e.g. `04_text/10_bat/`, `20_python/02_pipx/`). The parent module's `install.sh`/`main.sh` acts as a delegate:

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

Two-level hierarchy mirrors into `libs/` as well: `bash/04_text/10_bat/` → `libs/text/bat/`, `bash/08_bash/10_common/` → `libs/bash/common/`. When moving or renumbering a module, use `.ci/mv_util.sh --from <module> --to <module>`: it moves the control plane and data plane together (including ignored runtime data), creates missing groups with their delegates, and warns about broken symlinks and stale path references.

Some `libs/` subdirs contain tracked config files (e.g. `libs/text/bat/config/`, `libs/viewer/lf/config/`). Do NOT add these directories wholesale to `.gitignore` — only ignore download artifacts (`.tar.gz` etc.) if needed.

## Key Internal Functions (defined in `bash/common.sh`)

- `__rayrc_log_info <message>` — depth-aware logger (defined in `bash/logger.sh`, sourced by `common.sh`); indents by 2 spaces per `__rayrc_source_facade` nesting level
- `__rayrc_github_downloader <repo> <target> <filters...>` — (legacy) downloads latest GitHub release via HTML scraping
- `__rayrc_eget_install <repo> <binary_name> [--asset filters...]` — downloads GitHub release binary via eget. **Deprecated as an acquisition method and currently unused**; defined in `bash/02_net/10_eget/install.sh`, which still installs the eget binary for manual use only
- `__rayrc_module_common_setup` — sets `__rayrc_ctl_dir` and `__rayrc_data_dir` for the current module
- `__rayrc_source_facade <phase>` — scans `__rayrc_ctl_dir` subdirs and sources `<phase>.sh` in numeric order
- `__rayrc_determine_os_type` / `__rayrc_determin_os_distribution` — populates OS facts and package manager variables

## Binary Acquisition Strategy (priority order)

Core principle: every tool's binary — or a symlink to it — lives in rayrc's own dedicated location. Binaries land in `libs/bin/` (added to PATH); rayrc manages them itself, self-contained, so keep the external dependency and host footprint minimal. Favor plain `curl`/`tar` over anything that mutates the host system.

When adding a module, pick the acquisition method in this order of preference:

1. **Official install script (highest priority)** — if the tool ships its own installer, read its source first. If it robustly auto-detects OS/arch (glibc vs musl, macOS, etc.), pipe it and point its output at `libs/bin/` instead of hand-rolling a GitHub download. The uv module is the reference implementation (`bash/20_python/20_uv/install.sh`):
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh \
       | env UV_INSTALL_DIR="${__rayrc_bin_dir}" UV_NO_MODIFY_PATH=1 sh
   ```
   - Use the installer's own env vars to (a) target `libs/bin/`, (b) stop it from editing shell rc files (rayrc owns PATH), (c) keep a flat layout with no extra env script.
   - Wrap the pipe in a subshell with `set -o pipefail` so a mid-pipe failure is caught, then `return 8` on failure.

2. **Direct GitHub release download** — use when the tool ships no install script, or the one it ships relies on a system package manager. Download the release asset directly, extract it if it's a zip/tar, and move only the binary into `libs/bin/`. See the mechanics per asset type in "Adding a New Tool Module" below.

3. **System package manager (last resort)** — only when neither of the above is possible. Avoid when you can: it updates package-manager caches and pulls in transitive dependencies, which bloats the image and couples rayrc to the host's package state. The whole point is to stay lean and self-managed.

## Load-Order Constraints

`__rayrc_source_facade` sources modules in `ls -1` order: by number, and **alphabetically when numbers are equal**.

Principle: things that depend on nothing, or that others depend on, get small numbers; things that combine others get large numbers. Only two of the three kinds of dependency actually constrain the order:

| Kind | Meaning | Constrains order? |
|------|---------|-------------------|
| ① Install-time | an `install.sh` runs another tool installed earlier in the same session | **Yes** |
| ② Load-time | a `main.sh` sets or overwrites shell state (`PROMPT_COMMAND`, `bind`, aliases, env vars); the later one wins | **Yes** |
| ③ Run-time | a command calls another tool from PATH when the user runs it (navi → fzf, fzf preview → bat) | **No** — all binaries are in the flat `libs/bin/`, which `00_bin` puts on PATH first |

Current ①② constraints (there is no ① today):

| # | Constraint | Reason |
|---|------------|--------|
| C1 | `00_bin` < everything | adds `libs/bin` to PATH; later `command -v` guards rely on it |
| C2 | `08_bash/10_common` < `10_viewer/20_git` | gitstatus overwrites `PROMPT_COMMAND=smile_prompt` by assignment |
| C3 | `10_viewer/20_git` < `10_viewer/30_atuin` | gitstatus assigns (not appends) `PROMPT_COMMAND`; if it ran after atuin, atuin's bash-preexec hook would be lost and history would stop being recorded |
| C4 | `10_viewer/10_fzf` < `10_viewer/30_atuin` | both bind **Ctrl-R**; atuin must win |
| C5 | `10_viewer/40_yazi` < `10_viewer/48_lf` | both want **Ctrl-O**; lf wins for now (yazi's bind is commented out) |

## Adding a New Tool Module

1. Pick the group:
   - `02_net` / `04_text` / `06_filesearch` — single-purpose CLIs whose `main.sh` only sets env vars or aliases (no ②)
   - `08_bash` — the shell itself (prompt, aliases, env, sudo)
   - `10_viewer` — interactive tools that bind keys or touch `PROMPT_COMMAND` (②), or that combine tools from the other groups
2. Pick the number inside the group:
   - `0x` — base that other tools in the group need at install time (①). None today
   - `1x` — independent single-purpose CLI, or the base of the group. Order does not matter, so the same number is fine
   - `2x`+ — modules that touch shell state (②) or combine others. The later it must load, the larger the number; leave gaps
   - When two modules compete for a key, give the one that should win the larger number
   - **Never give the same number to modules with a ② "later wins" relation** — alphabetical order would decide (e.g. `20_atuin` < `20_git` would break C3)
3. Create `bash/<group>/<NN>_<tool>/install.sh` following the define-call-unset pattern. Its data dir is `libs/<group without prefix>/<tool>/`
4. Check GitHub releases for asset naming (`curl -s https://api.github.com/repos/<owner>/<repo>/releases/latest | grep '"name"'`)
5. Post-download handling by asset type:
   - **Single binary** (jq): `mv` to `${__rayrc_bin_dir}`
   - **tar.gz with subdirectory** (bat, fd): `tar xf --transform 's:^[^/]*:<tool>:'` then `cp`
   - **tar.gz flat** (navi): `tar xf -C "${__rayrc_data_dir}"` then `cp`
6. Cleanup: `rm -rf "${__rayrc_data_dir}/<tool>"*`
7. Tools without macOS releases: `*)` fallback warns and returns 8

## Conventions

- All internal functions/variables use `__rayrc_` prefix to avoid namespace collisions
- Functions are `unset -f` after use to keep the shell environment clean
- Modules should call `__rayrc_module_common_setup` at the start of both `install.sh` and `main.sh`
- `main.sh` files should guard with `command -v <tool> >/dev/null 2>&1 || { return; }` if they depend on an optional binary
- Use exit/return code `8` for failures (project convention)
- During `install`, `libs/bin/` is not yet in PATH; guard sub-modules that depend on a tool installed earlier in the same session using the exported env var (e.g. `[[ -x "${PIPX_BIN_DIR}/pipx" ]]` instead of `command -v pipx`) and invoke via full path (`"${PIPX_BIN_DIR}/pipx" install ...`)
