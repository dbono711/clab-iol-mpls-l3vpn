CLAB = clab-iol-mpls-l3vpn
LOG_FILE = setup.log
VENV_DIR = .venv
REQ_FILE = requirements.txt

define log
    echo "[$(shell date '+%Y-%m-%d %H:%M:%S')] $1" >> $(LOG_FILE)
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

.PHONY: clean
clean: initialize-log
	@$(call log,Cleaning up...)
	@sudo clab destroy --topo setup.yml >> $(LOG_FILE) 2>&1
	@rm -rf $(VENV_DIR) >> $(LOG_FILE) 2>&1
	@$(call log,Cleaning complete.)
	@echo "Cleaning complete. Check 'setup.log' for detailed output."
