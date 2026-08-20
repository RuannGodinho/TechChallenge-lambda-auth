# TechChallenge-lambda-auth

Funções serverless de autenticação JWT (`auth-sign`, `auth-authorizer`) e API Gateway HTTP que faz proxy autenticado para a API no EKS.

> **Não aplique este stack enquanto o Terraform do monorepo ainda criar as Lambdas.** Use a state key `split/lambda-auth/terraform.tfstate`. Apply duplicaria nomes (`techchallenge-eks-auth-sign`).

## Layout

```text
auth/                 # código Lambda (Jest + SAM local)
terraform/            # Lambda, IAM, API Gateway
```

O empacote (`terraform/scripts/prepare-auth-lambda.js`) instala deps de produção em `auth/` e gera `terraform/builds/auth-lambda.zip`.

## Dependências

1. Cluster EKS publicado pelo [TechChallenge-infra-eks](https://github.com/RuannGodinho/TechChallenge-infra-eks) (SSM `/techchallenge/eks/backend_url`).
2. API no NodePort `30080` (repo da aplicação).
3. Secrets GitHub iguais aos da API: `JWT_SECRET`, `AUTH_EMAIL`, `AUTH_PASSWORD`, `GATEWAY_TRUST_SECRET`.

## CI/CD

| Workflow | Gatilho | Efeito |
|---|---|---|
| CI | push/PR | testes Jest em `auth/` + `terraform fmt/validate` |
| Terraform | manual | plan/apply/destroy (`confirm=yes`) |

Ordem de apply: **EKS → app K8s → este repo**.

## SAM local

Os testes unitários rodam só com Node. SAM (`sam local start-api`) ainda precisa da API Express do [TechChallenge-Fiap](https://github.com/RuannGodinho/TechChallenge-Fiap) (`docker-compose.yml` + `docker-compose.sam.yml`).
