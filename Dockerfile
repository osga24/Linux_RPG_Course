
from ubuntu:latest
env debian_frontend=noninteractive

run apt update && apt upgrade -yq && \
    apt install gcc g++ binutils python3 python3-pip vim unrar zip unzip curl wget iputils-ping sudo sshpass file -yq

RUN useradd -m player
RUN mkdir /root/src
COPY /src/ /root/src

RUN chmod +x /root/src/init.sh && /root/src/init.sh && rm -rf /root/src

RUN chown -R player:link /home/link && \
    chmod -R 755 /home/player

USER player
WORKDIR /home/player

EXPOSE 10000
ENV TERM=xterm-color

CMD ["/bin/bash"]
