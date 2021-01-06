# koji-rpm-build-system
This project is created to automatically deploy **koji** build system environment.
> The Koji Build System is Fedora's RPM buildsystem. Packagers use the koji client to request package builds and get information about the buildsystem. Koji runs on top of Mock to build RPM packages for specific architectures and ensure that they build correctly. 

<!-- TOC depthFrom:2 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Prerequisites](#prerequisites)
- [Hardware Requirements](#hardware-requirements)
- [Quick start](#quick-start)
- [Usage](#usage)
  - [Starting the environment](#starting-the-environment)
  - [Faster (parallel) environment start](#faster-parallel-environment-start)
  - [Show status of VMs](#show-status-of-vms)
  - [Shutting down the environment](#shutting-down-the-environment)
  - [SSH into VM](#ssh-into-vm)
  - [Show `make` targets](#show-make-targets)
- [Variables](#variables)
- [Build RPM package](#build-rpm-package)
- [Demo](#demo)
  - [Start Koji multi-node cluster](#start-koji-multi-node-cluster)
  - [Destroy Cluster](#destroy-cluster)
- [Creating an Issue](#creating-an-issue)

<!-- /TOC -->

## Prerequisites

* Vagrant (>= `2.2.0`)
  * Plugins
    * vagrant-reload (vagrant plugin install vagrant-reload)
    * vagrant-libvirt (vagrant plugin install vagrant-libvirt)
* Vagrant Provider  
  * Virtualbox
  * libvirt (qemu)

## Hardware Requirements

* Server
  * CPU: 2 Cores (`SERVER_CPUS`)
  * Memory: 2GB (`SERVER_MEMORY_SIZE_GB`)
* 1x Builder:
  * CPU: 1 Core (it is recommended to use at least 2 Cores; `BUILDER_CPUS`)
  * Memory: 2GB (it is recommended to use more than 2GB; `BUILDER_MEMORY_SIZE_GB`)

These resources can be changed by setting the according variables for the `make up` command, see [Variables](#variables) section.

## Quick start
To create Koji cluster with default values '1-server and 1-builder' host:
```shell
$ make up
```
> To view on web browser: HOST_IP:8080/koji

## Usage
### Starting the environment
To start up the Vagrant Koji multi-node environment with all default values (not parallel) run:
```shell
$ make up
```

To start up the vagrant Koji multi-node with `libvirt` provider, run:
```shell
VAGRANT_DEFAULT_PROVIDER=libvirt make up
```

To start up the vagrant Koji multi-node using public network (DHCP), run:
```shell
PUBLIC_NW_NIC=eno1 make up
```

To start up the vagrant Koji multi-node using public network (static), run:
```shell
PUBLIC_NW_NIC=eno1 PUBLIC_IP=192.168.0.201 make up
```

To start up the vagrant Koji multi-node mounting to public NFS server, run:
```shell
NFS_MOUNTPATH=192.168.11.127:/mnt/koji make up
```
> Make sure that NFS server is running and option `no_root_squash`,`insecure` is provided in export file.

### Faster (parallel) environment start
To start up 3 VMs in parallel run (`-j` flag does not control how many (builder) VMs are started, the `BUILDER_COUNT` variable is used for that): 
```shell
$ BUILDER_COUNT=3 make up -j 3
```
> The `-j 3` will cause three VMs to be started in parallel to speed up the cluster creation.

### Show status of VMs
```shell
$ make status
server                    running (virtualbox)
builder-1                 running (virtualbox)
builder-2                 running (virtualbox)
builder-3                 running (virtualbox)
```

### Shutting down the environment
To destroy the Vagrant environment, run:
```shell
$ make clean
```

### SSH into VM
To SSH into server VM:
```shell
$ make ssh-server
```

To SSH into builder#1 VM:
```shell
$ make ssh-builder-1
```

### Show `make` targets
To see all available targets:
```shell
$ make help
Usage: make [TARGET ...]

clean-builder-%                Remove a builder VM, where `%` is the number of the builder.
clean-builders                 Remove all builder VMs.
clean                          Destroy server and builder VMs.
clean-data                     Remove data (shared folders) and disks of all VMs (server and builders).
clean-force                    Remove all drives which should normally have been removed by the normal clean-server or clean-builder-% targets.
clean-server                   Remove the server VM.
help                           Show this help menu.
show-env-config                Show all Environment values configuration used to create VMs.
ssh-builder-%                  SSH into a builder VM, where `%` is the number of the builder.
ssh-config-builder-%           Generate SSH config just for the one builder number given.
ssh-config-builders            Generate SSH config just for the builders.
ssh-config-server              Generate SSH config just for the server.
ssh-config                     Generate SSH config for server and builders.
ssh-server                     SSH into the server VM.
start-builders                 Create and start all builder VMs by utilizing the `builder-X` target (automatically done by `up` target).
start-builder-%                Start builder VM, where `%` is the number of the builder.
start-server                   Start up server VM (automatically done by `up` target).
status-builders                Show status of all builder VMs.
status-builder-%               Show status of a builder VM, where `%` is the number of the builder.
status-server                  Show status of the server VM.
status                         Show status of server and all builder VMs.
stop-builders                  Stop/Halt all builder VMs.
stop-builder-%                 Stop/Halt a builder VM, where `%` is the number of the builder.
stop-server                    Stop/Halt the server VM.
stop                           Stop/Halt server and all builder VMs.
up                             Start Koji Vagrant multi-node cluster. starts and bootsup the server and builder VMs.
vagrant-reload-builder-%       Run `vagrant reload` for specific builder VM.
vagrant-reload-builders        Run `vagrant reload` for all builder VMs.
vagrant-reload-server          Run vagrant reload for server VM.
vagrant-reload                 Run vagrant reload on server and builders.
versions                       Print the "imporant" tools versions out for easier debugging.
```

## Variables
see [Variables doc page](docs/configuration.md)

## Build RPM package
see [How to build RPM package. doc page](docs/build_rpm.md)

## Demo
### Start Koji multi-node cluster

### Destroy Cluster

## Creating an Issue
Please attach the `make versions` output to the issue as is shown in the issue template. This makes debugging easier.
