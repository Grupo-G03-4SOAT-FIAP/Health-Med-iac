output "region" {
  description = "AWS region"
  value       = local.region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.cluster_k8s.cluster_name
}

output "cluster_serviceaccount_role_arn" {
  description = "Amazon Resource Name (ARN) specifying the role."
  value       = module.cluster_k8s.serviceaccount_role_arn
}

output "cluster_serviceaccount_name" {
  description = "Kubernetes ServiceAccount name"
  value       = module.cluster_k8s.serviceaccount_name
}

output "repository_url_api" {
  description = "The URL of the repository (in the form aws_account_id.dkr.ecr.region.amazonaws.com/repositoryName)."
  value       = module.registry_api.repository_url
}

output "docker_login" {
  description = "Log in to Amazon ECR: run the following command to authenticate Docker to the Amazon ECR registry"
  value       = "aws ecr get-login-password --region ${local.region} | docker login --username AWS --password-stdin ${module.registry_api.repository_url}"
}

output "cognito_user_pool_id" {
  description = "ID of the user pool."
  value       = module.cognito_idp.cognito_user_pool_id
}

output "cognito_user_pool_client_id" {
  description = "Unique identifier for the user pool client."
  value       = module.cognito_idp.cognito_user_pool_client_id
}

output "cognito_secret_name" {
  description = "Friendly name of the new secret."
  value       = module.secrets_cognito.secretsmanager_secret_name
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${local.region} update-kubeconfig --name ${module.cluster_k8s.cluster_name}"
}
