# Bash is required as the shell
SHELL := /usr/bin/env bash

# Set Makefile directory in variable for referencing other files
MFILECWD = $(dir $(realpath $(firstword $(MAKEFILE_LIST))))

# sed 1-liner to reverse the lines in an input stream
REVERSE_LINES=sed -e '1!G;h;$$!d'

VAGRANT ?= vagrant

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
BUILDER_COUNT ?= 1
# Libvirt
LIBVIRT_STORAGE_POOL ?=
# Network
## Private Network (Server ip = PRIVATE_IP, Builder ip = PRIVATE_IP++)
## Public Network (PUBLIC_NW_NIC=eno1) | Not set = using private network
PRIVATE_IP ?= 192.168.83.10
PUBLIC_NW_NIC ?=
PUBLIC_IP ?=
# === END USER OPTIONS ===

VAGRANT_LOG ?=
VAGRANT_VAGRANTFILE ?= $(MFILECWD)/vagrantfiles/Vagrantfile

show-env-config: ## Show all Environment values configuration used to create VMs.
	@echo "==== Environment Info ===="
	@echo "VAGRANT_DEFAULT_PROVIDER = $(VAGRANT_DEFAULT_PROVIDER) (Default vagrant provider)"
	@echo "VAGRANT_VAGRANTFILE      = $(VAGRANT_VAGRANTFILE) (Vagrantfile)"
	@echo "-------- Server --------"
	@echo "SERVER_COUNT             = 1 (always one)"
	@echo "SERVER_CPUS              = $(SERVER_CPUS)"
	@echo "SERVER_MEMORY_SIZE_GB    = $(SERVER_MEMORY_SIZE_GB) (GB)"
	@echo "SERVER_IP                = $(SERVER_IP)"
	@echo "------------------------"
	@echo "******* Builder ********"
	@echo "BUILDER_COUNT            = $(BUILDER_COUNT)"
	@echo "BUILDER_CPUS             = $(BUILDER_CPUS)"
	@echo "BUILDER_MEMORY_SIZE_GB   = $(BUILDER_MEMORY_SIZE_GB) (GB)"
	@echo "BUILDER_IP_NW            = $(BUILDER_IP_NW)[server_ip + builder#]"
	@echo "************************"
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

up: start ## Start Koji Vagrant multi-node cluster. starts and bootsup the server and builder VMs.

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

clean: clean-server $(shell for (( i=1; i<=$(BUILDER_COUNT); i+=1 )); do echo "clean-builder-$$i"; done) ## Destroy server and builder VMs.
	@$(MAKE) clean-data --no-print-directory

clean-server: ## Remove the server VM.
	-$(VAGRANT) destroy -f

clean-builder-%: ## Remove a builder VM, where `%` is the number of the builder.
	-BUILDER=$* $(VAGRANT) destroy -f builder-$*

clean-builders: $(shell for (( i=1; i<=$(BUILDER_COUNT); i+=1 )); do echo "clean-builder-$$i"; done) ## Remove all builder VMs.

clean-data: ## Remove data (shared folders) and disks of all VMs (server and builders).
	@rm -v -rf "$(MFILECWD)/data/"*

clean-force: ## Remove all drives which should normally have been removed by the normal clean-server or clean-builder-% targets.
	@rm -v -rf "$(MFILECWD)/.vagrant/"*.vdi "$(MFILECWD)/.vagrant/"*.img

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

help: ## Show this help menu.
	@echo "Usage: make [TARGET ...]"
	@echo
	@grep -E '^[a-zA-Z_%-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
.EXPORT_ALL_VARIABLES:
.PHONY: clean clean-server clean-builders clean-data \
	help \
	show-env-config \
	ssh-config ssh-config-server ssh-config-builders \
	ssh-server ssh-builder-% \
	start-server start-builders \
	status status-server status-builders \
	stop stop-server stop-builders \
	vagrant-reload vagrant-reload-server vagrant-reload-builders \
	vagrant-plugins \
	versions
