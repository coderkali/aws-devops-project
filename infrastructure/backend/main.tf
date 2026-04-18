resource "aws_s3_bucket" "terraform_state" {
    bucket = "devops-project-tfstate-940278683030"
    force_destroy = true

    tags =  {
        Name = "devops-project-tfstate"
    }
  
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_lock" {
  name         = "devops-project-tfstate-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "devops-project-tfstate-lock"
  }
}