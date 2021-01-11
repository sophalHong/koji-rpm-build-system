# Bash is required as the shell
SHELL := /usr/bin/env bash

# Set Makefile directory in variable for referencing other files
MFILECWD = $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
BUILDER_CACHE_FILE ?= $(MFILECWD)data/.BUILDER_COUNT.cache
VAGRANT_VAGRANTFILE ?= $(MFILECWD)vagrantfiles/Vagrantfile
SCRIPT_FILE ?= $(MFILECWD)scripts/default.sh
SCRIPT_USER ?= vagrant
SCRIPT_ARGS ?=

VAGRANT ?= vagrant
VAGRANT_LOG ?=

# sed 1-liner to reverse the lines in an input stream
REVERSE_LINES=sed -e '1!G;h;$$!d'

# === BEGIN USER OPTIONS ===
# Vagrant Provider
VAGRANT_DEFAULT_PROVIDER ?= virtualbox
# Disk setup
DISK_COUNT ?=
DISK_SIZE_GB ?=
# VM Resources
SERVER_CPUS ?= 2
SERVER_MEMORY_SIZE_GB ?= 2
BUILDER_CPUS ?= 1
BUILDER_MEMORY_SIZE_GB ?= 2
ifeq (,$(wildcard $(BUILDER_CACHE_FILE)))
BUILDER_COUNT ?= 1
else
BUILDER_COUNT ?= `cat $(BUILDER_CACHE_FILE)`
endif
# Libvirt
LIBVIRT_STORAGE_POOL ?=
# Network
## Private Network (Server ip = PRIVATE_IP, Builder ip = PRIVATE_IP++)
## Public Network (PUBLIC_NW_NIC=eno1) | Not set = using private network
PRIVATE_IP ?= 192.168.83.10
PUBLIC_NW_NIC ?=
PUBLIC_IP ?=
FWD_PORT ?= 8080
## Add new builder
MY_IP ?=
BUILDER_NAME ?= my-builder
# Public NFS server
NFS_MOUNTPATH ?=
# User post install script path
USER_POST_INSTALL_SCRIPT_PATH ?=
# === END USER OPTIONS ===

vagrant-plugins-require:
	@if [ "$(VAGRANT_DEFAULT_PROVIDER)" = "libvirt" ]; then \
		$(MAKE) vagrant-plugins-libvirt; \
	fi

vagrant-plugins-libvirt: ## Checks that vagrant-libvirt plugin is installed, if not try to install it
	@if ! $(VAGRANT) plugin list | grep -q vagrant-libvirt; then \
		echo "vagrant-plugins: vagrant-libvirt is not installed, will try to install ..."; \
		$(VAGRANT) plugin install vagrant-libvirt || { echo "vagrant-plugins: failed to install vagrant-libvirt plugin."; exit 1; }; \
		echo "vagrant-plugins: vagrant-libvirt plugin has been installed."; \
	else \
		echo "vagrant-plugins: vagrant-libvirt is already installed."; \
	fi

show-env-config: ## Show all Environment values configuration used to create VMs.
	@echo "==== Environment Info ===="
	@echo "VAGRANT_DEFAULT_PROVIDER = '$(VAGRANT_DEFAULT_PROVIDER)' - Default vagrant provider"
	@echo "VAGRANT_VAGRANTFILE      = '$(VAGRANT_VAGRANTFILE)' - Vagrantfile"
	@echo "-------- Server --------"
	@echo "SERVER_COUNT             = '1' - Number of Kojihub server host (always one)"
	@echo "SERVER_CPUS              = '$(SERVER_CPUS)'"
	@echo "SERVER_MEMORY_SIZE_GB    = '$(SERVER_MEMORY_SIZE_GB)' (GB)"
	@echo "------------------------"
	@echo "******* Builder ********"
	@echo "BUILDER_COUNT            = '$(BUILDER_COUNT)' - Number of Kojid builder host"
	@echo "BUILDER_CPUS             = '$(BUILDER_CPUS)'"
	@echo "BUILDER_MEMORY_SIZE_GB   = '$(BUILDER_MEMORY_SIZE_GB)' (GB)"
	@echo "************************"
	@echo "DISK_COUNT               = '$(DISK_COUNT)' - Number of extra disk"
	@echo "DISK_SIZE_GB             = '$(DISK_SIZE_GB)' - Size of extra disk in GB"
	@echo "FWD_PORT                 = '$(FWD_PORT)' - Forwarding Port"
	@echo "PRIVATE_IP               = '$(PRIVATE_IP)'"
	@echo "PUBLIC_IP                = '$(PUBLIC_IP)' - [empty = DHCP]"
	@echo "PUBLIC_NW_NIC            = '$(PUBLIC_NW_NIC)' - Network Device [eno1] (empty=use private network)"
	@echo "[Server IP = PRIVATE_IP, Builder IP = PRIVATE_IP++]"
	@echo "NFS_MOUNTPATH            = '$(NFS_MOUNTPATH)' - Public NFS server mountpath 'IP:/path/to/dir'"
	@echo "=========================="

