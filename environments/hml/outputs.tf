output "namespace" {
  value = module.namespace.namespace
}

output "kong_release_name" {
  value = module.namespace.kong_release_name
}

output "fase4_messaging" {
  value = var.fase4_messaging_enabled ? {
    namespace_fqdn = module.fase4_messaging[0].namespace_fqdn
    client_ids     = module.fase4_messaging[0].workload_client_ids
    principal_ids  = module.fase4_messaging[0].workload_principal_ids
  } : null
}
