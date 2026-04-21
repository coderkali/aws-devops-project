#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TF_DIR="$REPO_ROOT/infrastructure/data-plane"
HELM_DIR="$REPO_ROOT/helm"

# macOS requires an explicit backup extension argument for -i; Linux does not
if [[ "$(uname)" == "Darwin" ]]; then
  SED_INPLACE=(-i '')
else
  SED_INPLACE=(-i)
fi

echo "Reading Terraform outputs from $TF_DIR..."
cd "$TF_DIR"

MYSQL_ENDPOINT=$(terraform output -raw mysql_endpoint)
MYSQL_HOST="${MYSQL_ENDPOINT%:*}"

POSTGRES_ENDPOINT=$(terraform output -raw postgres_endpoint)
POSTGRES_HOST="${POSTGRES_ENDPOINT%:*}"

REDIS_ENDPOINT=$(terraform output -raw redis_endpoint)

SQS_QUEUE_URL=$(terraform output -raw sqs_queue_url)

DYNAMODB_TABLE_NAME=$(terraform output -raw dynamodb_table_name)

echo "  mysql_host:        $MYSQL_HOST"
echo "  postgres_host:     $POSTGRES_HOST"
echo "  redis_endpoint:    $REDIS_ENDPOINT"
echo "  sqs_queue_url:     $SQS_QUEUE_URL"
echo "  dynamodb_table:    $DYNAMODB_TABLE_NAME"

# catalog-service: db.host = MySQL endpoint (no port)
echo "Updating catalog-service/values.yaml..."
sed "${SED_INPLACE[@]}" \
  "s|  host: .*|  host: \"$MYSQL_HOST\"|" \
  "$HELM_DIR/catalog-service/values.yaml"

# orders-service: db.host = PostgreSQL endpoint (no port), messaging.queueUrl = SQS URL
echo "Updating orders-service/values.yaml..."
sed "${SED_INPLACE[@]}" \
  "s|  host: .*|  host: \"$POSTGRES_HOST\"|" \
  "$HELM_DIR/orders-service/values.yaml"
sed "${SED_INPLACE[@]}" \
  "s|  queueUrl: .*|  queueUrl: \"$SQS_QUEUE_URL\"|" \
  "$HELM_DIR/orders-service/values.yaml"

# checkout-service: redis.host = Redis endpoint, messaging.queueUrl = SQS URL
echo "Updating checkout-service/values.yaml..."
sed "${SED_INPLACE[@]}" \
  "s|  host: .*|  host: \"$REDIS_ENDPOINT\"|" \
  "$HELM_DIR/checkout-service/values.yaml"
sed "${SED_INPLACE[@]}" \
  "s|  queueUrl: .*|  queueUrl: \"$SQS_QUEUE_URL\"|" \
  "$HELM_DIR/checkout-service/values.yaml"

# cart-service: dynamodb.tableName = DynamoDB table name
echo "Updating cart-service/values.yaml..."
sed "${SED_INPLACE[@]}" \
  "s|  tableName: .*|  tableName: \"$DYNAMODB_TABLE_NAME\"|" \
  "$HELM_DIR/cart-service/values.yaml"

echo "Done. Helm values updated."