versions: ## Print the "imporant" tools versions out for easier debugging.
	@echo "=== BEGIN Version Info ==="
	@echo "Repo state: $$(git rev-parse --verify HEAD) (dirty? $$(if git diff --quiet; then echo 'NO'; else echo 'YES'; fi))"
	-@echo "make: $$(command -v make)"
	-@echo "Vagrant version: $$($(VAGRANT) --version)"
	@echo "=== Vagrant Plugins ==="
	-@$(VAGRANT) plugin list
	@echo "=== Vagrant Plugins ==="
	-@echo "vboxmanage version: $$(vboxmanage --version)"
	-@echo "libvirtd version: $$(libvirtd --version)"
	@echo "=== END Version Info ==="

up: vagrant-plugins-require start ## Start Koji Vagrant multi-node cluster. starts and bootsup the server and builder VMs.

start:
ifeq ($(PARALLEL_VM_START),true)
	@$(MAKE) start-server start-builders --no-print-directory
else
	@$(MAKE) start-server --no-print-directory
	@$(MAKE) start-builders --no-print-directory
endif

start-server: ## Start up server VM (automatically done by `up` target).
	$(VAGRANT) up --provider $(VAGRANT_DEFAULT_PROVIDER)

start-builder-%: ## Start builder VM, where `%` is the number of the builder.
	BUILDER=$* $(VAGRANT) up --provider $(VAGRANT_DEFAULT_PROVIDER)

start-builders: $(shell for (( i=1; i<=$(BUILDER_COUNT); i+=1 )); do echo "start-builder-$$i"; done) ## Create and start all builder VMs by utilizing the `builder-X` target (automatically done by `up` target).
	@echo $(BUILDER_COUNT) > $(BUILDER_CACHE_FILE)

stop: stop-server $(shell for (( i=1; i<=$(BUILDER_COUNT); i+=1 )); do echo "stop-builder-$$i"; done) ## Stop/Halt server and all builder VMs.

stop-server: ## Stop/Halt the server VM.
	$(VAGRANT) halt -f

stop-builder-%: ## Stop/Halt a builder VM, where `%` is the number of the builder.
	BUILDER=$* $(VAGRANT) halt -f

stop-builders: $(shell for (( i=1; i<=$(BUILDER_COUNT); i+=1 )); do echo "stop-builder-$$i"; done) ## Stop/Halt all builder VMs.

ssh-server: ## SSH into the server VM.
	$(VAGRANT) ssh

ssh-builder-%: ## SSH into a builder VM, where `%` is the number of the builder.
	BUILDER=$* $(VAGRANT) ssh

clean: clean-server clean-builders clean-data ## Destroy server and builder VMs.

clean-server: ## Remove the server VM.
	-$(VAGRANT) destroy -f

clean-builder-%: ## Remove a builder VM, where `%` is the number of the builder.
	-BUILDER=$* $(VAGRANT) destroy -f builder-$*

clean-builders: $(shell for (( i=1; i<=$(BUILDER_COUNT); i+=1 )); do echo "clean-builder-$$i"; done) ## Remove all builder VMs.

clean-data: ## Remove data (shared folders) and disks of all VMs (server and builders).
	@rm -rf "$(MFILECWD)data/"*
	@rm -rf $(BUILDER_CACHE_FILE)

clean-force: ## Remove all drives which should normally have been removed by the normal clean-server or clean-builder-% targets.
	@rm -v -rf "$(MFILECWD).vagrant/"*.vdi "$(MFILECWD).vagrant/"*.img

vagrant-reload: vagrant-reload-server vagrant-reload-builders ## Run vagrant reload on server and builders.

vagrant-reload-server: ## Run vagrant reload for server VM.
	$(VAGRANT) reload

vagrant-reload-builder-%: ## Run `vagrant reload` for specific builder VM.
	BUILDER=$* $(VAGRANT) reload --provision

vagrant-reload-builders: $(shell for (( i=1; i<=$(BUILDER_COUNT); i+=1 )); do echo "vagrant-reload-builder-$$i"; done) ## Run `vagrant reload` for all builder VMs.

ssh-config: ssh-config-server ssh-config-builders ## Generate SSH config for server and builders.

ssh-config-server: ## Generate SSH config just for the server.
	@$(VAGRANT) ssh-config --host "server"

