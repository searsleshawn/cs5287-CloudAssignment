# ============================================================
# CA3 Makefile - Deployment, Validation, and Cleanup
# ============================================================

SSH_KEY = ~/.ssh/aws_rsa
INVENTORY = inventory.ini
DOCKERHUB_USERNAME = searsleshawn

ANSIBLE_FLAGS = -i $(INVENTORY) -e "dockerhub_username=$(DOCKERHUB_USERNAME)"

# --- Main commands ---

## Deploy full environment (Swarm + IoT + Observability)
deploy:
	@echo "=== Running Infrastructure Provisioning (site.yml) ==="
	@ansible-playbook $(ANSIBLE_FLAGS) site.yml || (make cleanup && false)
	@echo "=== Running Declarative Stack Deployment (declaratives.yml) ==="
	@ansible-playbook $(ANSIBLE_FLAGS) declaratives.yml --ask-vault-pass || (make cleanup && false)
	@echo "=== Running Observability Stack Deployment (observability.yml) ==="
	@ansible-playbook $(ANSIBLE_FLAGS) observability.yml --ask-vault-pass || (make cleanup && false)
	@echo "✅ All stacks deployed successfully!"

## Deploy only Swarm
swarm:
	@echo "=== Running Infrastructure Provisioning (site.yml) ==="
	@ansible-playbook $(ANSIBLE_FLAGS) site.yml

## Deploy only IoT stack
declaratives:
	@echo "=== Running Declarative Stack Deployment (declaratives.yml) ==="
	@ansible-playbook $(ANSIBLE_FLAGS) declaratives.yml --ask-vault-pass || (make cleanup && false)

## Deploy only Observability stack
obs:
	@echo "=== Running Observability Stack Deployment (observability.yml) ==="
	@ansible-playbook $(ANSIBLE_FLAGS) observability.yml --ask-vault-pass || (make cleanup && false)

## Full teardown
destroy:
	@echo "=== Running Swarm stack teardown (destroy.yml) ==="
	@ansible-playbook $(ANSIBLE_FLAGS) destroy.yml
	@echo "🗑️  Teardown complete."

## Help menu
help:
	@echo ""
	@echo "CA3 Project Makefile"
	@echo "--------------------"
	@echo "make deploy       -> Full deployment (site.yml + declaratives.yml + observability.yml)"
	@echo "make declaratives -> Deploy only IoT stack (with auto-cleanup)"
	@echo "make obs          -> Deploy only Observability stack (with auto-cleanup)"
	@echo "make clean        -> Remove iot_stack and obs_stack (keep swarm)"
	@echo "make destroy      -> Remove entire swarm environment"
	@echo ""
