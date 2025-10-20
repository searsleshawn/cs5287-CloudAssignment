#!/bin/bash
set -e

# Destroy cloud
cd ~/cloudAsgn/ansible
make destroy

# Change to terraform directory and destroy vm
cd ~/cloudAsgn/terraform
terraform destroy -auto-approve -input=false
