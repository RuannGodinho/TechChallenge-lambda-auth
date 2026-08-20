variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project tag used on resources"
  type        = string
  default     = "techchallenge-fiap"
}

variable "environment" {
  description = "Environment tag (lab, dev, prod)"
  type        = string
  default     = "lab"
}

variable "name_prefix" {
  description = "Prefix for Lambda and API Gateway names (keep techchallenge-eks to match existing resources after cutover)"
  type        = string
  default     = "techchallenge-eks"
}

variable "ssm_prefix" {
  description = "SSM prefix published by TechChallenge-infra-eks"
  type        = string
  default     = "/techchallenge"
}

variable "enable_auth_gateway" {
  description = "Deploy API Gateway HTTP API with JWT sign/authorizer Lambdas"
  type        = bool
  default     = true
}

variable "eks_backend_url" {
  description = "Optional override for API Gateway HTTP integration. When empty, Terraform reads SSM /techchallenge/eks/backend_url."
  type        = string
  default     = ""
}

variable "jwt_secret" {
  description = "Shared HS256 secret for JWT sign and verify Lambdas"
  type        = string
  sensitive   = true
  default     = ""
}

variable "jwt_expires_in" {
  description = "JWT expiration passed to the sign Lambda"
  type        = string
  default     = "1h"
}

variable "auth_email" {
  description = "Login email validated by the sign Lambda"
  type        = string
  sensitive   = true
  default     = ""
}

variable "auth_password" {
  description = "Login password validated by the sign Lambda"
  type        = string
  sensitive   = true
  default     = ""
}

variable "gateway_trust_secret" {
  description = "Shared secret injected by API Gateway as X-Gateway-Trust"
  type        = string
  sensitive   = true
  default     = ""
}
