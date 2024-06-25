provider "aws" {
  region = local.region
}

locals {
  region = var.region

  tags = {
    Project     = "rms"
    Terraform   = "true"
    Environment = "prod"
  }
}

/*
# Command shortcuts
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
terraform apply --auto-approve
terraform apply -var "name=value"
terraform show
terraform destroy
terraform destroy --auto-approve
*/

/*
# Para provisionar somente um módulo específico:
terraform plan -target="module.cognito_idp"
terraform apply -target="module.cognito_idp"
terraform destroy -target="module.cognito_idp"
*/

/*
# Para remover um recurso específico do tfstate:
terraform state rm "module.cluster_k8s.kubernetes_namespace_v1.rms"
*/

################################################################################
# Network
################################################################################

module "network" {
  source = "./modules/network"

  region = local.region
  tags   = local.tags
}

################################################################################
# Database
################################################################################

module "db" {
  source = "./modules/db-sql"

  region = local.region

  vpc_id          = module.network.vpc_id
  public_subnets  = module.network.public_subnets
  private_subnets = module.network.private_subnets

  tags = local.tags
}

################################################################################
# API Gateway
################################################################################

module "api-gateway" {
  source = "./modules/api-gateway"

  region = local.region
  tags   = local.tags
}

################################################################################
# Identity provider (IdP)
################################################################################

module "cognito_idp" {
  source = "./modules/cognito-idp"

  region = local.region
  tags   = local.tags
}

module "secrets_cognito" {
  source = "./modules/secrets-cognito"

  cognito_user_pool_id        = module.cognito_idp.cognito_user_pool_id
  cognito_user_pool_client_id = module.cognito_idp.cognito_user_pool_client_id

  region = local.region
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "cognito_secret_to_role" {
  role       = module.cluster_k8s.serviceaccount_role_name
  policy_arn = module.secrets_cognito.secretsmanager_secret_policy_arn

  depends_on = [
    module.cluster_k8s,
    module.cognito_idp,
    module.secrets_cognito
  ]
}

################################################################################
# Kubernetes
################################################################################

module "cluster_k8s" {
  source = "./modules/cluster-k8s"

  region = local.region

  vpc_id          = module.network.vpc_id
  public_subnets  = module.network.public_subnets
  private_subnets = module.network.private_subnets

  app_namespace       = "rms" # O 'name' do namespace do k8s onde será executada a sua aplicação
  serviceaccount_name = "aws-iam-serviceaccount"

  tags = local.tags
}

################################################################################
# Container Registry
################################################################################

# API Catálogo
# ------------------------------

module "registry_api_catalogo" {
  source = "./modules/registry"

  repository_name = "rms-api-catalogo"

  region = local.region
  tags   = local.tags
}

# API de Pedidos
# ------------------------------

module "registry_api_pedidos" {
  source = "./modules/registry"

  repository_name = "rms-api-pedidos"

  region = local.region
  tags   = local.tags
}

# API de Pagamentos
# ------------------------------

module "registry_api_pagamentos" {
  source = "./modules/registry"

  repository_name = "rms-api-pagamentos"

  region = local.region
  tags   = local.tags
}

################################################################################
# Message Broker
################################################################################

# Nova cobrança
# ------------------------------

module "fila-nova-cobranca" {
  source = "./modules/message-broker"

  region = local.region

  name        = "nova-cobranca"
  secret_name = "prod/RMS/SQSNovaCobranca"

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "fila_nova_cobranca_to_role" {
  role       = module.cluster_k8s.serviceaccount_role_name
  policy_arn = module.fila-nova-cobranca.policy_arn

  depends_on = [
    module.cluster_k8s
  ]
}

resource "aws_iam_role_policy_attachment" "fila_nova_cobranca_secret_to_role" {
  role       = module.cluster_k8s.serviceaccount_role_name
  policy_arn = module.fila-nova-cobranca.secretsmanager_secret_policy_arn

  depends_on = [
    module.cluster_k8s
  ]
}

# Cobrança gerada
# ------------------------------

module "fila-cobranca-gerada" {
  source = "./modules/message-broker"

