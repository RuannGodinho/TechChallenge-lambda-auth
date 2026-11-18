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
    "overwrite:header.X-User-Cpf"      = "$context.authorizer.cpf"
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

# Keep Orders' existing catch-all; route only the resources owned by the split services.
locals {
  split_backend_urls = {
    execution = local.execution_backend_url
    billing   = local.billing_backend_url
  }
  split_service_resources = {
    pecas             = "execution"
    servicos          = "execution"
    estoque           = "execution"
    execucoes-servico = "execution"
    metricas          = "execution"
    orcamentos        = "billing"
  }
  split_service_routes = merge(
    { for resource, service in local.split_service_resources : "${resource}-root" => {
      service = service
      path    = "/api/${resource}"
      route   = "ANY /api/${resource}"
    } },
    { for resource, service in local.split_service_resources : "${resource}-proxy" => {
      service = service
      path    = "/api/${resource}/{proxy}"
      route   = "ANY /api/${resource}/{proxy+}"
    } }
  )
}

resource "aws_apigatewayv2_integration" "split_service" {
  for_each = var.enable_auth_gateway ? local.split_service_routes : {}

  api_id             = aws_apigatewayv2_api.auth[0].id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = "${trim(local.split_backend_urls[each.value.service], "/")}${each.value.path}"
  connection_type    = "INTERNET"

  request_parameters = {
    "overwrite:header.X-Gateway-Trust" = var.gateway_trust_secret
    "overwrite:header.X-User-Id"       = "$context.authorizer.userId"
    "overwrite:header.X-User-Email"    = "$context.authorizer.email"
    "overwrite:header.X-User-Cpf"      = "$context.authorizer.cpf"
  }

  lifecycle {
    precondition {
      condition     = local.split_backend_urls[each.value.service] != "" && local.split_backend_urls[each.value.service] != "pending"
      error_message = "Resolve Execution and Billing NodePort URLs before applying gateway routes."
    }
  }
}

resource "aws_apigatewayv2_route" "split_service" {
  for_each = var.enable_auth_gateway ? local.split_service_routes : {}

  api_id             = aws_apigatewayv2_api.auth[0].id
  route_key          = each.value.route
  target             = "integrations/${aws_apigatewayv2_integration.split_service[each.key].id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt[0].id
}

# Mercado Pago authenticates its webhook signature in Billing; this route does not use JWT.
resource "aws_apigatewayv2_integration" "billing_webhook" {
  count = var.enable_auth_gateway ? 1 : 0

  api_id             = aws_apigatewayv2_api.auth[0].id
  integration_type   = "HTTP_PROXY"
  integration_method = "POST"
  integration_uri    = "${trim(local.billing_backend_url, "/")}/webhooks/mercado-pago"
  connection_type    = "INTERNET"

  lifecycle {
    precondition {
      condition     = local.billing_backend_url != "" && local.billing_backend_url != "pending"
      error_message = "Resolve Billing's NodePort URL before applying its webhook route."
    }
  }
}

resource "aws_apigatewayv2_route" "billing_webhook" {
  count = var.enable_auth_gateway ? 1 : 0

  api_id    = aws_apigatewayv2_api.auth[0].id
  route_key = "POST /webhooks/mercado-pago"
  target    = "integrations/${aws_apigatewayv2_integration.billing_webhook[0].id}"
}
