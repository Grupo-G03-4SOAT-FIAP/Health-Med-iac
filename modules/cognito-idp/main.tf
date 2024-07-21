provider "aws" {
  region = local.region
}

locals {
  region = var.region
}

resource "aws_cognito_user_pool" "health-med" {
  name = "usuarios-health-med"

  deletion_protection = "INACTIVE"
  mfa_configuration   = "OFF"

  schema {
    name                = "name"
    attribute_data_type = "String"
    required            = true # Torna o atributo 'name' obrigatório ao se registrar
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true # Torna o atributo 'email' obrigatório ao se registrar
  }

  alias_attributes = ["email", "phone_number"] # Permite o usuário logar também usando e-mail ou número de telefone

  username_configuration {
    case_sensitive = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  # Customizing user pool workflows with Lambda triggers
  # https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools-working-with-aws-lambda-triggers.html
  # lambda_config {
  #   pre_sign_up                    = "" # (Optional) Pre-registration AWS Lambda trigger.
  #   define_auth_challenge          = "" # (Optional) Defines the authentication challenge.
  #   create_auth_challenge          = "" # (Optional) ARN of the lambda creating an authentication challenge.
  #   verify_auth_challenge_response = "" # (Optional) Verifies the authentication challenge response.
  # }

  tags = var.tags
}

################################################################################
# Cognito User Pool Client
################################################################################

resource "aws_cognito_user_pool_client" "totem" {
  name = "Totem"

  user_pool_id = aws_cognito_user_pool.health-med.id

  generate_secret     = false
  explicit_auth_flows = ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_CUSTOM_AUTH"]
}

################################################################################
# Users
################################################################################

# Usuário anônimo para clientes que optarem por não se identificar
resource "aws_cognito_user" "anonimo" {
  user_pool_id = aws_cognito_user_pool.health-med.id
  username     = "00000000191" # CPF - 11 dígitos

  attributes = {
    name  = "Cliente Anônimo"
    email = "cliente@anonimo.com"
  }
}
