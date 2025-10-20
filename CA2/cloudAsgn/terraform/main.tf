# ============================================================
# Terraform - (with Docker Key Provisioning + Swarm Ports)
# ============================================================

# ---------------------------
# Provider Configuration
# ---------------------------
provider "aws" {
  region = "us-east-1"
}

# ---------------------------
# Ensure a Default VPC Exists
# ---------------------------
resource "aws_default_vpc" "default" {}

data "aws_vpc" "default" {
  default     = true
  depends_on  = [aws_default_vpc.default]
}

# ---------------------------
# Security Groups
# ---------------------------

# SSH access
resource "aws_security_group" "ssh" {
  name        = "aws-ssh"
  description = "SSH access from home IP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["172.223.186.129/32"] # home IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Kafka (Manager)
resource "aws_security_group" "kafka" {
  name        = "kafka"
  description = "Kafka + ZooKeeper + Swarm manager"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 9092
    to_port         = 9092
    protocol        = "tcp"
    security_groups = [aws_security_group.processor.id, aws_security_group.producer.id]
  }

  ingress {
    from_port       = 2181
    to_port         = 2181
    protocol        = "tcp"
    security_groups = [aws_security_group.processor.id]
  }

  # --- Added for Docker Swarm Manager communication ---
  ingress {
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 7946
    to_port     = 7946
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 7946
    to_port     = 7946
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # ------------------------------------------------------

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Database Node
resource "aws_security_group" "db" {
  name        = "db"
  description = "MongoDB + Swarm Worker"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.processor.id]
  }

  # --- Added for Swarm Worker communication ---
  ingress {
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 7946
    to_port     = 7946
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 7946
    to_port     = 7946
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # ------------------------------------------------------

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Processor Node
resource "aws_security_group" "processor" {
  name        = "processor"
  description = "Processor + Swarm Worker"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["172.223.186.129/32"]
  }

  # --- Added for Swarm Worker communication ---
  ingress {
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 7946
    to_port     = 7946
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 7946
    to_port     = 7946
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # ------------------------------------------------------

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Producer Node
resource "aws_security_group" "producer" {
  name        = "producer"
  description = "Producer + Swarm Worker"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = []
  }

  # --- Added for Swarm Worker communication ---
  ingress {
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 7946
    to_port     = 7946
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 7946
    to_port     = 7946
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # ------------------------------------------------------

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------
# Key Pair
# ---------------------------
resource "aws_key_pair" "iam_key" {
  key_name   = "iam-key"
  public_key = file("~/.ssh/aws_rsa.pub")
}

# ============================================================
# EC2 Instances + Docker Credential Provisioning
# ============================================================
locals {
  docker_provisioner = [
    {
      source      = "~/.docker/config.json"
      destination = "/home/ubuntu/config.json"
    }
  ]
}

locals {
  ssh_connection = {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/aws_rsa")
  }
}

# Kafka Node
resource "aws_instance" "kafka_vm" {
  ami                    = "ami-080e1f13689e07408"
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.iam_key.key_name
  vpc_security_group_ids = [aws_security_group.ssh.id, aws_security_group.kafka.id]
  tags                   = { Name = "KafkaZooKeeper" }

  provisioner "file" {
    source      = "~/.docker/config.json"
    destination = "/home/ubuntu/config.json"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/aws_rsa")
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /home/ubuntu/.docker",
      "sudo mv /home/ubuntu/config.json /home/ubuntu/.docker/config.json",
      "sudo chown ubuntu:ubuntu /home/ubuntu/.docker/config.json",
      "sudo chmod 600 /home/ubuntu/.docker/config.json"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/aws_rsa")
      host        = self.public_ip
    }
  }
}

# Database Node
resource "aws_instance" "db_vm" {
  ami                    = "ami-080e1f13689e07408"
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.iam_key.key_name
  vpc_security_group_ids = [aws_security_group.ssh.id, aws_security_group.db.id]
  tags                   = { Name = "Database" }

  provisioner "file" {
    source      = "~/.docker/config.json"
    destination = "/home/ubuntu/config.json"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/aws_rsa")
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /home/ubuntu/.docker",
      "sudo mv /home/ubuntu/config.json /home/ubuntu/.docker/config.json",
      "sudo chown ubuntu:ubuntu /home/ubuntu/.docker/config.json",
      "sudo chmod 600 /home/ubuntu/.docker/config.json"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/aws_rsa")
      host        = self.public_ip
    }
  }
}

# Processor Node
resource "aws_instance" "processor_vm" {
  ami                    = "ami-080e1f13689e07408"
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.iam_key.key_name
  vpc_security_group_ids = [aws_security_group.ssh.id, aws_security_group.processor.id]
  tags                   = { Name = "Processor" }

  provisioner "file" {
    source      = "~/.docker/config.json"
    destination = "/home/ubuntu/config.json"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/aws_rsa")
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /home/ubuntu/.docker",
      "sudo mv /home/ubuntu/config.json /home/ubuntu/.docker/config.json",
      "sudo chown ubuntu:ubuntu /home/ubuntu/.docker/config.json",
      "sudo chmod 600 /home/ubuntu/.docker/config.json"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/aws_rsa")
      host        = self.public_ip
    }
  }
}

# Producer Node
resource "aws_instance" "producer_vm" {
  ami                    = "ami-080e1f13689e07408"
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.iam_key.key_name
  vpc_security_group_ids = [aws_security_group.ssh.id, aws_security_group.producer.id]
  tags                   = { Name = "Producer" }

  provisioner "file" {
    source      = "~/.docker/config.json"
    destination = "/home/ubuntu/config.json"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/aws_rsa")
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /home/ubuntu/.docker",
      "sudo mv /home/ubuntu/config.json /home/ubuntu/.docker/config.json",
      "sudo chown ubuntu:ubuntu /home/ubuntu/.docker/config.json",
      "sudo chmod 600 /home/ubuntu/.docker/config.json"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/aws_rsa")
      host        = self.public_ip
    }
  }
}
