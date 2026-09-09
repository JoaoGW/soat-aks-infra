# Homologação

Stack Kubernetes de homologação do cluster AKS compartilhado. Cria o namespace
`hml` e, por ser a primeira stack de ambiente, também os namespaces `kong` e
`observability` e o Kong sem rotas de negócio.

O backend usa a chave `hml.tfstate` do container de state do AKS. A execução
automática ocorre apenas no push para `development` quando
`TF_APPLY_ENABLED=true` no Environment `hml`.
