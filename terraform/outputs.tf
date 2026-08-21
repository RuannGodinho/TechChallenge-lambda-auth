output "auth_api_gateway_url" {
  description = "Invoke URL for the JWT auth HTTP API"
  value       = var.enable_auth_gateway ? aws_apigatewayv2_api.auth[0].api_endpoint : ""
}

output "auth_sign_lambda_name" {
  description = "Name of the JWT sign Lambda function"
  value       = var.enable_auth_gateway ? aws_lambda_function.auth_sign[0].function_name : ""
}

output "auth_authorizer_lambda_name" {
  description = "Name of the JWT authorizer Lambda function"
  value       = var.enable_auth_gateway ? aws_lambda_function.auth_authorizer[0].function_name : ""
}

output "eks_backend_url" {
  description = "Backend URL used by API Gateway HTTP integrations"
  value       = var.enable_auth_gateway ? local.eks_backend_url : ""
  sensitive   = true
}
