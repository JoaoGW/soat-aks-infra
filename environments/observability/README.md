# Observabilidade compartilhada

Esta stack instala o coletor `nr-k8s-otel-collector` no namespace `observability`. A chave New Relic deve existir somente como `new-relic-license-key` no Key Vault; o CSI a sincroniza em tempo de execução para o chart, sem versionamento em Git ou state Terraform.

Execute apenas pelo workflow manual **Observabilidade AKS**, após criar o environment `observability`, configurar as variáveis OIDC não sigilosas e manter `TF_APPLY_ENABLED=false` até aprovação de custo. O apply exige a trava em `true` e nunca deve ser executado antes da foundation e da chave existirem.

O chart coleta recursos e eventos Kubernetes. Logs de containers ficam desabilitados, pois API e Function usam OTLP diretamente, evitando duplicidade e exposição de dados.
