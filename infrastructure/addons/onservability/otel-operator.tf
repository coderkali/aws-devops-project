# Phase 8: OpenTelemetry Operator and Collector

resource "helm_repository" "otel" {
  name   = "open-telemetry"
  url    = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  type   = "helm"
}

resource "helm_release" "otel_operator" {
  namespace        = "opentelemetry"
  create_namespace = true

  name       = "opentelemetry-operator"
  repository = "otel"
  chart      = "opentelemetry-operator"
  version    = "0.52.0"

  values = [
    yamlencode({
      manager = {
        collectorImage = {
          repository = "otel/opentelemetry-collector-k8s"
          tag        = "0.88.0"
        }
      }
    })
  ]

  wait    = true
  timeout = 300
}

output "otel_operator_namespace" {
  description = "Namespace where OTEL Operator is installed"
  value       = helm_release.otel_operator.namespace
}