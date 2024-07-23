provider "aws" {
  region = var.region
}

locals {
  region = var.region
}

################################################################################
# Prontuários dos Pacientes
################################################################################

resource "aws_s3_bucket" "prontuarios_pacientes" {
  bucket = "prontuarios-pacientes"

  force_destroy = true # Default: false

  tags = var.tags
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.prontuarios_pacientes.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [aws_s3_bucket_ownership_controls.example]

  bucket = aws_s3_bucket.prontuarios_pacientes.id
  acl    = "private" # Defaults to private
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.prontuarios_pacientes.id

  rule {
    id = "rule-1"

    transition {
      storage_class = "GLACIER_IR"
    }

    status = "Enabled"
  }
}

################################################################################
# Criptografia com o KMS
################################################################################

resource "aws_kms_key" "mykey" {
  description             = "This key is used to encrypt bucket objects"
  # deletion_window_in_days = 10
  deletion_window_in_days = 7
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.prontuarios_pacientes.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.mykey.arn
      sse_algorithm     = "aws:kms"
    }

    bucket_key_enabled = true
  }
}
