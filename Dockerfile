FROM summerwind/actions-runner:latest

USER root

# Instalação das ferramentas (Azure CLI e Terraform)
RUN apt-get update && apt-get install -y curl unzip \
    && curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    && curl -f -L -o terraform.zip https://releases.hashicorp.com/terraform/1.0.7/terraform_1.0.7_linux_amd64.zip \
    && unzip terraform.zip && mv terraform /usr/local/bin/ && rm terraform.zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Criamos o script de inicialização diretamente aqui
RUN printf '#!/bin/bash\n\
cd /home/runner\n\
# O Controller (ARC) passa essas variáveis via PAT\n\
./config.sh --url https://github.com/tmazevedo/PipelineEscalaveisDemo \
    --token ${RUNNER_TOKEN} \
    --name ${RUNNER_NAME} \
    --labels ${RUNNER_LABELS} \
    --unattended \
    --replace \
    --ephemeral\n\
# O comando EXEC abaixo substitui o shell pelo Runner e mantém o container VIVO\n\
exec ./bin/Runner.Listener run' > /home/runner/entrypoint.sh

RUN chmod +x /home/runner/entrypoint.sh && chown runner:runner /home/runner/entrypoint.sh

USER runner

# Definimos o novo ponto de entrada
ENTRYPOINT ["/home/runner/entrypoint.sh"]