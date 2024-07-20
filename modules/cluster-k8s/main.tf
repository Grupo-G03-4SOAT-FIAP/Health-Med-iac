provider "aws" {
  region = local.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

locals {
  name   = "health-med-prd-k8scluster"
  region = var.region
  tags   = var.tags
}

################################################################################
# Cluster
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8"

  cluster_name                   = local.name
  cluster_version                = "1.29"
  cluster_endpoint_public_access = true

  # Give the Terraform identity admin access to the cluster
  # which will allow resources to be deployed into the cluster
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"] # A instance_type do Free Tier é t2.micro

      # min_size     = 2
      # max_size     = 10
      # desired_size = 2
      min_size     = 1
      max_size     = 3
      desired_size = 1
    }
  }

  tags = local.tags
}

################################################################################
# EKS Blueprints Addons
################################################################################

# Terraform module which provisions addons on Amazon EKS clusters
# https://registry.terraform.io/modules/aws-ia/eks-blueprints-addons/aws/latest

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.16"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_metrics_server = true

  tags = local.tags

  depends_on = [
    module.eks
  ]
}

################################################################################
# Helm packages
################################################################################

# Use AWS Secrets Manager secrets in Amazon Elastic Kubernetes Service
# install the Secrets Store CSI Driver and ASCP
# https://docs.aws.amazon.com/secretsmanager/latest/userguide/integrating_csi_driver.html#integrating_csi_driver_install

resource "helm_release" "csi-secrets-store" {
  name       = "csi-secrets-store"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  namespace  = "kube-system"

  # Optional Values
  # See https://secrets-store-csi-driver.sigs.k8s.io/getting-started/installation.html#optional-values
  set {
    name  = "syncSecret.enabled"
    value = "true"
  }
  set {
    name  = "enableSecretRotation"
    value = "true"
  }

  depends_on = [
    module.eks,
    module.eks_blueprints_addons
  ]
}

resource "helm_release" "secrets-provider-aws" {
  name       = "secrets-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  namespace  = "kube-system"

  depends_on = [
    module.eks,
    module.eks_blueprints_addons,
    helm_release.csi-secrets-store
  ]
}

################################################################################
# Namespaces
################################################################################

# Declare o(s) namespaces caso deseje que o Terraform exclua os Services, 
# e consequentemente os Load Balancers atrelados a eles, ao fazer "terraform destroy"

resource "kubernetes_namespace_v1" "health-med" {
  metadata {
    name = var.app_namespace
  }

  depends_on = [
    module.eks
  ]
}

################################################################################
# Supporting Resources
################################################################################

# Configuração de uma conta de serviço do Kubernetes para assumir um perfil do IAM
# Todos os Pods configurados para usar a conta de serviço podem então acessar quaisquer AWS service (Serviço da AWS) para os quais a função tenha permissões de acesso.
# https://docs.aws.amazon.com/pt_br/eks/latest/userguide/associate-service-account-role.html

resource "aws_iam_role" "serviceaccount_role" {
  name = "aws-iam-serviceaccount-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:aud" : "sts.amazonaws.com",
            "${module.eks.oidc_provider}:sub" : "system:serviceaccount:${var.app_namespace}:${var.serviceaccount_name}"
          }
        }
      },
    ]
  })

  tags = local.tags
}

# NOTAS

# Baseado no tutorial "Provision an EKS cluster (AWS)" do portal HashiCorp Developer em 
# https://developer.hashicorp.com/terraform/tutorials/kubernetes/eks 
# https://github.com/hashicorp/learn-terraform-provision-eks-cluster/blob/main/main.tf 
# e no Istio pattern Blueprint do projeto "Amazon EKS Blueprints for Terraform" em 
# https://github.com/aws-ia/terraform-aws-eks-blueprints/tree/main/patterns/istio

# A documentação do Istio em https://istio.io/latest/docs/setup/platform-setup/amazon-eks/ 
# recomenda a instação do Istio no EKS da AWS através do "EKS Blueprints for Istio" do projeto "Amazon EKS Blueprints for Terraform", disponível em 
# https://github.com/aws-ia/terraform-aws-eks-blueprints/tree/main/patterns/istio

# SOLUÇÃO DE PROBLEMAS

# Caso der erro 
# "Error: deleting EC2 Internet Gateway (igw-???): detaching EC2 Internet Gateway (igw-???) from VPC (vpc-???): DependencyViolation: Network vpc-??? has some mapped public address(es). Please unmap those public address(es) before detaching the gateway."
# ao fazer 'terraform destroy' acesse https://us-east-1.console.aws.amazon.com/ec2/home#LoadBalancers e exclua o Load Balancer manualmente através do console da AWS ou da AWS CLI e tente executar 'terraform destroy' novamente.

# Caso der erro 
# "Error: deleting EC2 VPC (vpc-0f61381943c87ae59): operation error EC2: DeleteVpc, https response error StatusCode: 400, RequestID: b3cf023b-67f2-4421-b73c-a9604de5b9ab, api error DependencyViolation: The vpc 'vpc-0f61381943c87ae59' has dependencies and cannot be deleted."
# ao fazer 'terraform destroy' acesse https://us-east-1.console.aws.amazon.com/vpcconsole/home#vpcs e exclua a VPC manualmente através do console da AWS ou da AWS CLI e tente executar 'terraform destroy' novamente.
