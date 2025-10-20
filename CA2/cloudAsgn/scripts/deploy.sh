#!/bin/bash
set -e  # exit immediately if a command fails

# Step 1: Terraform init/plan/apply
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply -auto-approve tfplan

# Step 2: Export outputs to JSON
terraform output -json > ../ansible/tf_outputs.json
cd ..

# Step 3: Build Ansible inventory from outputs
cd ansible
jq -r '
   "[kafka]\n\(.kafka_dns.value)\n\n
    [db]\n\(.db_dns.value)\n\n
    [processor]\n\(.processor_dns.value)\n\n
    [producer]\n\(.producer_dns.value)\n\n
    [all:vars]\nansible_user=ubuntu\nansible_ssh_private_key_file=~/.ssh/aws_rsa\n"
' tf_outputs.json > inventory.ini

# Step 4: Run Ansible playbook
make deploy
