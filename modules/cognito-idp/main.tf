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

  schema {
    name                     = "id"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true  # false for "sub"
    required                 = false # true for "sub"
    string_attribute_constraints {   # if it is a string
      min_length = 0                 # 10 for "birthdate"
      max_length = 2048              # 10 for "birthdate"
    }
  }

  alias_attributes = ["email", "phone_number"] # Permite o usuário logar também usando e-mail ou número de telefone

  username_configuration {
    case_sensitive = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  tags = var.tags
}

################################################################################
# Cognito User Pool Client
################################################################################

resource "aws_cognito_user_pool_client" "client" {
  name = "client"

  user_pool_id = aws_cognito_user_pool.health_med.id

  generate_secret     = false
  explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
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
  username     = "194528-SP" # CRM - 6 dígitos + sigla do estado
  password     = "Mudar@123"

  attributes = {
    "custom:id" = "06f46f66-9f2e-4a27-976c-fa785936a765"
    name        = "Arao Andrade Napoleao Lima"
    email       = "arao.lima@healthmed.com.br"
  }
}

resource "aws_cognito_user_in_group" "medico_1" {
  user_pool_id = aws_cognito_user_pool.health_med.id
  group_name   = aws_cognito_user_group.medicos.name
  username     = aws_cognito_user.medico_1.username
}

# ----------

resource "aws_cognito_user" "medico_2" {
  user_pool_id = aws_cognito_user_pool.health_med.id
  username     = "202768-SP" # CRM - 6 dígitos + sigla do estado
  password     = "Mudar@123"

  attributes = {
    "custom:id" = "6bf977c6-f120-473d-8f00-97e2b5f8b18a"
    name        = "Aron da Costa Telles"
    email       = "aron.telles@healthmed.com.br"
  }
}

resource "aws_cognito_user_in_group" "medico_2" {
  user_pool_id = aws_cognito_user_pool.health_med.id
  group_name   = aws_cognito_user_group.medicos.name
  username     = aws_cognito_user.medico_2.username
}

# ----------

resource "aws_cognito_user" "medico_3" {
  user_pool_id = aws_cognito_user_pool.health_med.id
  username     = "127670-SP" # CRM - 6 dígitos + sigla do estado
  password     = "Mudar@123"

  attributes = {
    "custom:id" = "87299678-a39f-46ff-a849-79c35f561945"
    name        = "Bruno Lopes dos Santos"
    email       = "bruno.santos@healthmed.com.br"
  }
}

resource "aws_cognito_user_in_group" "medico_3" {
  user_pool_id = aws_cognito_user_pool.health_med.id
  group_name   = aws_cognito_user_group.medicos.name
  username     = aws_cognito_user.medico_3.username
}

# ----------

resource "aws_cognito_user" "medico_4" {
  user_pool_id = aws_cognito_user_pool.health_med.id
  username     = "2364-SP" # CRM - 6 dígitos + sigla do estado
  password     = "Mudar@123"

  attributes = {
    "custom:id" = "3fb50be0-b77b-4f9f-8288-adcccb79a234"
    name        = "Jarbas Camargo Barbosa de Barros"
    email       = "jarbas.barros@healthmed.com.br"
  }
}

resource "aws_cognito_user_in_group" "medico_4" {
  user_pool_id = aws_cognito_user_pool.health_med.id
  group_name   = aws_cognito_user_group.medicos.name
  username     = aws_cognito_user.medico_4.username
}

# ----------

resource "aws_cognito_user" "medico_5" {
  user_pool_id = aws_cognito_user_pool.health_med.id
  username     = "42296-SP" # CRM - 6 dígitos + sigla do estado
  password     = "Mudar@123"

  attributes = {
    "custom:id" = "107622f8-3f6a-4506-b863-5a8740a94f8f"
    name        = "Jose Francisco Goncalves Filho"
    email       = "jose.filho@healthmed.com.br"
  }
}

resource "aws_cognito_user_in_group" "medico_5" {
  user_pool_id = aws_cognito_user_pool.health_med.id
  group_name   = aws_cognito_user_group.medicos.name
  username     = aws_cognito_user.medico_5.username
}

# Pacientes
# ------------------------------

resource "aws_cognito_user" "paciente_1" {
  user_pool_id = aws_cognito_user_pool.health_med.id
  username     = "00000000191" # CPF - 11 dígitos
  password     = "Mudar@123"

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
