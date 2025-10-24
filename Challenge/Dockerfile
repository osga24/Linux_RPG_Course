# syntax=docker/dockerfile:1.7
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-color

# 需要 g++、runuser、基本工具
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential g++ \
      vim \
      zip unzip unrar-free \
      curl wget ca-certificates \
      iputils-ping \
      sudo \
      sshpass \
      file \
      openssh-client \
      passwd \
    && rm -rf /var/lib/apt/lists/*

# 建立玩家
RUN useradd -m -s /bin/bash player

# 複製 Challenge/src/ 到 /root/src/（build context 請指到 Challenge/）
COPY src/ /root/src/

# 先設定工作目錄，避免 su/login shell 落在 /
WORKDIR /home/player

# 執行初始化（以 root）
RUN chmod +x /root/src/init.sh && /root/src/init.sh

# 之後用 player 身份
USER player

EXPOSE 10000
CMD ["/bin/bash"]
