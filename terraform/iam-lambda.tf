resource "aws_iam_role" "auth_lambda" {
  count = var.enable_auth_gateway ? 1 : 0
  name  = "${local.name}-auth-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "auth_lambda_basic" {
  count      = var.enable_auth_gateway ? 1 : 0
  role       = aws_iam_role.auth_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
