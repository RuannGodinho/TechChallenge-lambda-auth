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

check "auth_gateway_requires_execution_backend_url" {
  assert {
    condition     = !var.enable_auth_gateway || (local.execution_backend_url != "" && local.execution_backend_url != "pending")
    error_message = "Apply TechChallenge-infra-eks first or set execution_backend_url to a reachable NodePort URL."
  }
}

check "auth_gateway_requires_billing_backend_url" {
  assert {
    condition     = !var.enable_auth_gateway || (local.billing_backend_url != "" && local.billing_backend_url != "pending")
    error_message = "Apply TechChallenge-infra-eks first or set billing_backend_url to a reachable NodePort URL."
  }
}
