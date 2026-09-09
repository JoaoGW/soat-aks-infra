# Exceções de segurança da infraestrutura AKS

O CI usa GitHub-hosted runners e autenticação OIDC. Não há client secret,
senha Azure ou credencial Kubernetes persistente no repositório.

## Key Vault

O Key Vault usa RBAC e acesso público habilitado. A exceção `AVD-AZU-0013` é
necessária para que a identity federada do pipeline PostgreSQL grave o segredo
`DATABASE_URL`; ela recebe somente `Key Vault Secrets Officer`. O banco em si
não possui acesso público. Migrar o Vault para Private Endpoint exige runner
conectado à VNet e fica fora do crédito e escopo desta fase.

## API do AKS

O endpoint do AKS é público, mas Azure RBAC e OIDC estão habilitados e as
contas locais estão desabilitadas. A exceção `AVD-AZU-0041` permite que
`kubelogin` funcione em GitHub-hosted runners. O acesso ao plano de controle é
restrito às identities de deploy e não usa kubeconfig administrativo. Uma API
privada exigiria um runner dentro da VNet.
