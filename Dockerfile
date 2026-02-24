# Usamos a imagem oficial que você já validou que funciona no ARC
FROM summerwind/actions-runner:latest

USER root

# 1. Instala Azure CLI e Terraform 1.0.7
RUN apt-get update && apt-get install -y curl unzip \
    && curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    && curl -f -L -o terraform.zip https://releases.hashicorp.com/terraform/1.0.7/terraform_1.0.7_linux_amd64.zip \
    && unzip terraform.zip && mv terraform /usr/local/bin/ && rm terraform.zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Voltamos para o usuário runner (padrão da imagem summerwind)
USER runner