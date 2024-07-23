provider "aws" {
  region = local.region
}

locals {
  region = var.region

  tags = {
    Project     = "health-med"
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
terraform state rm "module.cluster_k8s.kubernetes_namespace_v1.health-med"
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
# Storage
################################################################################

module "storage_s3" {
  source = "./modules/storage-s3"

  region = local.region
  tags   = local.tags
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

  app_namespace       = "health-med" # O 'name' do namespace do k8s onde será executada a sua aplicação
  serviceaccount_name = "aws-iam-serviceaccount"

  tags = local.tags
}

################################################################################
# Container Registry
################################################################################

# API do Backend
# ------------------------------

module "registry_api" {
  source = "./modules/registry"

  repository_name = "health-med-api"

  region = local.region
  tags   = local.tags
}

################################################################################
# Message Broker
################################################################################

# Fila de exemplo
# ------------------------------

module "fila-exemplo" {
  source = "./modules/message-broker"

  region = local.region

  name        = "fila-exemplo"
  secret_name = "prod/HealthMed/SQSFilaExemplo"

  tags = local.tags
}

################################################################################
# Message Broker Policies
################################################################################

# Filas
# ------------------------------

resource "aws_iam_policy" "policy_sqs" {
  name        = "policy-sqs-health-med"
  description = "Permite publicar e consumir mensagens nas filas da Health&Med no Amazon SQS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "SQS:SendMessage",
          "SQS:ReceiveMessage",
          "sqs:DeleteMessage"
        ]
        Resource = [
          module.fila-exemplo.queue_arn,
        ]
      },
    ]
  })

  tags = local.tags

  depends_on = [
    module.cluster_k8s
  ]
}

resource "aws_iam_role_policy_attachment" "policy_sqs_to_role" {
  role       = module.cluster_k8s.serviceaccount_role_name
  policy_arn = aws_iam_policy.policy_sqs.arn

  depends_on = [
    module.cluster_k8s
  ]
}

# Secrets
# ------------------------------

resource "aws_iam_policy" "policy_secret_sqs" {
  name        = "policy-secret-sqs-health-med"
  description = "Permite acesso somente leitura aos Secrets das filas SQS da Health&Med no AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          module.fila-exemplo.secretsmanager_secret_arn
        ]
      },
    ]
  })

  tags = local.tags

  depends_on = [
    module.cluster_k8s
  ]
}

resource "aws_iam_role_policy_attachment" "fila_secret_to_role" {
  role       = module.cluster_k8s.serviceaccount_role_name
  policy_arn = aws_iam_policy.policy_secret_sqs.arn

  depends_on = [
    module.cluster_k8s
  ]
}

################################################################################
# Secrets
################################################################################

# DB API do Backend
# ------------------------------

module "secrets_db_api" {
  source = "./modules/secrets-db"

  secret_name = "prod/HealthMed/Postgresql"
  policy_name = "policy-secret-db-api"

  region = local.region
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "db_api_secret_to_role" {
  role       = module.cluster_k8s.serviceaccount_role_name
  policy_arn = module.secrets_db_api.secretsmanager_secret_policy_arn

  depends_on = [
    module.cluster_k8s
  ]
}

# Google Meet
# ------------------------------

module "secrets_google_meet" {
  source = "./modules/secrets-google-meet"

  region = local.region
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "google_meet_secret_to_role" {
  role       = module.cluster_k8s.serviceaccount_role_name
  policy_arn = module.secrets_google_meet.secretsmanager_secret_policy_arn

  depends_on = [
    module.cluster_k8s,
    module.secrets_google_meet
  ]
}

# Baseado no tutorial "Build and use a local module" do portal HashiCorp Developer em 
# https://developer.hashicorp.com/terraform/tutorials/modules/module-create
