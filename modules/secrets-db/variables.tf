variable "region" {
  default     = "us-east-1"
  description = "AWS region"
}

variable "tags" {
  description = "Tags to set."
  type        = map(string)
  default     = {}
}

variable "secret_name" {
  description = "Friendly name of the new secret."
  type        = string
  default     = "prod/HealthMed/Postgresql"
}


variable "policy_name" {
  description = "Name of the policy."
  type        = string
  default     = "policy-secret-db"
}
