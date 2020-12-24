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
SERVER_CPUS ?=
SERVER_MEMORY_SIZE_GB ?=
BUILDER_CPUS ?=
BUILDER_MEMORY_SIZE_GB ?=
BUILDER_COUNT ?= 2
# Libvirt
LIBVIRT_STORAGE_POOL ?=
# Network
SERVER_IP ?= 192.168.83.10
BUILDER_IP_NW ?=
# === END USER OPTIONS ===

VAGRANT_LOG ?=
VAGRANT_VAGRANTFILE ?= $(MFILECWD)/vagrantfiles/Vagrantfile

up: ## Start Kubernetes Vagrant multi-node cluster. Creates, starts and bootsup the master and node VMs.
	$(MAKE) start

start:
ifeq ($(PARALLEL_VM_START),true)
	$(MAKE) start-server start-builders
else
	$(MAKE) start-server
	$(MAKE) start-builders
endif

start-server: ## Start up master VM (automatically done by `up` target).
	$(VAGRANT) up --provider $(VAGRANT_DEFAULT_PROVIDER)

start-builder-%: ## Start node VM, where `%` is the number of the node.
	BUILDER=$* $(VAGRANT) up --provider $(VAGRANT_DEFAULT_PROVIDER)

start-builders: $(shell for (( i=1; i<=$(BUILDER_COUNT); i+=1 )); do echo "start-builder-$$i"; done) ## Create and start all node VMs by utilizing the `node-X` target (automatically done by `up` target).

stop: stop-server $(shell for (( i=1; i<=$(BUILDER_COUNT); i+=1 )); do echo "stop-builder-$$i"; done) ## Stop/Halt master and all nodes VMs.

stop-server: ## Stop/Halt the master VM.
	$(VAGRANT) halt -f

stop-builder-%: ## Stop/Halt a node VM, where `%` is the number of the node.
	BUILDER=$* $(VAGRANT) halt -f

stop-builders: $(shell for (( i=1; i<=$(BUILDER_COUNT); i+=1 )); do echo "stop-builder-$$i"; done) ## Stop/Halt all node VMs.

ssh-server: ## SSH into the master VM.
	$(VAGRANT) ssh

ssh-builder-%: ## SSH into a node VM, where `%` is the number of the node.
	BUILDER=$* $(VAGRANT) ssh

clean: clean-server $(shell for (( i=1; i<=$(BUILDER_COUNT); i+=1 )); do echo "clean-builder-$$i"; done) ## Destroy master and node VMs, delete data and the kubectl context.
	$(MAKE) clean-data

clean-server: ## Remove the master VM and the kubectl context.
	-$(VAGRANT) destroy -f

clean-builder-%: ## Remove a node VM, where `%` is the number of the node.
	-BUILDER=$* $(VAGRANT) destroy -f builder-$*

clean-builders: $(shell for (( i=1; i<=$(BUILDER_COUNT); i+=1 )); do echo "clean-builder-$$i"; done) ## Remove all node VMs.

clean-force: ## Remove all drives which should normally have been removed by the normal clean-master or clean-node-% targets.
	rm -v -rf "$(MFILECWD)/.vagrant/"*.vdi "$(MFILECWD)/.vagrant/"*.img

vagrant-reload: vagrant-reload-server vagrant-reload-builders ## Run vagrant reload on master and nodes.

vagrant-reload-server: ## Run vagrant reload for master VM.
	$(VAGRANT) reload

vagrant-reload-builder-%: ## Run `vagrant reload` for specific node  VM.
	BUILDER=$* $(VAGRANT) reload --provision

vagrant-reload-builders: $(shell for (( i=1; i<=$(BUILDER_COUNT); i+=1 )); do echo "vagrant-reload-builder-$$i"; done) ## Run `vagrant reload` for all node VMs.

load-image: load-image-master $(shell for (( i=1; i<=$(BUILDER_COUNT); i+=1 )); do echo "load-image-node-$$i"; done) ## Load local/pulled Docker image into master and all node VMs.

