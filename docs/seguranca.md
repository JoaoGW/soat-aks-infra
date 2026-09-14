# Exceções de segurança da infraestrutura AKS

O CI usa GitHub-hosted runners e autenticação OIDC. Não há client secret,
senha Azure ou credencial Kubernetes persistente no repositório.

## Key Vault

O Key Vault usa RBAC e acesso público habilitado. A exceção `AVD-AZU-0013` é
necessária para que a identity federada do pipeline PostgreSQL grave o segredo
`DATABASE_URL`; ela recebe somente `Key Vault Secrets Officer`. O banco em si
não possui acesso público. Migrar o Vault para Private Endpoint exige runner
conectado à VNet e fica fora do crédito e escopo desta fase.

## Cluster AKS

O cluster habilita Azure CNI Overlay com `network_policy = "azure"`, Azure
Policy, Azure RBAC, OIDC e Workload Identity; as contas locais estão
desabilitadas.

O endpoint do AKS é público, mas autenticado por Entra RBAC, para que
`kubelogin` funcione em GitHub-hosted runners. Como os IPs desses runners são
dinâmicos, a lista de IPs autorizados também não é definida; isso corresponde à
exceção `AVD-AZU-0041`. A exceção `AVD-AZU-0065` só permanece enquanto não
houver runner conectado à VNet. O acesso ao plano de controle é restrito às
identities de deploy e não usa kubeconfig administrativo.

## Exceções temporárias do scanner

- `AVD-AZU-0040`: a instrumentação escolhida é OpenTelemetry/New Relic, prevista
  para a Fase 6. Não há workload nesta fase que justifique também o agente OMS.
- `AVD-AZU-0067`: os discos já usam a criptografia padrão do Azure. Uma chave
  gerenciada pelo cliente exigiria um Disk Encryption Set adicional e fica fora
  do escopo e do orçamento desta entrega.
