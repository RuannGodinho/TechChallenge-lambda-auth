check "auth_gateway_requires_backend_url" {
  assert {
    condition     = !var.enable_auth_gateway || local.eks_backend_url != ""
    error_message = "Could not resolve eks_backend_url. Apply TechChallenge-infra-eks first (SSM /techchallenge/eks/backend_url) or set eks_backend_url."
  }
}

check "auth_gateway_requires_jwt_secret" {
  assert {
    condition     = !var.enable_auth_gateway || var.jwt_secret != ""
    error_message = "jwt_secret must be set when enable_auth_gateway is true."
  }
}

check "auth_gateway_requires_auth_email" {
  assert {
    condition     = !var.enable_auth_gateway || var.auth_email != ""
    error_message = "auth_email must be set when enable_auth_gateway is true."
  }
}

check "auth_gateway_requires_auth_password" {
  assert {
    condition     = !var.enable_auth_gateway || var.auth_password != ""
    error_message = "auth_password must be set when enable_auth_gateway is true."
  }
}

check "auth_gateway_requires_trust_secret" {
  assert {
    condition     = !var.enable_auth_gateway || var.gateway_trust_secret != ""
    error_message = "gateway_trust_secret must be set when enable_auth_gateway is true."
  }
}

check "auth_lambda_production_deps_installed" {
  assert {
    condition = (
      !var.enable_auth_gateway ||
      try(data.external.auth_lambda_prepare[0].result.prepared, "") == "true"
    )
    error_message = "Lambda production dependencies were not installed before packaging auth-lambda.zip."
  }
}
