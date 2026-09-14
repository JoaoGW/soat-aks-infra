output "namespace" {
  value = kubernetes_namespace_v1.application.metadata[0].name
}

output "kong_release_name" {
  value = try(helm_release.kong[0].name, null)
}
