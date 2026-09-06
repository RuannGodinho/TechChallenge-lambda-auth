# Documentação — TechChallenge-lambda-auth

Este repositório documenta a **autenticação JWT** na borda (API Gateway + Lambdas). A API da oficina e o cluster EKS moram nos [repositórios irmãos](../README.md).

Índice da solução: [TechChallenge-Fiap / docs/ARQUITETURA.md](https://github.com/RuannGodinho/TechChallenge-Fiap/blob/main/docs/ARQUITETURA.md).

| Documento | Conteúdo |
|---|---|
| [Sequência — Autenticação](ARQUITETURA-SEQUENCIA-AUTENTICACAO.md) | Login AuthSign, JWT e Authorizer |
| [RFCs](rfcs/README.md) | [RFC-003](rfcs/003-autenticacao-jwt-api-gateway.md) |
| [ADRs](adrs/README.md) | [ADR-003](adrs/003-autenticacao-jwt-api-gateway.md) |

## O que não fica aqui

| Assunto | Repositório |
|---|---|
| Componentes, abertura de OS, modelo de dados | [TechChallenge-Fiap](https://github.com/RuannGodinho/TechChallenge-Fiap/tree/main/docs) |
| AWS, EKS, NodePort, Terraform do cluster | [TechChallenge-infra-eks](https://github.com/RuannGodinho/TechChallenge-infra-eks/tree/main/docs) |
| MongoDB / Atlas | [TechChallenge-infra-db](https://github.com/RuannGodinho/TechChallenge-infra-db/tree/main/docs) |
