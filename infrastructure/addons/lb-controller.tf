resource "kubernetes_service_account" "lb_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.lb_controller.arn
    }
  }
}

resource "helm_release" "lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  values = [
    yamlencode({
      clusterName = data.terraform_remote_state.eks.outputs.cluster_name
      serviceAccount = {
        create = false
        name   = "aws-load-balancer-controller"
      }
      region = var.aws_region
      vpcId  = data.terraform_remote_state.vpc.outputs.vpc_id
    })
  ]
}