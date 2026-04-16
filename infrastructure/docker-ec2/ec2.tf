data "aws_ami" "amazon_linux_2023" {
    most_recent = true
    owners = ["amazon"]

    filter {
      name = "name"
      values = ["al2023-ami-*-x86_64"]
    } 
}

resource "aws_instance" "docker_ec2" {
    ami = data.aws_ami.amazon_linux_2023.id
    instance_type = var.instance_type
    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.docker_ec2_sg.id]
    
    tags = {
        Name = "docker-demo"
    }
}