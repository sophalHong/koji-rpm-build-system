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
* Vagrant Provider  
  * Virtualbox

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
| Variable Name                   | Default Value            | Descriptioni                                                            |
| ------------------------------- | ------------------------ | ------------------------------------------------------------------------|
| `VAGRANT_DEFAULT_PROVIDER`      | `virtualbox`             | Which Vagrant provider to use. Available are `virtualbox` and `libvirt`.|
| `VAGRANT`                       | `vagrant`                | Path to `vagrant` binary (needed when `vagrant` is no in your `PATH`)   |
| `SERVER_CPUS`                   | `2` Core                 | Amount of cores to use for the server VM.                               |
| `SERVER_MEMORY_SIZE_GB`         | `2` GB                   | Size of memory (in GB) to be allocated for the server VM.               |
| `BUILDER_COUNT`                 | `2`                      | How many worker builders should be spawned.                             |
| `BUILDER_CPUS`                  | `1` Core                 | Amount of cores to use for each builder VM.                             |
| `BUILDER_MEMORY_SIZE_GB`        | `2` GB                   | Size of memory (in GB) to be allocated for each builder VM.             |
| `SERVER_IP`                     | `192.168.26.10`          | The Kubernetes server builder IP.                                       |
| `BUILDER_IP_NW`                 | `192.168.26.`            | The first three parts of the IPs used for the builders.                 |
| `DISK_COUNT`                    | `0`                      | Set how many additional disks will be added to the VMs.                 |
| `DISK_SIZE_GB`                  | `20` GB                  | Size of additional disks added to the VMs.                              |

## Build RPM package
SSH into server VM:
```shell
$ make ssh-server
```

Change to Koji 'admin' user:
```shell
$ sudo bash
$ su - admin
```

Add 'tag':
```shell
koji add-tag dist-centos8
koji add-tag --parent dist-centos8 --arches "x86_64" dist-centos8-build
```

Add external-repo:
```shell
# you can change location of mirror to access repository faster
koji add-external-repo -t dist-centos8-build dist-CentOS8-BaseOS http://mirror.kakao.com/centos/8.3.2011/BaseOS/x86_64/os/
koji add-external-repo -t dist-centos8-build dist-CentOS8-AppStream http://mirror.kakao.com/centos/8.3.2011/AppStream/x86_64/os/
koji add-external-repo -t dist-centos8-build dist-CentOS8powertools http://mirror.kakao.com/centos/8.3.2011/PowerTools/x86_64/os/
koji add-external-repo -t dist-centos8-build dist-Epel https://mirror.hoster.kz/fedora/epel/8/Everything/x86_64/
koji add-target dist-centos8 dist-centos8-build
```

Add group && group-pkg:
```shell
koji add-group dist-centos8-build build
koji add-group dist-centos8-build srpm-build

koji add-group-pkg dist-centos8-build build bash bzip2 coreutils cpio diffutils findutils gawk gcc gcc-c++ gnupg2 grep gzip info make patchredhat-rpm-config rpm-build scl-utils-build sed shadow-utils tar unzip util-linux which
koji add-group-pkg dist-centos8-build srpm-build bash gnupg2 libedit make openssh-clients redhat-rpm-config rpm-build rpmdevtools scl-utils-build shadow-utils wget
```

Generate repository:
```shell
koji regen-repo dist-centos8-build
```
Download RPM source package you want to build:
```shell
curl -LO https://vault.centos.org/8.1.1911/BaseOS/Source/SPackages/tree-1.7.0-15.el8.src.rpm
```

Quick test building (scratch):
```shell
koji build --scratch dist-centos8 tree-1.7.0-15.el8.src.rpm
```

Add packages and permanently maintain:
```shell
koji add-pkg --owner=admin dist-centos8 tree
koji build dist-centos8 tree-1.7.0-15.el8.src.rpm
```

## Demo
### Start Koji multi-node cluster

### Destroy Cluster

## Creating an Issue
Please attach the `make versions` output to the issue as is shown in the issue template. This makes debugging easier.
