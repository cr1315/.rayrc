FROM python:3.13

## apt over https: the Debian base image ships http:// mirrors, which fail where
## outbound :80 is blocked (https is preferable anyway)
RUN sed -i 's#http://deb.debian.org#https://deb.debian.org#g' /etc/apt/sources.list.d/debian.sources

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    vim \
    less \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root

## rayrc itself is not baked in: mount the work tree at run time and copy it
## (see SKILL.md / .ci/snapshot.sh)
##   docker run --rm -v "$PWD":/work:ro rayrc-test bash -c "cp -a /work /root/.rayrc && cd /root && source .rayrc/install"
