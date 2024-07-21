provider "aws" {
  region = local.region
}

locals {
  region = var.region
}

resource "aws_cognito_user_pool" "health_med" {
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

  user_pool_id = aws_cognito_user_pool.health_med.id

  generate_secret     = false
  explicit_auth_flows = ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_CUSTOM_AUTH"]
}

################################################################################
# Grupos
################################################################################

resource "aws_cognito_user_group" "medicos" {
  name         = "medicos"
  user_pool_id = aws_cognito_user_pool.health_med.id
  description  = "Médicos da Health&Med"
}

resource "aws_cognito_user_group" "pacientes" {
  name         = "pacientes"
  user_pool_id = aws_cognito_user_pool.health_med.id
  description  = "Pacientes da Health&Med"
}

################################################################################
# Users
################################################################################

# Médicos
# ------------------------------

resource "aws_cognito_user" "medico_1" {
  user_pool_id = aws_cognito_user_pool.health_med.id
  username     = "123456" # CRM - 6 dígitos + sigla do estado

  attributes = {
    name  = "Dr. Albert Feffer"
    email = "albert.feffer@healthmed.com.br"
  }
}

resource "aws_cognito_user_in_group" "medico_1" {
  user_pool_id = aws_cognito_user_pool.health_med.id
  group_name   = aws_cognito_user_group.medicos.name
  username     = aws_cognito_user.medico_1.username
}

# Pacientes
# ------------------------------

resource "aws_cognito_user" "paciente_1" {
  user_pool_id = aws_cognito_user_pool.health_med.id
  username     = "00000000191" # CPF - 11 dígitos

  attributes = {
    name  = "Fulano da Silva"
    email = "fulano.silva@gmail.com"
  }
}

resource "aws_cognito_user_in_group" "paciente_1" {
  user_pool_id = aws_cognito_user_pool.health_med.id
  group_name   = aws_cognito_user_group.pacientes.name
  username     = aws_cognito_user.paciente_1.username
}
