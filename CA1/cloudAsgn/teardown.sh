#!/bin/bash
set -e

# Change to terraform directory and destroy vm
cd ~/cloudAsgn/terraform
terraform destroy -auto-approve -input=false
