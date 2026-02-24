FROM ubuntu:22.04

ARG RUNNER_VERSION=2.311.0

ENV DEBIAN_FRONTEND=noninteractive
ENV RUNNER_MANUALLY_TRAP_SIG=1
ENV ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=1
ENV ImageOS=ubuntu22

# Instalação de dependências do sistema
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
    sudo lsb-release git curl ca-certificates unzip jq \
    && rm -rf /var/lib/apt/lists/*

# Configuração do usuário runner (UID 1001 como no seu padrão)
RUN adduser --disabled-password --gecos "" --uid 1001 runner \
    && usermod -aG sudo runner \
    && echo "%sudo ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers

# Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Terraform 1.0.7
RUN curl -f -L -o terraform.zip https://releases.hashicorp.com/terraform/1.0.7/terraform_1.0.7_linux_amd64.zip \
    && unzip terraform.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform.zip

# Instalação do Binário do Runner 
WORKDIR /actions-runner
RUN curl -f -L -o runner.tar.gz https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./runner.tar.gz \
    && rm runner.tar.gz \
    && ./bin/installdependencies.sh

# Ferramentas de Lint e Segurança
RUN curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.50.1

RUN mkdir -p /tmp/fcli/bin \
    && curl -f -L -o /tmp/fcli/fcli-linux.tgz https://github.com/fortify/fcli/releases/download/v2.3.0/fcli-linux.tgz \
    && tar -zxvf /tmp/fcli/fcli-linux.tgz -C /tmp/fcli/bin \
    && chmod 755 /tmp/fcli/bin/fcli \
    && ln -s /tmp/fcli/bin/fcli /usr/local/bin/fcli

# Script de Inicialização
COPY scripts/start.sh start.sh
RUN chmod +x start.sh && chown -R runner:runner /actions-runner

USER runner

ENTRYPOINT ["./start.sh"]