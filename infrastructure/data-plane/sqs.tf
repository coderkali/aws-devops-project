resource "aws_sqs_queue" "orders" {
  name                      = "devops-orders-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10

  tags = {
    Name = "devops-orders-queue"
  }
}