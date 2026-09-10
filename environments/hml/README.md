# Homologação

Stack Kubernetes de homologação do cluster AKS compartilhado. Cria o namespace
`hml` e, por ser a primeira stack de ambiente, também os namespaces `kong` e
`observability` e o Kong sem rotas de negócio.

Quando `resource_name_suffix` estiver definido, esta stack também encaminha
`POST /auth/cpf` para a Function hml por um Service `ExternalName` HTTPS. O
plugin Kong `auth-cpf-rate-limit` limita a cinco tentativas por minuto por IP.

O backend usa a chave `hml.tfstate` do container de state do AKS. A execução
automática ocorre apenas no push para `development` quando
`TF_APPLY_ENABLED=true` no Environment `hml`.
