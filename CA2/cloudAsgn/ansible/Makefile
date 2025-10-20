# ============================================================
# CA2 Makefile - Validation & Teardown
# ============================================================

# Inventory and variables
INVENTORY = inventory.ini
DOCKERHUB_USERNAME = searsleshawn

# Default Ansible flags (include Docker Hub username)
ANSIBLE_FLAGS = -i $(INVENTORY) -e "dockerhub_username=$(DOCKERHUB_USERNAME)"

# === Commands ===

## Deploy full stack (Provision + Declarative)
deploy:
	@echo "=== Running Infrastructure Provisioning (site.yml) ==="
	ansible-playbook $(ANSIBLE_FLAGS) site.yml
	@echo "=== Running Declarative Stack Deployment (declaratives.yml) ==="
	ansible-playbook $(ANSIBLE_FLAGS) declaratives.yml --ask-vault-pass

## Remove stack (Teardown)
destroy:
	@echo "=== Running Swarm stack teardown on Kafka VM ==="
	ansible-playbook $(ANSIBLE_FLAGS) destroy.yml
	@echo "=== Teardown complete. ==="

## Help menu
help:
	@echo ""
	@echo "CA2 Project Makefile"
	@echo "--------------------"
	@echo "make deploy     -> Run full deployment (site.yml + declaratives.yml)"
	@echo "make destroy    -> Remove Swarm stack (teardown)"
	@echo ""
