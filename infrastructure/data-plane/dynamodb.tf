resource "aws_dynamodb_table" "carts" {
  name         = "devops-carts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "customerId"

  attribute {
    name = "customerId"
    type = "S"
  }

  tags = {
    Name = "devops-carts"
  }
}