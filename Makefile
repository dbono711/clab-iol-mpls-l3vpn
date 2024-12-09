CLAB = clab-iol-mpls-l3vpn
LOG_FILE = setup.log
VENV_DIR = .venv
REQ_FILE = requirements.txt
ANSIBLE_HOSTS = clab-iol-mpls-l3vpn/ansible-inventory.yml
ANSIBLE_PLAYBOOK = ansible/config.yaml
CLIENTS = client1 client2

define log
    echo "[$(shell date '+%Y-%m-%d %H:%M:%S')] $1" >> $(LOG_FILE)
endef

define client_setup
	for CLIENT in $(CLIENTS); do \
		docker cp clients/$$CLIENT.sh $(CLAB)-$$CLIENT:/tmp/; \
		docker exec $(CLAB)-$$CLIENT bash /tmp/$$CLIENT.sh 2>/dev/null; \
	done
endef

.PHONY: initialize-log
initialize-log:
	@echo -n "" > $(LOG_FILE)

.PHONY: initialize-virtual-environment
initialize-virtual-environment: initialize-log
	@if [ ! -d $(VENV_DIR) ]; then \
		$(call log,Creating virtual environment...); \
		python3 -m venv $(VENV_DIR) >> $(LOG_FILE) 2>&1; \
		$(call log,Installing requirements in virtual environment...); \
		$(VENV_DIR)/bin/pip install -r $(REQ_FILE) >> $(LOG_FILE) 2>&1; \
	else \
		$(call log,Virtual environment already exists.); \
	fi

.PHONY: lab
lab: initialize-virtual-environment
	@$(call log,Deploying ContainerLAB topology...)
	@sudo clab deploy --topo setup.yml >> $(LOG_FILE) 2>&1
	@sleep 5
	@$(call log,ContainerLAB topology successfully deployed.)

.PHONY: configure
configure: lab
	@$(call log,Starting configuration...)
	@$(call log,Running ansible playbook for cRPD configuration...)
	@$(VENV_DIR)/bin/ansible-playbook -i $(ANSIBLE_HOSTS) $(ANSIBLE_PLAYBOOK) >> $(LOG_FILE) 2>&1
	@$(call log,Running shell scripts for client configuration...)
	@$(call client_setup) >> $(LOG_FILE) 2>&1
	@echo "Configuration complete. Check 'setup.log' for detailed output."

all: configure

.PHONY: configure-only
configure-only: initialize-log
	@$(call log,Starting configuration...)
	@$(call log,Running ansible playbook for cRPD configuration...)
	@$(VENV_DIR)/bin/ansible-playbook -i $(ANSIBLE_HOSTS) $(ANSIBLE_PLAYBOOK) >> $(LOG_FILE) 2>&1
	@$(call log,Running shell scripts for client configuration...)
	@$(call client_setup) >> $(LOG_FILE) 2>&1
	@echo "Configuration complete. Check 'setup.log' for detailed output."

.PHONY: clean
clean: initialize-log
	@$(call log,Cleaning up...)
	@sudo clab destroy --topo setup.yml >> $(LOG_FILE) 2>&1
	@rm -rf $(VENV_DIR) >> $(LOG_FILE) 2>&1
	@$(call log,Cleaning complete.)
	@echo "Cleaning complete. Check 'setup.log' for detailed output."
