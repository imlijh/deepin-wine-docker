FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive

ENV USER=pulseaudio \
    UID=1000 \
    GROUPS=audio
ENV HOME=/home/${USER} \
    TZ=Asia/Shanghai

RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y pulseaudio pulseaudio-utils tzdata \
    && rm -rf /var/lib/apt/lists/*

COPY [ "./default.pa", "./client.conf", "./daemon.conf", "/etc/pulse/" ]

RUN useradd -u ${UID} -m -d ${HOME} -s /usr/sbin/nologin ${USER} \
    && usermod -aG ${GROUPS} ${USER} \
    && chmod 0644 -- /etc/pulse/* \
    && mkdir -p ${HOME}/.config/pulse \
    && chown -Rh ${USER}:${USER} -- ${HOME}

WORKDIR ${HOME}
USER ${USER}
VOLUME [ "/tmp", "${HOME}/.config/pulse" ]
ENTRYPOINT [ "/usr/bin/pulseaudio" ]