  region = local.region

  name        = "cobranca-gerada"
  secret_name = "prod/RMS/SQSCobrancaGerada"

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "fila_cobranca_gerada_to_role" {
  role       = module.cluster_k8s.serviceaccount_role_name
  policy_arn = module.fila-cobranca-gerada.policy_arn

  depends_on = [
    module.cluster_k8s
  ]
}

resource "aws_iam_role_policy_attachment" "fila_cobranca_gerada_secret_to_role" {
  role       = module.cluster_k8s.serviceaccount_role_name
  policy_arn = module.fila-cobranca-gerada.secretsmanager_secret_policy_arn

  depends_on = [
    module.cluster_k8s
  ]
}

# Falha na cobrança
# ------------------------------

module "fila-falha-cobranca" {
  source = "./modules/message-broker"

  region = local.region

  name        = "falha-cobranca"
  secret_name = "prod/RMS/SQSFalhaCobranca"

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "fila_falha_cobranca_to_role" {
  role       = module.cluster_k8s.serviceaccount_role_name
  policy_arn = module.fila-falha-cobranca.policy_arn

  depends_on = [
    module.cluster_k8s
  ]
}

resource "aws_iam_role_policy_attachment" "fila_falha_cobranca_secret_to_role" {
  role       = module.cluster_k8s.serviceaccount_role_name
  policy_arn = module.fila-falha-cobranca.secretsmanager_secret_policy_arn

  depends_on = [
    module.cluster_k8s
  ]
}

################################################################################
# Secrets
################################################################################

# DB API Catálogo
# ------------------------------

module "secrets_db_catalogo" {
  source = "./modules/secrets-db"

  secret_name = "prod/catalogo/Postgresql"
  policy_name = "policy-secret-db-catalogo"

  region = local.region
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "db_catalogo_secret_to_role" {
  role       = module.cluster_k8s.serviceaccount_role_name
  policy_arn = module.secrets_db_catalogo.secretsmanager_secret_policy_arn

  depends_on = [
    module.cluster_k8s
  ]
}

# DB API de Pedidos
# ------------------------------

module "secrets_db_pedidos" {
  source = "./modules/secrets-db"

  secret_name = "prod/pedidos/Postgresql"
  policy_name = "policy-secret-db-pedidos"

  region = local.region
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "db_pedidos_secret_to_role" {
  role       = module.cluster_k8s.serviceaccount_role_name
  policy_arn = module.secrets_db_pedidos.secretsmanager_secret_policy_arn

  depends_on = [
    module.cluster_k8s
  ]
}

# DB API de Pagamentos
# ------------------------------

module "secrets_db_pagamentos" {
  source = "./modules/secrets-db"

  secret_name = "prod/pagamentos/Mongodb"
  policy_name = "policy-secret-db-pagamentos"

  region = local.region
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "db_pagamentos_secret_to_role" {
  role       = module.cluster_k8s.serviceaccount_role_name
  policy_arn = module.secrets_db_pagamentos.secretsmanager_secret_policy_arn

  depends_on = [
    module.cluster_k8s
  ]
}

# Mercado Pago
# ------------------------------

module "secrets_mercadopago" {
  source = "./modules/secrets-mercadopago"

  region = local.region
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "mercadopago_secret_to_role" {
  role       = module.cluster_k8s.serviceaccount_role_name
  policy_arn = module.secrets_mercadopago.secretsmanager_secret_policy_arn

  depends_on = [
    module.cluster_k8s,
    module.secrets_mercadopago
  ]
}

# Baseado no tutorial "Build and use a local module" do portal HashiCorp Developer em 
# https://developer.hashicorp.com/terraform/tutorials/modules/module-create
