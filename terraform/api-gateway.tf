resource "aws_apigatewayv2_api" "auth" {
  count         = var.enable_auth_gateway ? 1 : 0
  name          = "${local.name}-http-api"
  protocol_type = "HTTP"
  tags          = local.common_tags

}

resource "aws_apigatewayv2_stage" "default" {
  count       = var.enable_auth_gateway ? 1 : 0
  api_id      = aws_apigatewayv2_api.auth[0].id
  name        = "$default"
  auto_deploy = true
  tags        = local.common_tags
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  count = var.enable_auth_gateway ? 1 : 0

  api_id                            = aws_apigatewayv2_api.auth[0].id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.auth_authorizer[0].invoke_arn
  identity_sources                  = ["$request.header.Authorization"]
  name                              = "${local.name}-jwt-authorizer"
  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = true
  authorizer_result_ttl_in_seconds  = 0
}

resource "aws_apigatewayv2_integration" "auth_sign" {
  count = var.enable_auth_gateway ? 1 : 0

  api_id                 = aws_apigatewayv2_api.auth[0].id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.auth_sign[0].invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "eks_proxy" {
  count = var.enable_auth_gateway ? 1 : 0

  api_id             = aws_apigatewayv2_api.auth[0].id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = "${trim(local.eks_backend_url, "/")}/api/{proxy}"
  connection_type    = "INTERNET"

  request_parameters = {
    "overwrite:header.X-Gateway-Trust" = var.gateway_trust_secret
    "overwrite:header.X-User-Id"       = "$context.authorizer.userId"
    "overwrite:header.X-User-Email"    = "$context.authorizer.email"
  }
}

resource "aws_apigatewayv2_integration" "public_ordem_detalhes" {
  count = var.enable_auth_gateway ? 1 : 0

  api_id             = aws_apigatewayv2_api.auth[0].id
  integration_type   = "HTTP_PROXY"
  integration_method = "GET"
  integration_uri    = "${trim(local.eks_backend_url, "/")}/api/ordensServico/{cpfCnpj}/detalhes"
  connection_type    = "INTERNET"
}

resource "aws_apigatewayv2_integration" "public_docs" {
  count = var.enable_auth_gateway ? 1 : 0

  api_id             = aws_apigatewayv2_api.auth[0].id
  integration_type   = "HTTP_PROXY"
  integration_method = "GET"
  integration_uri    = "${trim(local.eks_backend_url, "/")}/docs"
  connection_type    = "INTERNET"
}

resource "aws_apigatewayv2_integration" "public_docs_proxy" {
  count = var.enable_auth_gateway ? 1 : 0

  api_id             = aws_apigatewayv2_api.auth[0].id
  integration_type   = "HTTP_PROXY"
  integration_method = "GET"
  integration_uri    = "${trim(local.eks_backend_url, "/")}/docs/{proxy}"
  connection_type    = "INTERNET"
}

resource "aws_apigatewayv2_integration" "public_swagger_json" {
  count = var.enable_auth_gateway ? 1 : 0

  api_id             = aws_apigatewayv2_api.auth[0].id
  integration_type   = "HTTP_PROXY"
  integration_method = "GET"
  integration_uri    = "${trim(local.eks_backend_url, "/")}/swagger.json"
  connection_type    = "INTERNET"
}

resource "aws_apigatewayv2_route" "login" {
  count = var.enable_auth_gateway ? 1 : 0

  api_id    = aws_apigatewayv2_api.auth[0].id
  route_key = "POST /api/login"
  target    = "integrations/${aws_apigatewayv2_integration.auth_sign[0].id}"
}

resource "aws_apigatewayv2_route" "public_ordem_detalhes" {
  count = var.enable_auth_gateway ? 1 : 0

  api_id    = aws_apigatewayv2_api.auth[0].id
  route_key = "GET /api/ordensServico/{cpfCnpj}/detalhes"
  target    = "integrations/${aws_apigatewayv2_integration.public_ordem_detalhes[0].id}"
}

resource "aws_apigatewayv2_route" "docs" {
  count = var.enable_auth_gateway ? 1 : 0

  api_id    = aws_apigatewayv2_api.auth[0].id
  route_key = "GET /docs"
  target    = "integrations/${aws_apigatewayv2_integration.public_docs[0].id}"
}

resource "aws_apigatewayv2_route" "docs_proxy" {
  count = var.enable_auth_gateway ? 1 : 0

  api_id    = aws_apigatewayv2_api.auth[0].id
  route_key = "GET /docs/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.public_docs_proxy[0].id}"
}

resource "aws_apigatewayv2_route" "swagger_json" {
  count = var.enable_auth_gateway ? 1 : 0

  api_id    = aws_apigatewayv2_api.auth[0].id
  route_key = "GET /swagger.json"
  target    = "integrations/${aws_apigatewayv2_integration.public_swagger_json[0].id}"
}

resource "aws_apigatewayv2_route" "protected_api" {
  count = var.enable_auth_gateway ? 1 : 0

  api_id             = aws_apigatewayv2_api.auth[0].id
  route_key          = "ANY /api/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.eks_proxy[0].id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt[0].id
}
