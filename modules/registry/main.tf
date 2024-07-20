provider "aws" {
  region = local.region
}

locals {
  region = var.region
}

data "aws_caller_identity" "current" {}

module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 2.2"

  repository_name = var.repository_name

  repository_image_tag_mutability = "MUTABLE" # Default "IMMUTABLE"
  repository_force_delete         = true      # If true, will delete the repository even if it contains images. Defaults to false.

  repository_read_write_access_arns = [data.aws_caller_identity.current.arn]

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus   = "any",
          countType   = "imageCountMoreThan",
          countNumber = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = var.tags
}

# Para obter instruções de como fazer login no Amazon ECR visite a página
# https://docs.aws.amazon.com/AmazonECR/latest/userguide/getting-started-cli.html#cli-authenticate-registry
# aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ????????????.dkr.ecr.us-east-1.amazonaws.com
# docker build -t ????????????.dkr.ecr.us-east-1.amazonaws.com/health-med:latest .
# docker push ????????????.dkr.ecr.us-east-1.amazonaws.com/health-med:latest
