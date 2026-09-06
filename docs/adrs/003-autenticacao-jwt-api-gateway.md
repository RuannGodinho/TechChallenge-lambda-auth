# ADR – Autenticamos com JWT na borda do API Gateway

**Casa:** [TechChallenge-lambda-auth](https://github.com/RuannGodinho/TechChallenge-lambda-auth).

| Campo | Valor |
|---|---|
| **Número** | 003 |
| **Data** | 21/08/2026 |
| **Dono** | Ruann Correa Godinho |
| **Status** | Aceita |
| **RFC de origem** | [RFC-003](../rfcs/003-autenticacao-jwt-api-gateway.md) |

## Contexto

A API expõe dados da oficina. Validar token só no Express deixa o NodePort como superfície. Um IdP completo (Cognito, Keycloak) estoura o recorte: um usuário mock, demonstração de login, 401 e `/api/me`. Precisamos do mesmo fluxo no SAM local e no EKS.

## Decisão

Emitimos JWT **HS256** na Lambda **AuthSign** (`POST /api/login`) e validamos o Bearer no **Authorizer** do API Gateway. No EKS a API usa `AUTH_MODE=gateway`: o pod confia em `x-user-id`, `x-user-email` e `x-gateway-trust`. Login direto no NodePort responde 410. No Compose, `AUTH_MODE=local` assina e valida no próprio Express. A consulta pública de OS permanece exceção ([ADR-015 no Fiap](https://github.com/RuannGodinho/TechChallenge-Fiap/blob/main/docs/adrs/015-consulta-publica-os.md)).

## Consequências

Centralizamos emissão e validação na borda e separamos logs de auth (CloudWatch) dos da API. O custo das Lambdas no laboratório é desprezível. Pagamos cold start, um único par de credenciais, segredo HS256 compartilhado e a dependência de `GATEWAY_TRUST_SECRET` não vazar. Rotação de secret é manual.

## Alternativas

Descartamos Cognito pela complexidade de User Pool neste challenge. Descartamos JWT só no Express porque o NodePort viraria a borda. Descartamos sessão + cookie por causa do HPA sem store compartilhado. Descartamos OAuth2/OIDC completo e mTLS (exigiria ALB/certificados).
