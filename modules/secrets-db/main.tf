provider "aws" {
  region = local.region
}

locals {
  region = var.region
}

resource "aws_secretsmanager_secret" "db" {
  name        = var.secret_name
  description = "Armazena as credenciais do banco de dados PostgreSQL"

  # recovery_window_in_days = 7 # (Optional) Number of days that AWS Secrets Manager waits before it can delete the secret. This value can be 0 to force deletion without recovery or range from 7 to 30 days. The default value is 30.
  recovery_window_in_days = 0

  tags = var.tags
}

# The map here can come from other supported configurations
# like locals, resource attribute, map() built-in, etc.
locals {
  initial = {
    # Inicializa as Keys com valores default
    # Por segurança, após o provisionamento do Secret preencha os valores abaixo manualmente no Console da AWS no link abaixo: 
    # https://us-east-1.console.aws.amazon.com/secretsmanager/secret?name=prod/HealthMed/Postgresql&region=us-east-1
    username             = null
    password             = null
    engine               = null
    host                 = null
    port                 = null
    dbInstanceIdentifier = null
  }
}

resource "aws_secretsmanager_secret_version" "version1" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = jsonencode(local.initial)
}

################################################################################
# Policies
################################################################################

resource "aws_iam_policy" "policy_secret_db" {
  name        = "policy-secret-db-${var.policy_name}"
  description = "Permite acesso somente leitura ao Secret ${aws_secretsmanager_secret.db.name} no AWS Secrets Manager"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.db.arn
      },
    ]
  })

  tags = var.tags
}

# DICA: Para forçar a exclusão de um Secret antes do fim do prazo de recovery, use o comando 
# aws secretsmanager delete-secret --secret-id nome/Segredo/Aqui --force-delete-without-recovery --region <region>

# DICA: Não esqueça de preencher o valor dos Secrets declarados acima, caso contrário você irá verá o erro "Failed to fetch secret from all regions" no k8s
