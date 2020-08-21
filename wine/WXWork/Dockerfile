FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive

RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list

RUN apt-get update \
    && apt-get install -y \
    vim net-tools curl wget ca-certificates locales tzdata \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/apt/sources.list.d \
    && touch /etc/apt/sources.list.d/deepin.list \
    && echo "deb [trusted=yes] https://mirrors.huaweicloud.com/deepin stable main contrib non-free" > /etc/apt/sources.list.d/deepin.list \
    && dpkg --add-architecture i386

RUN apt-get update \
    && apt-get install -y --allow-downgrades perl-base=5.24.1-3+deb9u5 \
    && apt-get install -y perl=5.24.1-3+deb9u5 \
    && apt-get install -y \
    udis86 libgif7 libreadline7 libpng16-16 libjpeg62-turbo libgnutls30 \
    libgstreamer1.0-0 libgstreamer-plugins-base1.0-0 zenity \
    fonts-wqy-microhei fonts-wqy-zenhei firefox \
    && apt-get install -y \
    deepin-fonts-wine deepin-libwine deepin-wine32 deepin-wine \
    deepin-wine32-preloader deepin-wine-binfmt deepin-wine-helper \
    deepin-wine-plugin deepin-wine-plugin-virtual deepin-wine-uninstaller \
    && rm -rf /var/lib/apt/lists/*

ENV LC_CTYPE=zh_CN.UTF-8 XMODIFIERS="@im=ibus"

RUN locale-gen en_US.UTF-8 zh_CN.UTF-8 zh_CN.GBK \
    && update-locale LANG=zh_CN.UTF-8

RUN ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata

RUN apt-get update \
    && apt-get install -y deepin.com.weixin.work \
    && rm -rf /var/lib/apt/lists/*

COPY ./run.sh /home/run.sh

RUN chmod a+x /home/run.sh

CMD [ "/bin/bash", "/home/run.sh" ]
