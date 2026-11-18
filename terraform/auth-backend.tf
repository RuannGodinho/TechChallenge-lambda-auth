data "aws_ssm_parameter" "eks_backend_url" {
  count = var.enable_auth_gateway && var.eks_backend_url == "" ? 1 : 0
  name  = "${var.ssm_prefix}/eks/backend_url"
}

locals {
  eks_backend_url = var.eks_backend_url != "" ? var.eks_backend_url : (
    length(data.aws_ssm_parameter.eks_backend_url) > 0 ? data.aws_ssm_parameter.eks_backend_url[0].value : ""
  )
}

data "aws_ssm_parameter" "execution_backend_url" {
  count = var.enable_auth_gateway && var.execution_backend_url == "" ? 1 : 0
  name  = "${var.ssm_prefix}/eks/execution_backend_url"
}

locals {
  execution_backend_url = var.execution_backend_url != "" ? var.execution_backend_url : (
    length(data.aws_ssm_parameter.execution_backend_url) > 0 ? data.aws_ssm_parameter.execution_backend_url[0].value : ""
  )
}

data "aws_ssm_parameter" "billing_backend_url" {
  count = var.enable_auth_gateway && var.billing_backend_url == "" ? 1 : 0
  name  = "${var.ssm_prefix}/eks/billing_backend_url"
}

locals {
  billing_backend_url = var.billing_backend_url != "" ? var.billing_backend_url : (
    length(data.aws_ssm_parameter.billing_backend_url) > 0 ? data.aws_ssm_parameter.billing_backend_url[0].value : ""
  )
}
