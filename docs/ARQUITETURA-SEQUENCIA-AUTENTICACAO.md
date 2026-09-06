# Diagrama de Sequência — Autenticação

Fluxo de login e validação de JWT na solução **Node-Fiap**, em produção (`AUTH_MODE=gateway`).

O login **não** chega ao pod Express. A Lambda `AuthSign` **deste** repositório emite o token; o **API Gateway Authorizer** valida o Bearer nas demais rotas.

Índice da solução: [TechChallenge-Fiap / ARQUITETURA.md](https://github.com/RuannGodinho/TechChallenge-Fiap/blob/main/docs/ARQUITETURA.md). Componentes: [ARQUITETURA-COMPONENTES.md](https://github.com/RuannGodinho/TechChallenge-Fiap/blob/main/docs/ARQUITETURA-COMPONENTES.md). Decisão: [RFC-003](rfcs/003-autenticacao-jwt-api-gateway.md) / [ADR-003](adrs/003-autenticacao-jwt-api-gateway.md).

| O que o enunciado pede | Neste documento |
|---|---|
| Sequência do fluxo de autenticação | Diagrama abaixo: login sem authorizer → JWT → chamada autenticada (`GET /api/me`) |

---

## Diagrama

```mermaid
sequenceDiagram
  autonumber
  actor Cliente
  participant GW as API Gateway
  participant Sign as Lambda AuthSign
  participant AuthZ as Lambda Authorizer
  participant API as API Express EKS

  Cliente->>GW: POST /api/login { email, password }
  GW->>Sign: Invoca Lambda (sem authorizer)

  alt JSON inválido ou campos ausentes
    Sign-->>GW: 400 Email e senha são obrigatórios
    GW-->>Cliente: 400
  else Credenciais diferentes de AUTH_EMAIL / AUTH_PASSWORD
    Sign-->>GW: 401 Credenciais inválidas
    GW-->>Cliente: 401
  else Credenciais válidas
    Sign->>Sign: jwt.sign { userId, email } com JWT_SECRET
    Sign-->>GW: 200 { token }
    GW-->>Cliente: 200 { token }
  end

  Note over Cliente,API: Chamadas autenticadas usam o mesmo token

  Cliente->>GW: GET /api/me  Authorization Bearer token
  GW->>AuthZ: Valida Bearer

  alt Token ausente, malformado ou inválido
    AuthZ-->>GW: isAuthorized false
    GW-->>Cliente: 401
  else Token válido
    AuthZ-->>GW: isAuthorized true  context userId, email
    GW->>API: GET /api/me<br/>x-user-id, x-user-email, x-gateway-trust
    API->>API: gatewayUserMiddleware compara x-gateway-trust
    API-->>GW: 200 { user: { userId, email } }
    GW-->>Cliente: 200
  end
```

---

## Contrato do login

| Item | Valor |
|---|---|
| Método e path | `POST /api/login` |
| Body | `{ "email": string, "password": string }` |
| Sucesso | `200 { "token": "<jwt>" }` |
| Payload do JWT | `{ userId: "mock-user", email }` |
| Algoritmo | HS256 (`JWT_SECRET`) |
| Expiração | `JWT_EXPIRES_IN` (default `1h`) |
| Header nas demais rotas | `Authorization: Bearer <token>` |

Headers injetados pelo Gateway no backend (não devem ser forjados pelo cliente):

- `x-user-id` / `x-user-email` — contexto do authorizer
- `x-gateway-trust` — segredo compartilhado (`GATEWAY_TRUST_SECRET`), comparado com `crypto.timingSafeEqual`

Tentativa de login direto no NodePort, com `AUTH_MODE=gateway`, retorna **410** (`Login disponível apenas via API Gateway`).

---

## Modo local (Docker Compose + SAM)

Com `AUTH_MODE=local` (default), o Express no [TechChallenge-Fiap](https://github.com/RuannGodinho/TechChallenge-Fiap) autentica internamente. Esse modo não é o de produção no EKS.

Auth com Gateway simulado: API com `AUTH_MODE=gateway` + `sam local start-api` neste repo (porta 3001). Ver README da raiz.

---

## Documentação relacionada

- [docs deste repo](README.md)
- [RFC-003](rfcs/003-autenticacao-jwt-api-gateway.md) / [ADR-003](adrs/003-autenticacao-jwt-api-gateway.md)
- [Sequência — Abertura de OS](https://github.com/RuannGodinho/TechChallenge-Fiap/blob/main/docs/ARQUITETURA-SEQUENCIA-ORDEM-SERVICO.md)
- [Diagrama de Componentes](https://github.com/RuannGodinho/TechChallenge-Fiap/blob/main/docs/ARQUITETURA-COMPONENTES.md)
