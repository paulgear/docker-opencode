FROM    paulgear/base:latest

ARG     APT_PKGS="\
ca-certificates \
git \
python3-pip \
python3-pytest \
sudo \
"

ENV     DEBIAN_FRONTEND=noninteractive
ENV     http_proxy=${http_proxy}
ENV     https_proxy=${https_proxy}
ENV     no_proxy=${no_proxy}

ARG     http_proxy
ARG     https_proxy

RUN     apt-get update && \
        apt-get install --no-install-recommends -y ${APT_PKGS} && \
        rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/installer
ARG     BINDIR=/usr/local/bin

RUN     curl -sL https://github.com/anomalyco/opencode/releases/latest/download/opencode-linux-x64.tar.gz -o opencode.tar.gz && \
        tar -xvf opencode.tar.gz && \
        mv opencode ${BINDIR}/ && \
        chmod +x ${BINDIR}/opencode && \
        chown root:root ${BINDIR}/opencode && \
        rm -rf *

RUN     curl -sL https://github.com/sammcj/mcp-devtools/releases/latest/download/mcp-devtools-linux-amd64 -o ${BINDIR}/mcp-devtools && \
        chmod +x ${BINDIR}/mcp-devtools && \
        rm -rf *

RUN     BEADS_VERSION=$(curl -sL https://api.github.com/repos/steveyegge/beads/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/') && \
        curl -sL https://github.com/steveyegge/beads/releases/download/v${BEADS_VERSION}/beads_${BEADS_VERSION}_linux_amd64.tar.gz -o bd.tar.gz && \
        tar -xzf bd.tar.gz && \
        mv bd ${BINDIR}/ && \
        chmod +x ${BINDIR}/bd && \
        rm -rf *

# for some reason running opencode --version leaves a 4 MB .so hanging around in /tmp/
RUN     opencode --version && \
        rm -f /tmp/.*.so

RUN     mcp-devtools --version

RUN     bd --version

RUN     echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu && \
        chmod 0440 /etc/sudoers.d/ubuntu

USER    ubuntu
WORKDIR /src
