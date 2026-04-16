variable "aws_region" {
    description = "AWS region"
    type = string
    default = "us-east-1"
}

variable "instance_type" {
    description = "EC2 instance type"
    type = string
    default = "t3.medium"
}

variable "key_name" {
    description = "EC2 key pair name"
    type = string
    default = "devops-key"
}




