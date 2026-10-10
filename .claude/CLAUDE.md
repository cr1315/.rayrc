# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A "pluggable terminal rc platform" — a portable dotfiles framework that automates shell environment setup across workstations. Installs to `$HOME/.rayrc` and supports both bash and zsh. Everything lives self-contained within the `.rayrc` folder.

## Installation & Testing

```bash
# Full install (detects shell automatically)
source ./install

# Install specific packages only
# one comma-separated token per hierarchy level, substring match ("*" matches any)
source ./install --filter text,bat

# Uninstall
source ./uninstall
```

CI runs on push/PR via `.github/workflows/successful-install-on-every-platform.yml` (currently ubuntu-22.04). There is also a Docker-based tester in `test/docker_bash_tester/`.

### Docker Testing (clean environment)

```bash
docker build --no-cache -t rayrc-test .
docker run --rm rayrc-test bash -c "cd && git clone -b dev_docker --single-branch --depth 1 https://github.com/cr1315/.rayrc.git && source .rayrc/install"
```

Dockerfile is at project root. Clones from remote (dev_docker branch), so commit & push before building.
Note: Consecutive builds may hit GitHub API rate limits (eget uses GitHub API).
Tip: use `/rayrc-docker-test` skill to run the above two commands automatically.

## Architecture

### Shell Detection & Dispatch

The top-level `install` and `uninstall` scripts detect whether bash or zsh is running, then delegate to the appropriate shell-specific entry point (`bash/install.sh` or `zsh/install.zsh`).

Module system details, key internal functions, and bash conventions are in `.claude/rules/bash.md` (auto-loaded when editing `bash/**`).

`zsh/` mirrors the same group layout, facade (`zsh/common.zsh`, `zsh/logger.zsh`), `--filter` syntax and `libs/` data plane, with `<phase>.zsh` instead of `<phase>.sh`. Keep the two trees in sync when moving or renumbering a module (`.ci/mv_util.sh` only handles `bash/`). zsh is currently used on macOS, where tools usually also come from brew.

### OS Support

Linux (Ubuntu, Amazon Linux, RHEL, Debian, CentOS, Photon, Arch, Alpine, OpenWrt, Synology) and macOS. Windows support is in-progress via `powershell/`.
