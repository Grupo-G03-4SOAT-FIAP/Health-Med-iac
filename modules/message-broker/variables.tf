variable "region" {
  default     = "us-east-1"
  description = "AWS region"
}

variable "tags" {
  description = "Tags to set."
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "This is the human-readable name of the queue. If omitted, Terraform will assign a random name"
  type        = string
  default     = null
}

variable "secret_name" {
  description = "Friendly name of the new secret."
  type        = string
  default     = "prod/HealthMed/SQS"
}