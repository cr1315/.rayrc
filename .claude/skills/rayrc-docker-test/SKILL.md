---
name: rayrc-docker-test
description: Build a Docker image and run the .rayrc install script in a clean container to verify effect and logs
allowed-tools: Bash
---

# .rayrc Docker Clean Environment Test

Run the following steps to test the `.rayrc` install in a clean Docker environment.

## Step 1: Confirm working directory

Make sure you are in the project root `/home/ray/.rayrc`:

```bash
pwd
```

## Step 2: Build the Docker image

```bash
docker build --no-cache -t rayrc-test .
```

## Step 3: Run install in clean container

```bash
docker run --rm rayrc-test bash -c "
  cd &&
  git clone -b dev_docker --single-branch --depth 1 https://github.com/cr1315/.rayrc.git &&
  source .rayrc/install
"
```

## Notes

- `--no-cache`: ensures a completely fresh build every time
- `--rm`: removes the container automatically after it exits
- Branch `dev_docker` is used; commit and push before testing
- GitHub API rate limits may apply on consecutive builds (eget uses GitHub API)
- After running, report the full output to the user and highlight:
  - Any errors or warnings
  - Which modules installed successfully
  - Specifically check whether `20_pipx`, `21_poetry`, `22_glances`, `23_ansible` all appear in order
  - On Python 3.11+, confirm that ansible was **skipped** with the appropriate message