load-image-master: ## Load local/pulled image into master VM.
	docker save $(IMG) | $(VAGRANT) ssh "master" -t -c 'sudo docker load'
	@if [ ! -z "$(TAG)" ]; then \
		$(VAGRANT) ssh "master" -t -c 'sudo docker tag $(IMG) $(TAG)'; \
	fi

load-image-node-%: ## Load local/pulled image into node VM, where `%` is the number of the node.
	docker save $(IMG) | BUILDER=$* $(VAGRANT) ssh "node$*" -t -c 'sudo docker load'
	@if [ ! -z "$(TAG)" ]; then \
		BUILDER=$* $(VAGRANT) ssh "node$*" -t -c 'sudo docker tag $(IMG) $(TAG)'; \
	fi

load-image-nodes: $(shell for (( i=1; i<=$(BUILDER_COUNT); i+=1 )); do echo "load-image-node-$$i"; done) ## Load local/pulled Docker image into all node VMs.

ssh-config: ssh-config-master ssh-config-nodes ## Generate SSH config for master and nodes.

ssh-config-master: ## Generate SSH config just for the master.
	@$(VAGRANT) ssh-config --host "master"

ssh-config-nodes: $(shell for (( i=1; i<=$(BUILDER_COUNT); i+=1 )); do echo "ssh-config-node-$$i"; done) ## Generate SSH config just for the nodes.

ssh-config-node-%: ## Generate SSH config just for the one node number given.
	@BUILDER=$* $(VAGRANT) ssh-config --host "node$*"

status: status-master $(shell for (( i=1; i<=$(BUILDER_COUNT); i+=1 )); do echo "status-node-$$i"; done) ## Show status of master and all node VMs.

status-master: ## Show status of the master VM.
	@set -o pipefail; \
		STATUS_OUT="$$($(VAGRANT) status | tail -n+3)"; \
		if (( $$(echo "$$STATUS_OUT" | wc -l) > 5 )); then \
			echo "$$STATUS_OUT" | $(REVERSE_LINES) | tail -n +6 | $(REVERSE_LINES); \
		else \
			echo "$$STATUS_OUT" | $(REVERSE_LINES) | tail -n +3 | $(REVERSE_LINES); \
		fi | \
			sed '/^$$/d'

status-node-%: ## Show status of a node VM, where `%` is the number of the node.
	@set -o pipefail; \
		STATUS_OUT="$$(BUILDER=$* $(VAGRANT) status | tail -n+3)"; \
		if (( $$(echo "$$STATUS_OUT" | wc -l) > 5 )); then \
			echo "$$STATUS_OUT" | $(REVERSE_LINES) | tail -n +6 | $(REVERSE_LINES); \
		else \
			echo "$$STATUS_OUT" | $(REVERSE_LINES) | tail -n +3 | $(REVERSE_LINES); \
		fi | \
			sed '/^$$/d'

status-nodes: $(shell for (( i=1; i<=$(BUILDER_COUNT); i+=1 )); do echo "status-node-$$i"; done) ## Show status of all node VMs.

tests: ## Run shunit2 tests (`expect` command is required).
	@KUBERNETES_VERSION=$$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt | sed 's/^v//') \
		bash ./tests/cluster-tests.sh$(if $(TESTS), -- $(TESTS),)

help: ## Show this help menu.
	@echo "Usage: make [TARGET ...]"
	@echo
	@grep -E '^[a-zA-Z_%-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
.EXPORT_ALL_VARIABLES:
.PHONY: help kubectl kubectl-delete preflight token up \
	clean clean-data clean-master clean-nodes \
	load-image load-image-master load-image-nodes \
	ssh-config ssh-config-master ssh-config-nodes \
	ssh-master \
	start-master start-nodes \
	status status-master status-nodes \
	stop stop-master stop-nodes \
	tests \
	vagrant-reload vagrant-reload-master vagrant-reload-nodes \
	vagrant-plugins

.PHONY: docs-serve
docs-serve:
	docker run --net=host --volume "$$(pwd)":"$$(pwd)" --workdir "$$(pwd)" -it squidfunk/mkdocs-material

.PHONY: docs-build
docs-build:
	docker run --net=host --volume "$$(pwd)":"$$(pwd)" --workdir "$$(pwd)" -it squidfunk/mkdocs-material build --clean
