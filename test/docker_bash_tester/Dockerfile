FROM python:3.8.15

# RUN cd $HOME \
#     && apt update -y \
#     && apt install -y tree \
#     && apt install -y vim \
#     && apt install -y eza \
#     && apt-get clean autoclean \
#     && apt-get autoremove --yes \
#     && rm -rf /var/lib/{apt,cache,log}/ \
#     && git clone --single-branch --depth 1 https://github.com/cr1315/.rayrc.git \
#     && bash .rayrc/install

COPY .rayrc.sh /tmp/

RUN bash /tmp/.rayrc.sh

