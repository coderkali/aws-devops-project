output "ec2_public_ip" {
    description = "Public IP of the Docker EC2 instances"
    value =  aws_instance.docker_ec2.public_ip
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh -i ~/Documents/devops-key.pem ec2-user@${aws_instance.docker_ec2.public_ip}"
}

