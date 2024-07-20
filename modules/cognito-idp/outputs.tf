output "cognito_user_pool_id" {
  description = "ID of the user pool."
  value       = aws_cognito_user_pool.health-med.id
}

output "cognito_user_pool_client_id" {
  description = "Unique identifier for the user pool client."
  value       = aws_cognito_user_pool_client.totem.id
}
