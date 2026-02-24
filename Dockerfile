# Usa a imagem oficial do ARC como base
FROM ghcr.io/actions/actions-runner:latest

USER root

# Instala dependências básicas e a Azure CLI
RUN apt-get update && apt-get install -y \
    curl \
    apt-transport-https \
    lsb-release \
    gnupg \
    && curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Volta para o usuário padrão do runner por segurança
USER runner