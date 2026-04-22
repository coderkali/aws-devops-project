# Phase 7: Metrics Server for HPA
# Required for HPA to read CPU/memory metrics

resource "helm_repository" "metrics_server" {
  name   = "metrics-server"
  url    = "https://kubernetes-sigs.github.io/metrics-server/"
  type   = "helm"
}

resource "helm_release" "metrics_server" {
  namespace        = "kube-system"
  create_namespace = false

  name       = "metrics-server"
  repository = "metrics-server"
  chart      = "metrics-server"
  version    = "3.12.0"

  values = [
    yamlencode({
      args = [
        "--kubelet-insecure-tls",
        "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname"
      ]
    })
  ]

  wait    = true
  timeout = 300
}

output "metrics_server_namespace" {
  description = "Namespace where Metrics Server is installed"
  value       = helm_release.metrics_server.namespace
}