provider "aws" {
  region = "us-east-1"
}

# ---------------------------
# Security Groups
# ---------------------------

# SSH access (from home IP)
resource "aws_security_group" "ssh" {
  name        = "ca1-ssh"
  description = "SSH access from home IP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["172.223.186.129/32"] # home public IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Kafka SG (9092 for producers + processor, 2181 for ZooKeeper)
resource "aws_security_group" "kafka" {
  name        = "ca1-kafka"
  description = "Kafka + ZooKeeper"

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Database SG (only processor can reach MongoDB)
resource "aws_security_group" "db" {
  name        = "ca1-db"
  description = "MongoDB access"

  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.processor.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Processor SG (REST endpoint, open to home IP for testing)
resource "aws_security_group" "processor" {
  name        = "ca1-processor"
  description = "REST endpoint"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["172.223.186.129/32"] # allow home IP to hit REST API
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Producer SG
resource "aws_security_group" "producer" {
  name        = "ca1-producer"
  description = "Producer SG"

  #  Producer initiates connections no inbound ports needed
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = []
  }

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
resource "aws_key_pair" "ca1_key" {
  key_name   = "ca1-key"
  public_key = file("~/.ssh/aws_rsa.pub")
}

# ---------------------------
# Instances
# ---------------------------

resource "aws_instance" "kafka_vm" {
  ami                    = "ami-080e1f13689e07408"
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.ca1_key.key_name
  vpc_security_group_ids = [aws_security_group.ssh.id, aws_security_group.kafka.id]

  tags = { Name = "CA1-KafkaZooKeeper" }
}

resource "aws_instance" "db_vm" {
  ami                    = "ami-080e1f13689e07408"
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.ca1_key.key_name
  vpc_security_group_ids = [aws_security_group.ssh.id, aws_security_group.db.id]

  tags = { Name = "CA1-Database" }
}

resource "aws_instance" "processor_vm" {
  ami                    = "ami-080e1f13689e07408"
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.ca1_key.key_name
  vpc_security_group_ids = [aws_security_group.ssh.id, aws_security_group.processor.id]

  tags = { Name = "CA1-Processor" }
}

resource "aws_instance" "producer_vm" {
  ami                    = "ami-080e1f13689e07408"
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.ca1_key.key_name
  vpc_security_group_ids = [aws_security_group.ssh.id, aws_security_group.producer.id]
  
  tags = { Name = "CA1-Producer" }
}

# ---------------------------
# Outputs
# ---------------------------
# output "kafka_public_ip"     { value = aws_instance.kafka_vm.public_ip }
# output "db_public_ip"        { value = aws_instance.db_vm.public_ip }
# output "processor_public_ip" { value = aws_instance.processor_vm.public_ip }
# output "producer_public_ip"  { value = aws_instance.producer_vm.public_ip }

output "kafka_public_ip" {
  value = aws_instance.kafka_vm.public_ip
}

output "kafka_private_ip" {
  value = aws_instance.kafka_vm.private_ip
}

output "db_public_ip" {
  value = aws_instance.db_vm.public_ip
}

output "db_private_ip" {
  value = aws_instance.db_vm.private_ip
}

output "producer_public_ip" {
  value = aws_instance.producer_vm.public_ip
}

output "producer_private_ip" {
  value = aws_instance.producer_vm.private_ip
}

output "processor_public_ip" {
  value = aws_instance.processor_vm.public_ip
}

output "processor_private_ip" {
  value = aws_instance.processor_vm.private_ip
}

