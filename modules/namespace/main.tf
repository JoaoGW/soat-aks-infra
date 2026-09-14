resource "kubernetes_namespace_v1" "application" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/part-of" = "soat"
      "soat.io/environment"       = var.namespace
    }
  }
}

resource "kubernetes_namespace_v1" "kong" {
  count = var.create_shared_namespaces ? 1 : 0

  metadata {
    name = "kong"
    labels = {
      "app.kubernetes.io/part-of" = "soat"
    }
  }
}

resource "kubernetes_namespace_v1" "observability" {
  count = var.create_shared_namespaces ? 1 : 0

  metadata {
    name = "observability"
    labels = {
      "app.kubernetes.io/part-of" = "soat"
    }
  }
}

resource "helm_release" "kong" {
  count = var.install_kong ? 1 : 0

  name             = "kong"
  repository       = "https://charts.konghq.com"
  chart            = "kong"
  version          = var.kong_chart_version
  namespace        = kubernetes_namespace_v1.kong[0].metadata[0].name
  create_namespace = false
  wait             = true
  timeout          = 600

  set {
    name  = "proxy.type"
    value = "LoadBalancer"
  }

  set {
    name  = "admin.enabled"
    value = "false"
  }

  set {
    name  = "ingressController.enabled"
    value = "true"
  }
}
