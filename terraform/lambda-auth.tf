locals {
  auth_lambda_env = {
    JWT_SECRET     = var.jwt_secret
    JWT_EXPIRES_IN = var.jwt_expires_in
    AUTH_EMAIL     = var.auth_email
    AUTH_PASSWORD  = var.auth_password
  }

  auth_lambda_source_files = [
    "${path.module}/../auth/package.json",
    "${path.module}/../auth/package-lock.json",
    "${path.module}/../auth/sign/handler.js",
    "${path.module}/../auth/authorizer/handler.js",
    "${path.module}/../auth/shared/config.js",
    "${path.module}/../auth/shared/jwt.js",
  ]

  auth_lambda_source_hash = sha256(join("", [
    for file_path in local.auth_lambda_source_files : fileexists(file_path) ? filemd5(file_path) : ""
  ]))
}

data "external" "auth_lambda_prepare" {
  count = var.enable_auth_gateway ? 1 : 0

  program = ["node", "${path.module}/scripts/prepare-auth-lambda.js"]

  query = {
    source_hash = local.auth_lambda_source_hash
  }
}

data "archive_file" "auth_lambda" {
  count = var.enable_auth_gateway ? 1 : 0

  depends_on = [data.external.auth_lambda_prepare]

  type        = "zip"
  source_dir  = "${path.module}/../auth"
  output_path = "${path.module}/builds/auth-lambda.zip"

  excludes = [
    "tests",
    "local",
    "events",
    "scripts",
    "backend-proxy",
    ".aws-sam",
    "template.yaml",
    "samconfig.toml",
    "env.local.json",
    ".env.local",
    ".env.local.example",
    "node_modules/.cache",
  ]
}

resource "aws_cloudwatch_log_group" "auth_sign" {
  count             = var.enable_auth_gateway ? 1 : 0
  name              = "/aws/lambda/${local.name}-auth-sign"
  retention_in_days = 14
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "auth_authorizer" {
  count             = var.enable_auth_gateway ? 1 : 0
  name              = "/aws/lambda/${local.name}-auth-authorizer"
  retention_in_days = 14
  tags              = local.common_tags
}

resource "aws_lambda_function" "auth_sign" {
  count = var.enable_auth_gateway ? 1 : 0

  function_name = "${local.name}-auth-sign"
  role          = aws_iam_role.auth_lambda[0].arn
  handler       = "sign/handler.handler"
  runtime       = "nodejs20.x"
  timeout       = 10
  memory_size   = 128

  filename         = data.archive_file.auth_lambda[0].output_path
  source_code_hash = data.archive_file.auth_lambda[0].output_base64sha256

  environment {
    variables = local.auth_lambda_env
  }

  depends_on = [
    aws_cloudwatch_log_group.auth_sign,
    aws_iam_role_policy_attachment.auth_lambda_basic,
  ]

  lifecycle {
    precondition {
      condition = (
        var.jwt_secret != "" &&
        var.auth_email != "" &&
        var.auth_password != "" &&
        var.gateway_trust_secret != ""
      )
      error_message = "jwt_secret, auth_email, auth_password, and gateway_trust_secret must be set when enable_auth_gateway is true."
    }
  }

  tags = local.common_tags
}

resource "aws_lambda_function" "auth_authorizer" {
  count = var.enable_auth_gateway ? 1 : 0

  function_name = "${local.name}-auth-authorizer"
  role          = aws_iam_role.auth_lambda[0].arn
  handler       = "authorizer/handler.handler"
  runtime       = "nodejs20.x"
  timeout       = 10
  memory_size   = 128

  filename         = data.archive_file.auth_lambda[0].output_path
  source_code_hash = data.archive_file.auth_lambda[0].output_base64sha256

  environment {
    variables = local.auth_lambda_env
  }

  depends_on = [
    aws_cloudwatch_log_group.auth_authorizer,
    aws_iam_role_policy_attachment.auth_lambda_basic,
  ]

  lifecycle {
    precondition {
      condition = (
        var.jwt_secret != "" &&
        var.auth_email != "" &&
        var.auth_password != "" &&
        var.gateway_trust_secret != ""
      )
      error_message = "jwt_secret, auth_email, auth_password, and gateway_trust_secret must be set when enable_auth_gateway is true."
    }
  }

  tags = local.common_tags
}

resource "aws_lambda_permission" "auth_sign_apigw" {
  count = var.enable_auth_gateway ? 1 : 0

  statement_id  = "AllowAPIGatewayInvokeSign"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_sign[0].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.auth[0].execution_arn}/*/*"
}

resource "aws_lambda_permission" "auth_authorizer_apigw" {
  count = var.enable_auth_gateway ? 1 : 0

  statement_id  = "AllowAPIGatewayInvokeAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_authorizer[0].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.auth[0].execution_arn}/authorizers/${aws_apigatewayv2_authorizer.jwt[0].id}"
}