ssh-config-builders: $(shell for (( i=1; i<=$(BUILDER_COUNT); i+=1 )); do echo "ssh-config-builder-$$i"; done) ## Generate SSH config just for the builders.

ssh-config-builder-%: ## Generate SSH config just for the one builder number given.
	@BUILDER=$* $(VAGRANT) ssh-config --host "builder$*"

status: status-server status-builders ## Show status of server and all builder VMs.

status-server: ## Show status of the server VM.
	@set -o pipefail; \
		STATUS_OUT="$$($(VAGRANT) status | tail -n+3)"; \
		if (( $$(echo "$$STATUS_OUT" | wc -l) > 5 )); then \
			echo "$$STATUS_OUT" | $(REVERSE_LINES) | tail -n +6 | $(REVERSE_LINES); \
		else \
			echo "$$STATUS_OUT" | $(REVERSE_LINES) | tail -n +3 | $(REVERSE_LINES); \
		fi | \
			sed '/^$$/d'

status-builder-%: ## Show status of a builder VM, where `%` is the number of the builder.
	@set -o pipefail; \
		STATUS_OUT="$$(BUILDER=$* $(VAGRANT) status | tail -n+3)"; \
		if (( $$(echo "$$STATUS_OUT" | wc -l) > 5 )); then \
			echo "$$STATUS_OUT" | $(REVERSE_LINES) | tail -n +6 | $(REVERSE_LINES); \
		else \
			echo "$$STATUS_OUT" | $(REVERSE_LINES) | tail -n +3 | $(REVERSE_LINES); \
		fi | \
			sed '/^$$/d'

status-builders: $(shell for (( i=1; i<=$(BUILDER_COUNT); i+=1 )); do echo "status-builder-$$i"; done) ## Show status of all builder VMs.

run-script: ## Run script on koji-server VM, which `SCRIPT_FILE=/path/to/script`
	$(eval DIR := $(MFILECWD)data/scripts)
	$(eval FILENAME := $(lastword $(subst /, ,$(SCRIPT_FILE))))
	@mkdir -p $(DIR)
	@cp $(SCRIPT_FILE) $(DIR)/$(FILENAME)
	@echo "[INFO] Executing '$(SCRIPT_FILE)' on server VM..."
ifeq ($(SCRIPT_USER),$(filter $(SCRIPT_USER), SUDO sudo ROOT root))
	$(eval USER := sudo)
else
	$(eval USER := "sudo runuser -u $(SCRIPT_USER) --")
endif
	@$(VAGRANT) ssh -- $(USER) bash /vagrant/scripts/$(FILENAME) $(SCRIPT_ARGS)

test-build-rpm: ## Run ./script/build_test.sh to test building RPM package
	@SCRIPT_USER=admin SCRIPT_FILE=$(MFILECWD)scripts/build_test.sh $(MAKE) run-script --no-print-directory

server-add-builder: ## Generate new builder cert, which `BUILDER_NAME=<name>`
	@SCRIPT_USER=root SCRIPT_FILE=$(MFILECWD)scripts/add-new-builder.sh \
		SCRIPT_ARGS=$(BUILDER_NAME) $(MAKE) run-script --no-print-directory

builder-up: vagrant-plugins-require ## Start new koji builder
ifndef KOJIHUB_IP
	$(info Usage: $ KOJIHUB_IP=<your-server-ip> make builder-up)
	$(error 'KOJIHUB_IP' environment is not set!)
endif
	@BUILDER=999 $(VAGRANT) up --provider $(VAGRANT_DEFAULT_PROVIDER)

builder-clean:  ## Destroy one koji builder `BUILDER_NAME=<name>`
	@BUILDER=999 $(VAGRANT) destroy -f $(BUILDER_NAME)

builder-ssh: ## SSH into a builder VM, which `BUILDER_NAME=<name>`
	@BUILDER=999 $(VAGRANT) ssh $(BUILDER_NAME)

help: ## Show this help menu.
	@echo "Usage: make [TARGET ...]"
	@echo
	@grep -E '^[a-zA-Z_%-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
.EXPORT_ALL_VARIABLES:
.PHONY: builder-up builder-clean builder-ssh \
	clean clean-server clean-builders clean-data \
	help \
	run-script \
	server-add-builder \
	show-env-config \
	ssh-config ssh-config-server ssh-config-builders \
	ssh-server ssh-builder-% \
	start-server start-builders \
	status status-server status-builders \
	stop stop-server stop-builders \
	test-build-rpm \
	vagrant-reload vagrant-reload-server vagrant-reload-builders \
	vagrant-plugins-require vagrant-plugins-libvirt\
	versions
