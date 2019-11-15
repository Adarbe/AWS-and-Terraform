

###############################################
###Variables
###############################################

variable "AWS_ACCESS_KEY_ID" {}
variable "AWS_SECRET_ACCESS_KEY" {}
variable "region" {
  default = "us-east-1d"
}
variable "instance_count" {
  default = 2
}

##############################################
###Provider
##############################################
provider "aws" {
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
  region = "us-east-1"
}
##############################################
###Data
##############################################
data "aws_ami" "ubuntu-18_04" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

################################################
###Resourses
################################################

resource "aws_security_group" "allow_ssh" {
  name = "nginx_demo"
  description = "allow ports from nginx_demo"

  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "terraform_nginx" {
  #description = "create 2 EC2 machines and install nginx"
  count = 2
  ami = "ami-024582e76075564db"
  instance_type = "t2.medium"
  key_name = "nginx"
  tags = {
    Name = "ngnix ${count.index}"
  }
  user_data = <<-EOF
              #! /bin/bash
              sudo apt-get update
              sudo apt-get install -y nginx
              sudo chmod +777 /var/www/html/
              sudo service nginx start
              sed -i 's/Welcome to nginx/ OpsSchool Rules!/g' /var/www/html/index.nginx-debian.html
              sudo service nginx restart

              EOF

  ebs_block_device {
    device_name = "/dev/sdg"
    volume_size = "10"
    volume_type = "gp2"
    encrypted = true
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id]


}

################################################
###OUTPUT
################################################
output "aws_insatnce_public_dns" {
  value = "aws_instance.ngnix.public_dns"
}