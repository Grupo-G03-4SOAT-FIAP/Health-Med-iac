output "region" {
  description = "AWS region"
  value       = local.region
}

output "secretsmanager_secret_name" {
  description = "Friendly name of the new secret."
  value       = aws_secretsmanager_secret.google_meet.name
}

output "secretsmanager_secret_arn" {
  description = "ARN of the secret."
  value       = aws_secretsmanager_secret.google_meet.arn
}

output "secretsmanager_secret_policy_name" {
  description = "The name of the policy."
  value       = aws_iam_policy.policy_google_meet.name
}

output "secretsmanager_secret_policy_arn" {
  description = "The ARN assigned by AWS to the policy."
  value       = aws_iam_policy.policy_google_meet.arn
}
