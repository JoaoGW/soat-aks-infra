# soat-aks-infra

Scaffold Terraform da infraestrutura Azure Kubernetes Service da plataforma
SOAT. Nenhum recurso é provisionado nesta fase.

## Estrutura

- `versions.tf`: Terraform e provider Azure declarados para validação;
- `environments/hml` e `environments/prod`: pontos de entrada reservados;
- `.github/workflows/ci.yml`: validação sem backend remoto ou credenciais.

## Validação local

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

O repositório não possui Dockerfile, pois entrega infraestrutura como código e
não uma aplicação executável. AKS, rede, Kong, Key Vault, HPA e OIDC serão
implementados na Fase 3 após revisão de custo do Azure.

