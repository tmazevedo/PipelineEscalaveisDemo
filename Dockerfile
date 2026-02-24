FROM summerwind/actions-runner:latest

USER root

# Instalação das ferramentas (Azure CLI e Terraform)
RUN apt-get update && apt-get install -y curl unzip \
    && curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    && curl -f -L -o terraform.zip https://releases.hashicorp.com/terraform/1.0.7/terraform_1.0.7_linux_amd64.zip \
    && unzip terraform.zip && mv terraform /usr/local/bin/ && rm terraform.zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Criamos o script de inicialização dentro do Dockerfile para garantir o controle
RUN printf '#!/bin/bash\n\
cd /home/runner\n\
# O ARC passa as variáveis RUNNER_TOKEN e RUNNER_NAME\n\
./config.sh --url https://github.com/tmazevedo/PipelineEscalaveisDemo \
    --token ${RUNNER_TOKEN} \
    --name ${RUNNER_NAME} \
    --unattended \
    --replace \
    --ephemeral\n\
# O comando EXEC abaixo é o que impede o status "Completed"\n\
exec ./bin/Runner.Listener run' > /home/runner/entrypoint.sh

RUN chmod +x /home/runner/entrypoint.sh && chown runner:runner /home/runner/entrypoint.sh

USER runner

# Definimos o nosso script como o ponto de entrada
ENTRYPOINT ["/home/runner/entrypoint.sh"]