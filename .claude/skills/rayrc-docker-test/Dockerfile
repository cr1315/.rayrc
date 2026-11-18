FROM python:3.13

## apt over https: the Debian base image ships http:// mirrors, which fail where
## outbound :80 is blocked (https is preferable anyway)
RUN sed -i 's#http://deb.debian.org#https://deb.debian.org#g' /etc/apt/sources.list.d/debian.sources

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    vim \
    less \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root

# COPY . /root/.rayrc
# RUN bash -c "cd /root/ && source .rayrc/install"

## ローカルのディレクトリ(.rayrc)をコンテナの /root/.rayrc にコピー
# RUN bash -c "cd && git clone -b dev_docker --single-branch --depth 1 https://github.com/cr1315/.rayrc.git && source .rayrc/install"
