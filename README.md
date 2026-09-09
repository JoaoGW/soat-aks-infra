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

## Variáveis, arquitetura e CI

Não há variáveis Terraform nem arquivos `.tfvars` nesta fase; eles serão
adicionados na Fase 3 e permanecerão fora do Git. Consulte o
[diagrama central](https://github.com/JoaoGW/soat-api/blob/main/docs/architecture/README.md#mapa-de-responsabilidades-dos-repositórios).
O [workflow CI](https://github.com/JoaoGW/soat-aks-infra/actions/workflows/ci.yml)
executa formatação e validação Terraform em `main` e `development`.
