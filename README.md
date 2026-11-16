# soat-aks-infra

Infraestrutura Azure Kubernetes Service da plataforma SOAT. Este repositório
provisiona a rede compartilhada, AKS, Key Vault, identities federadas e a base
Kubernetes para homologação e produção.

## Arquitetura

```mermaid
flowchart LR
  GH[GitHub Actions com OIDC] --> AKS[AKS compartilhado]
  AKS --> HML[Namespace hml]
  AKS --> PROD[Namespace prod]
  AKS --> KONG[Namespace kong]
  AKS --> OBS[Namespace observability]
  AKS --> KV[Azure Key Vault]
  AKS --> VNET[VNet 10.30.0.0/16]
  VNET --> PGNET[Subnet PostgreSQL delegada]
  VNET --> FUNCNET[Subnet reservada para Function]
```

O diagrama central e as decisões arquiteturais estão em
[soat-api/docs/architecture](https://github.com/JoaoGW/soat-api/tree/main/docs/architecture).

## Stacks

- `foundation`: VNet, subnets, DNS privado PostgreSQL, Key Vault, AKS,
  Workload Identity, Secrets Store CSI e identities OIDC para infraestrutura,
  Function e pipeline da API.
- `environments/hml`: namespace `hml`, namespaces compartilhados `kong` e
  `observability`, Kong e os recursos compartilhados da rota HML.
- `environments/prod`: namespace `prod` no mesmo cluster.

O AKS usa Azure CNI Overlay, Azure RBAC, OIDC, Secrets Store CSI e
autoscaling de um a dois nós. O cluster implantado usa `Standard_D2as_v6`.
O Deployment HML da API, Kong e o coletor `nr-k8s-otel-collector` estão ativos;
HPA/PDB e duas réplicas pertencem ao Deployment produtivo. Não são usados
Prometheus, Grafana ou Azure Monitor nesta arquitetura.

As identities `api_hml` e `api_prod` autenticam o workflow da API por OIDC e
recebem os papéis Azure Kubernetes Service Cluster User e Azure Kubernetes
Service RBAC Cluster Admin somente no cluster. O primeiro permite obter a
credencial do cluster; o segundo autoriza a operação Kubernetes. As identities
de workload `api_workload[hml|prod]` são federadas aos
ServiceAccounts de mesmo ambiente e podem apenas ler segredos do Key Vault.
Os client IDs necessários estão no output não sigiloso
`github_identity_client_ids` e os de workload em `api_workload_client_ids`.

## Fase 4: mensageria e identidades dos microsserviços

O módulo `modules/fase4-messaging` (ativado por `fase4_messaging_enabled=true`
em `environments/hml`) cria o Azure Service Bus usado pela Saga orquestrada:

| Recurso | Uso | Quem envia | Quem recebe |
| --- | --- | --- | --- |
| Fila `billing.commands` | Comandos da Saga para o Billing | OS | Billing |
| Fila `execution.commands` | Comandos da Saga para o Execution | OS | Execution |
| Tópico `soat.domain.events` | Eventos de domínio assinados | OS, Billing, Execution | — |
| Subscription `os.saga-events` | Eventos consumidos pelo orquestrador | — | OS |
| Subscription `billing.evidence` | Provas `execution.work-cancelled.v1` e `execution.work-failed.v1` exigidas para reembolso/cancelamento de cobrança | — | Billing |

Cada serviço tem uma identidade gerenciada federada ao ServiceAccount do seu
Deployment no namespace `hml` (`soat-api`, `soat-billing-service` e
`soat-execution-service`; o OS seleciona a identidade de mensageria por
`SERVICE_BUS_CLIENT_ID`, porque a mesma ServiceAccount também usa a identidade
do Key Vault) e recebe apenas os papéis
`Azure Service Bus Data Sender/Receiver` das entidades da tabela; não há chave
compartilhada (`local_auth_enabled=false`). Os bancos ficam em
`soat-postgres-infra` (OS e Billing) e em `soat-execution-service/infra`
(Cosmos DB do Execution).

### Ambiente Kubernetes em uso

A assinatura Azure da entrega está desativada e os workflows de apply ficam
atrás da trava de custo (`TF_APPLY_ENABLED`): sem ela o deploy não tenta login
no Azure e termina verde com o aviso no resumo do job. Enquanto o AKS estiver
desligado, o ambiente Kubernetes verificável é o cluster kind criado pelo CI
de cada serviço (`Deploy Kubernetes (kind)`) e pelo workflow
`Fluxo completo em Kubernetes` do `soat-api`, que sobe os três serviços, seus
bancos e o emulador do Service Bus com a mesma topologia desta tabela.

## Pré-requisitos e bootstrap

- Azure CLI autenticado na assinatura Free Account correta;
- Terraform 1.9.8, kubelogin, TFLint e Trivy;
- grupos `rg-soat-platform`, `rg-soat-data` e `rg-soat-auth`, além da Storage
  Account privada de state criados na Fase 0;
- SKU implantado `Standard_D2as_v6`, quota e crédito validados em Brazil South.

O primeiro `apply` da `foundation` é feito localmente com login interativo para
criar as identities OIDC que quebram o ciclo inicial do CI. Copie os arquivos
`*.example` para arquivos locais ignorados, preencha os nomes reais do state e
execute apenas após validar o custo:

```bash
terraform -chdir=foundation init -backend-config=.backend.hcl
terraform -chdir=foundation plan -out=foundation.tfplan
terraform -chdir=foundation apply foundation.tfplan
```

Não há fallback automático de SKU e não existe `apply` permitido enquanto a
estimativa e o crédito não forem revisados.

## CI/CD e variáveis

PRs executam formatação, validação, TFLint, Trivy e plano somente leitura
quando o bootstrap OIDC estiver concluído. `development` promove `hml` e
`main` promove `prod`; ambos só aplicam quando a variável do Environment
`TF_APPLY_ENABLED` for `true`.

As variáveis não sigilosas necessárias são `AZURE_TENANT_ID`,
`AZURE_SUBSCRIPTION_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_ID_PLAN`,
`TF_STATE_RESOURCE_GROUP`, `TF_STATE_STORAGE_ACCOUNT`,
`TF_STATE_AKS_CONTAINER` e `RESOURCE_NAME_SUFFIX`. Nenhuma senha ou client
secret é aceita pelo pipeline.

O workflow de destroy exige a palavra `DESTRUIR` e
`TF_DESTROY_ENABLED=true`. Use-o após registrar as evidências da entrega.

## Validação local

```bash
terraform fmt -check -recursive
for stack in foundation environments/hml environments/prod modules/fase4-messaging; do
  terraform -chdir="$stack" init -backend=false -input=false
  terraform -chdir="$stack" validate
done
tflint --recursive
trivy config --ignorefile .trivyignore --severity CRITICAL .
```

Este repositório não possui Dockerfile: entrega infraestrutura como código,
não uma aplicação executável. Swagger e Postman não se aplicam a Terraform;
consulte o [Swagger HML](http://20.226.244.207/docs) e a
[coleção central](https://github.com/JoaoGW/soat-api/blob/main/docs/postman/oficina-api.postman_collection.json).
