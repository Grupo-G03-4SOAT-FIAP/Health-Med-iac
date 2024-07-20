# Health&Med
## Infrastructure as code (IaC)

[![Terraform Apply](https://github.com/Grupo-G03-4SOAT-FIAP/Health-Med-iac/actions/workflows/terraform-apply.yml/badge.svg)](https://github.com/Grupo-G03-4SOAT-FIAP/Health-Med-iac/actions/workflows/terraform-apply.yml)
[![Terraform Plan](https://github.com/Grupo-G03-4SOAT-FIAP/Health-Med-iac/actions/workflows/terraform-plan.yml/badge.svg)](https://github.com/Grupo-G03-4SOAT-FIAP/Health-Med-iac/actions/workflows/terraform-plan.yml)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=Grupo-G03-4SOAT-FIAP_Health-Med-iac&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=Grupo-G03-4SOAT-FIAP_Health-Med-iac)
[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=Grupo-G03-4SOAT-FIAP_Health-Med-iac&metric=security_rating)](https://sonarcloud.io/summary/new_code?id=Grupo-G03-4SOAT-FIAP_Health-Med-iac)

Projeto desenvolvido durante o Hackatown da Pós Tech em Software Architecture da FIAP.

asdasdasd

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)

[Ver no Terraform Cloud](https://app.terraform.io/app/Grupo-G03-4SOAT-FIAP/workspaces/Health-Med-iac)↗️

## Pré-requisitos

Você deve ter instalado o [Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli), a [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), o [kubectl](https://kubernetes.io/docs/tasks/tools/) e possuir uma conta na AWS.

Antes de começar, você precisa definir duas variáveis de ambiente em seu computador: `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY`

```bash
export AWS_ACCESS_KEY_ID=???
```

```bash
export AWS_SECRET_ACCESS_KEY=???
```

> Substitua os sinais de interrogação `???` acima pelas suas credenciais do IAM da AWS.

> [!TIP]
> Você pode obter o **ID da chave de acesso** do seu usuário do IAM na AWS e sua respectiva **Chave de acesso secreta** na seção "[Minhas credenciais de segurança](https://us-east-1.console.aws.amazon.com/iam/home#/security_credentials)" no console da AWS, conforme instruções na página [Managing access keys for IAM users](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey).

## Como aplicar o plano de execução do Terraform manualmente

1. Clone este repositório;
2. Navegue até a pasta raiz do projeto;
3. Use o comando `terraform init` para baixar e instalar os módulos e providers;
4. Use o comando `terraform fmt -recursive` para formatar e identar os arquivos .tf
5. Use o comando `terraform validate` para validar os arquivos de configuração;
6. Use o comando `terraform plan` para revisar o plano de execução;
7. Use o comando `terraform apply` para aplicar o plano de execução;

> Você também pode fazer `terraform apply --auto-approve` ou `terraform destroy --auto-approve` para aplicar o plano ou destruir a infra imediatamente, pulando a aprovação (não recomendado).

<details>

<summary>Como provisionar somente um módulo específico?</summary>

<br>

Para provisionar somente um módulo específico, use a opção `-target`:

```sh
terraform init
terraform apply -target="module.cognito_idp"
terraform destroy -target="module.cognito_idp"
```

</details>

<details>

<summary>Como remover um recurso do tfstate?</summary>

<br>

Para remover um recurso do `terraform.tfstate` use o comando abaixo:

```sh
terraform state rm "module.cluster_k8s.kubernetes_namespace_v1.rms"
```

Isso é útil por exemplo quando o Terraform por algum motivo não é capaz de fazer a destruição de um recurso específico com `terraform destroy`, impedindo a destruição dos demais.

</details>

> Para excluir a infraestrutura provisionada pelo Terraform, use o comando `terraform destroy`

> Você também pode visualizar o tfstate através do comando `terraform show`

## Projetos relacionados

API do Backend\
https://github.com/Grupo-G03-4SOAT-FIAP/Health-Med-api

## Requisitos

*Terraform 1.7.3, aws-cli/2.15.10*

[![SonarCloud](https://sonarcloud.io/images/project_badges/sonarcloud-white.svg)](https://sonarcloud.io/summary/new_code?id=Grupo-G03-4SOAT-FIAP_Health-Med-iac)
