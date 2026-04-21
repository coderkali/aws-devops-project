#!/bin/bash
set -e

BASE_DIR=~/Documents/aws-devops-project/aws-devops-project
K8S_DIR=$BASE_DIR/kubernetes/foundation
INFRA_DIR=$BASE_DIR/infrastructure

format_time() {
  local seconds=$1
  local mins=$((seconds / 60))
  local secs=$((seconds % 60))
  echo "${mins}m ${secs}s"
}

up() {
  TOTAL_START=$SECONDS

  echo "==> [1/6] Applying VPC"
  STEP_START=$SECONDS
  cd $INFRA_DIR/vpc && terraform apply -auto-approve
  echo "    VPC done in $(format_time $((SECONDS - STEP_START)))"

  echo "==> [2/6] Applying EKS"
  STEP_START=$SECONDS
  cd $INFRA_DIR/eks && terraform apply -auto-approve
  echo "    EKS done in $(format_time $((SECONDS - STEP_START)))"

  echo "==> [3/6] Configuring kubectl"
  STEP_START=$SECONDS
  aws eks update-kubeconfig --region us-east-1 --name devops-eks-cluster
  echo "    kubectl configured in $(format_time $((SECONDS - STEP_START)))"

  echo "==> [4/6] Applying Addons"
  STEP_START=$SECONDS
  cd $INFRA_DIR/addons && terraform apply -auto-approve
  echo "    Addons done in $(format_time $((SECONDS - STEP_START)))"

  echo "==> [5/6] Applying Kubernetes resources"
  STEP_START=$SECONDS
  kubectl apply -f $K8S_DIR
  echo "    Kubernetes resources done in $(format_time $((SECONDS - STEP_START)))"

  # ... existing steps ...

  echo "==> [5/6] Applying Data Plane"
  STEP_START=$SECONDS
  cd $INFRA_DIR/data-plane && terraform init && terraform apply -auto-approve
  echo "    Data plane done in $(format_time $((SECONDS - STEP_START)))"

  echo ""
  echo "================================"
  echo " Cluster ready in $(format_time $((SECONDS - TOTAL_START)))"
  echo "================================"
}

down() {
  TOTAL_START=$SECONDS

  echo "==> [1/4] Deleting Kubernetes resources"
  STEP_START=$SECONDS
  kubectl delete -f $K8S_DIR
  echo "    Kubernetes resources deleted in $(format_time $((SECONDS - STEP_START)))"

  echo "==> [2/5] Destroying Data Plane"
  STEP_START=$SECONDS
  cd $INFRA_DIR/data-plane && terraform destroy -auto-approve
  echo "    Data plane destroyed in $(format_time $((SECONDS - STEP_START)))"

  echo "==> [3/5] Destroying Addons"
  STEP_START=$SECONDS
  cd $INFRA_DIR/addons && terraform destroy -auto-approve
  echo "    Addons destroyed in $(format_time $((SECONDS - STEP_START)))"

  echo "==> [4/5] Destroying EKS"
  STEP_START=$SECONDS
  cd $INFRA_DIR/eks && terraform destroy -auto-approve
  echo "    EKS destroyed in $(format_time $((SECONDS - STEP_START)))"

  echo "==> [5/5] Destroying VPC"
  STEP_START=$SECONDS
  cd $INFRA_DIR/vpc && terraform destroy -auto-approve
  echo "    VPC destroyed in $(format_time $((SECONDS - STEP_START)))"

  echo ""
  echo "================================"
  echo " All resources destroyed in $(format_time $((SECONDS - TOTAL_START)))"
  echo "================================"
}

status() {
  echo "==> Checking cluster status"
  echo ""
  echo "--- Nodes ---"
  kubectl get nodes
  echo ""
  echo "--- Pods ---"
  kubectl get pods -n devops-app
  echo ""
  echo "--- Ingress ---"
  kubectl get ingress -n devops-app
  echo ""
  ALB_URL=$(kubectl get ingress -n devops-app -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
  echo "--- App Health Check ---"
  curl -s --max-time 5 http://$ALB_URL > /dev/null && echo "App is UP → http://$ALB_URL" || echo "App is not responding yet"
}

case $1 in
  up)   up ;;
  down) down ;;
  status) status ;;
  *)    echo "Usage: ./manage-infra.sh [up|down|status]" ;;
esac