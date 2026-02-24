FROM ubuntu:22.04

# Versão do Runner e metadados
ARG RUNNER_VERSION=2.311.0
ENV DEBIAN_FRONTEND=noninteractive
ENV RUNNER_MANUALLY_TRAP_SIG=1
ENV ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=1
ENV ImageOS=ubuntu22

# 1. Instalação de dependências essenciais do sistema
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
    sudo lsb-release git curl ca-certificates unzip jq gnupg \
    && rm -rf /var/lib/apt/lists/*

# 2. Configuração do usuário runner (UID 1001) para segurança no AKS
RUN adduser --disabled-password --gecos "" --uid 1001 runner \
    && usermod -aG sudo runner \
    && echo "%sudo ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers

# 3. Instalação da Azure CLI (Nativa na imagem)
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# 4. Instalação do Terraform 1.0.7
RUN curl -f -L -o terraform.zip https://releases.hashicorp.com/terraform/1.0.7/terraform_1.0.7_linux_amd64.zip \
    && unzip terraform.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform.zip

# 5. Instalação do Binário do GitHub Runner (Download manual)
WORKDIR /actions-runner
RUN curl -f -L -o runner.tar.gz https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./runner.tar.gz \
    && rm runner.tar.gz \
    && ./bin/installdependencies.sh

# 6. Instalação de ferramentas de Segurança e Qualidade
# TFLint
RUN curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
# Trivy
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.50.1
# Fortify fcli
RUN mkdir -p /tmp/fcli/bin \
    && curl -f -L -o /tmp/fcli/fcli-linux.tgz https://github.com/fortify/fcli/releases/download/v2.3.0/fcli-linux.tgz \
    && tar -zxvf /tmp/fcli/fcli-linux.tgz -C /tmp/fcli/bin \
    && chmod 755 /tmp/fcli/bin/fcli \
    && ln -s /tmp/fcli/bin/fcli /usr/local/bin/fcli

# Este script usa as variáveis que o Actions Runner Controller (ARC) injeta via PAT
RUN printf '#!/bin/bash\n\
cd /actions-runner\n\
# O ARC injeta RUNNER_TOKEN e RUNNER_NAME automaticamente\n\
./config.sh --url https://github.com/tmazevedo/PipelineEscalaveisDemo \
    --token ${RUNNER_TOKEN} \
    --name ${RUNNER_NAME} \
    --labels ${RUNNER_LABELS} \
    --unattended \
    --replace \
    --ephemeral\n\
# O exec garante que o processo do runner receba os sinais de parada do Kubernetes\n\
exec ./bin/Runner.Listener run' > start.sh

RUN chmod +x start.sh && \
    chown -R runner:runner /actions-runner && \
    mkdir -p /actions-runner/_diag && \
    chown -R runner:runner /actions-runner/_diag

USER runner

ENTRYPOINT ["./start.sh"]