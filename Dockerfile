FROM ubuntu:22.04

# Versão do Runner (Pode passar via --build-arg)
ARG RUNNER_VERSION=2.311.0

# Evita perguntas interativas durante a instalação
ENV DEBIAN_FRONTEND=noninteractive

# 1. Instala dependências básicas e Azure CLI
RUN apt-get update && apt-get install -y \
    curl \
    sudo \
    git \
    jq \
    ca-certificates \
    apt-transport-https \
    lsb-release \
    gnupg \
    && curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    && apt-get clean

# 2. Cria um usuário 'runner' (O runner não pode rodar como root)
RUN useradd -m runner && \
    usermod -aG sudo runner && \
    echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /home/runner

# 3. Baixa e descompacta o binário do GitHub Runner (Lógica que você pediu)
RUN curl -o actions-runner-linux-x64.tar.gz -L \
    https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64.tar.gz \
    && rm actions-runner-linux-x64.tar.gz

# 4. Instala dependências extras que o binário do runner exige para rodar no Linux
RUN ./bin/installdependencies.sh

# Muda para o usuário runner
USER runner

# O entrypoint padrão para o ARC funcionar
ENTRYPOINT ["./bin/Runner.Listener", "run"]