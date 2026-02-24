FROM ubuntu:22.04

ARG RUNNER_VERSION=2.311.0
ENV DEBIAN_FRONTEND=noninteractive

# 1. Instala dependências e Azure CLI
RUN apt-get update && apt-get install -y \
    curl sudo git jq ca-certificates apt-transport-https lsb-release gnupg \
    && curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    && apt-get clean

# 2. Cria usuário runner
RUN useradd -m runner && usermod -aG sudo runner && \
    echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /home/runner

RUN curl -o actions-runner-linux-x64.tar.gz -L \
    https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64.tar.gz \
    && rm actions-runner-linux-x64.tar.gz

# 4. Instala dependências do binário
RUN ./bin/installdependencies.sh && chown -R runner:runner /home/runner

USER runner

# 5. O CMD equivalente ao seu de Windows
# No ARC, o Controller passa os argumentos (@), então o binário sabe o que fazer
ENTRYPOINT ["./bin/Runner.Listener", "run"]