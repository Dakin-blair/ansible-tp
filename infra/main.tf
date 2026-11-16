terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

# Image Debian 12 (utilisateur par défaut : admin)
data "aws_ami" "debian" {
  most_recent = true
  owners = ["136693071363"]
  filter {
    name = "name"
    values = ["debian-12-amd64-*"]
  }
}

# Clé SSH
resource "aws_key_pair" "tp" {
  key_name = "ansible-tp"
  public_key = file("~/.ssh/ansible-tp.pub")
}

# Pare-feu : SSH ouvert
resource "aws_security_group" "tp" {
  name = "ansible-tp-sg"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Machine Ansible (nœud de contrôle)
resource "aws_instance" "ansible" {
  ami = data.aws_ami.debian.id
  instance_type = "t3.micro"
  key_name = aws_key_pair.tp.key_name
  vpc_security_group_ids = [aws_security_group.tp.id]
  user_data = "#!/bin/bash\napt-get update -y\napt-get install -y ansible"
  tags = {
    Name = "ansible"
  }
}

# Client 1
resource "aws_instance" "client1" {
  ami = data.aws_ami.debian.id
  instance_type = "t3.micro"
  key_name = aws_key_pair.tp.key_name
  vpc_security_group_ids = [aws_security_group.tp.id]
  tags = {
    Name = "client1"
  }
}

# Adresses IP
output "ansible_public_ip" {
  value = aws_instance.ansible.public_ip
}

output "client1_private_ip" {
  value = aws_instance.client1.private_ip
}


# Client 2
resource "aws_instance" "client2" {
  ami = data.aws_ami.debian.id
  instance_type = "t3.micro"
  key_name = aws_key_pair.tp.key_name
  vpc_security_group_ids = [aws_security_group.tp.id]
  tags = {
    Name = "client2"
  }
}

output "client2_private_ip" {
  value = aws_instance.client2.private_ip
}
