FROM python:3.13

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    vim \
    less \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root

# COPY . /root/.rayrc
# RUN bash -c "cd /root/ && source .rayrc/install"

## ローカルのディレクトリ(.rayrc)をコンテナの /root/.rayrc にコピー
# RUN bash -c "cd && git clone -b dev_docker --single-branch --depth 1 https://github.com/cr1315/.rayrc.git && source .rayrc/install"
