# Produção

Stack Kubernetes de produção do cluster AKS compartilhado. Cria somente o
namespace `prod`; Kong é um componente compartilhado e permanece sob a stack
de homologação.

O backend usa a chave `prod.tfstate` do container de state do AKS. A execução
automática ocorre apenas no push para `main` quando `TF_APPLY_ENABLED=true` no
Environment `prod`.
