#!/bin/bash
set -e  # exit immediately if a command fails

# Step 1: Terraform init/plan/apply
cd terraform
terraform plan -out=tfplan
terraform apply -auto-approve tfplan

# Step 2: Export outputs to JSON
terraform output -json > ../ansible/tf_outputs.json
cd ..

# Step 3: Build Ansible inventory from outputs
cd ansible
jq -r '
  "[kafka]\n\(.kafka_public_ip.value) private_ip=\(.kafka_private_ip.value)\n\n
   [db]\n\(.db_public_ip.value) private_ip=\(.db_private_ip.value)\n\n
   [processor]\n\(.processor_public_ip.value) private_ip=\(.processor_private_ip.value)\n\n
   [producer]\n\(.producer_public_ip.value) private_ip=\(.producer_private_ip.value)\n\n
   [all:vars]\nansible_user=ubuntu\nansible_ssh_private_key_file=~/.ssh/aws_rsa\n"
' tf_outputs.json > inventory.ini


# Step 4: Run Ansible playbook
ansible-playbook -i inventory.ini site.yml
