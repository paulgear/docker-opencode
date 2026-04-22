FROM    paulgear/base:latest

ARG     APT_PKGS="\
ca-certificates \
git \
gnupg \
jq \
openssh-client \
pylint \
python3-pip \
python3-pytest \
python3-venv \
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

# Add Docker's official GPG key and repository
RUN     curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
        echo "deb [signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list && \
        apt-get update && \
        apt-get install --no-install-recommends -y docker-ce-cli && \
        rm -rf /var/lib/apt/lists/*

# Add NodeSource GPG key and repository for Node.js 20.x LTS
RUN     curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
        echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \
        apt-get update && \
        apt-get install --no-install-recommends -y nodejs && \
        rm -rf /var/lib/apt/lists/*

# Add HashiCorp GPG key and repository for Terraform
RUN     curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg && \
        echo "deb [signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo "$VERSION_CODENAME") main" > /etc/apt/sources.list.d/hashicorp.list && \
        apt-get update && \
        apt-get install --no-install-recommends -y terraform && \
        rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/installer
ARG     BINDIR=/usr/local/bin
ARG     OPENCODE_VERSION=v1.4.3

RUN     if [ "${OPENCODE_VERSION}" = "latest" ]; then \
            API_URL="https://api.github.com/repos/anomalyco/opencode/releases/latest"; \
        else \
            API_URL="https://api.github.com/repos/anomalyco/opencode/releases/tags/${OPENCODE_VERSION}"; \
        fi && \
        curl -fsSL ${API_URL} -o release.json && \
        OPENCODE_VERSION=$(jq -r '.tag_name' release.json) && \
        OPENCODE_SHA256=$(jq -r '.assets[] | select(.name=="opencode-linux-x64.tar.gz") | .digest' release.json | cut -d: -f2) && \
        curl -fsSL https://github.com/anomalyco/opencode/releases/download/${OPENCODE_VERSION}/opencode-linux-x64.tar.gz -o opencode.tar.gz && \
        echo "${OPENCODE_SHA256}  opencode.tar.gz" | sha256sum -c - && \
        tar -xvf opencode.tar.gz && \
        mv opencode ${BINDIR}/ && \
        chmod +x ${BINDIR}/opencode && \
        chown root:root ${BINDIR}/opencode && \
        rm -rf *

RUN     MCPDEVTOOLS_SHA256=$(curl -fsSL https://api.github.com/repos/sammcj/mcp-devtools/releases/latest | jq -r '.assets[] | select(.name=="mcp-devtools-linux-amd64") | .digest' | cut -d: -f2) && \
        curl -fsSL https://github.com/sammcj/mcp-devtools/releases/latest/download/mcp-devtools-linux-amd64 -o ${BINDIR}/mcp-devtools && \
        echo "${MCPDEVTOOLS_SHA256}  ${BINDIR}/mcp-devtools" | sha256sum -c - && \
        chmod +x ${BINDIR}/mcp-devtools && \
        rm -rf *

RUN     curl -fsSL https://api.github.com/repos/ArjenSchwarz/rune/releases/latest -o release.json && \
        RUNE_VERSION=$(jq -r '.tag_name' release.json | sed 's/^v//') && \
        RUNE_SHA256=$(jq -r '.assets[] | select(.name=="rune-v'${RUNE_VERSION}'-linux-amd64.tar.gz") | .digest' release.json | cut -d: -f2) && \
        curl -fsSL https://github.com/ArjenSchwarz/rune/releases/download/v${RUNE_VERSION}/rune-v${RUNE_VERSION}-linux-amd64.tar.gz -o rune.tar.gz && \
        echo "${RUNE_SHA256}  rune.tar.gz" | sha256sum -c - && \
        tar -xzf rune.tar.gz && \
        mv rune ${BINDIR}/ && \
        chmod +x ${BINDIR}/rune && \
        rm -rf *

RUN     echo 'ubuntu ALL=(ALL) NOPASSWD:ALL \n\
Defaults env_keep += "http_proxy https_proxy no_proxy"' > /etc/sudoers.d/ubuntu && \
        chmod 0440 /etc/sudoers.d/ubuntu

# for some reason the docker image seems to default to root ownership
RUN     chown ubuntu:ubuntu /home/ubuntu

COPY    --chmod=0755 opencode /usr/local/bin

# for some reason running opencode --version leaves a 4 MB .so hanging around in /tmp/
RUN     opencode --version && \
        rm -f /tmp/.*.so

RUN     mcp-devtools --version

RUN     rune --version

RUN     terraform --version

USER    ubuntu
WORKDIR /src
