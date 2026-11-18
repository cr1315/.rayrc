---
name: rayrc-docker-test
description: Build a Docker image and run the .rayrc install script in a clean container to verify effect and logs
allowed-tools: Bash
---

# .rayrc Docker Clean Environment Test

Run the following steps to test the `.rayrc` install in a clean Docker environment.
The local work tree is mounted read-only and copied into the container, so uncommitted changes are tested as they are (no commit / push needed).

## Step 1: Confirm working directory

Make sure you are in the repository root (the directory that contains `install` and `src/`):

```bash
pwd && ls install src >/dev/null
```

## Step 2: Build the Docker image

```bash
docker build -t rayrc-test -f .claude/skills/rayrc-docker-test/Dockerfile .
```

## Step 3: Run install in clean container

bash:

```bash
docker run --rm -v "$PWD":/work:ro rayrc-test bash -c "
  cp -a /work /root/.rayrc && cd /root &&
  source .rayrc/install
"
```

zsh (not in the image; installed per run):

```bash
docker run --rm -v "$PWD":/work:ro rayrc-test bash -c "
  apt-get update -qq && apt-get install -y -qq zsh >/dev/null &&
  cp -a /work /root/.rayrc && cd /root && touch .zshrc &&
  zsh -c 'source .rayrc/install'
"
```

## Step 4 (optional): Compare the runtime state

`.ci/snapshot.sh` runs the same install and dumps aliases / functions / env / key bindings of an interactive shell, normalized for diffing (per-run values such as HOSTNAME are masked):

```bash
.ci/snapshot.sh bash /tmp/snap_bash   # -> /tmp/snap_bash.txt (.raw / .stderr alongside)
.ci/snapshot.sh zsh  /tmp/snap_zsh
diff <before>.txt /tmp/snap_bash.txt
```

## Notes

- Add `--no-cache` to `docker build` for a completely fresh image
- `--rm`: removes the container automatically after it exits
- The image uses https apt mirrors (some hosts block outbound :80)
- GitHub rate limits may apply on consecutive runs (installs download releases from GitHub)
- After running, report the full output to the user and highlight:
  - Any errors or warnings
  - Which modules installed successfully
  - Specifically check whether `20_pipx`, `21_poetry`, `22_glances`, `23_ansible` all appear in order
  - On Python 3.11+, confirm that ansible was **skipped** with the appropriate message
