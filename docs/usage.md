# Documents

## Usage

- [Starting the environment](#starting-the-environment)
- [Faster (parallel) environment start](#faster-parallel-environment-start)
- [Show status of VMs](#show-status-of-vms)
- [Shutting down the environment](#shutting-down-the-environment)
- [SSH into VM](#ssh-into-vm)
- [Show `make` targets](#show-make-targets)
- [Add new koji builder](#add-new-koji-builder)
- [Run script on koji-server VM](#run-script-on-koji-server-vm)
- [Start new builder](#start-new-builder)

### Starting the environment
To start up the Vagrant Koji multi-node environment with all default values (not parallel) run:
```shell
make up
```

To start up the vagrant Koji multi-node with `libvirt` provider, run:
```shell
VAGRANT_DEFAULT_PROVIDER=libvirt make up
```

To start up the vagrant Koji multi-node using private network (Static), run:
```shell
PRIVATE_IP=192.168.33.10 make up
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
BUILDER_COUNT=3 make up -j 3
```
> The `-j 3` will cause three VMs to be started in parallel to speed up the cluster creation.

### Show status of VMs
```shell
make status
server                    running (virtualbox)
builder-1                 running (virtualbox)
builder-2                 running (virtualbox)
builder-3                 running (virtualbox)
```

### Shutting down the environment
To destroy the Vagrant environment, run:
```shell
make clean
```

### SSH into VM
To SSH into server VM:
```shell
make ssh-server
```

To SSH into builder#1 VM:
```shell
make ssh-builder-1
```

### Show `make` targets
```shell
make help
```

### Add new koji builder
```shell
BUILDER_NAME=new-builder make server-add-builder
```

### Run script on koji-server VM
To run script with default `vagrant` user, run:
```shell
SCRIPT_FILE=./scripts/my_script.sh make run-script
```

To run script with `root` user, run:
```shell
SCRIPT_USER=root SCRIPT_FILE=./scripts/my_script.sh make run-script
```

To run script with `admin` user and args, run:
```shell
SCRIPT_USER=admin SCRIPT_FILE=./scripts/my_script.sh SCRIPT_ARGS="hello world" make run-script
```

### Start new builder
To create and start new koji builder, run:
```shell
KOJIHUB_IP=192.168.0.200 make builder-up
```

To create and start new koji builder with specific name and address, run:
```shell
BUILDER_NAME=arirang PUBLIC_NW_NIC=eno1 MY_IP=192.168.0.210 KOJIHUB_IP=192.168.0.200 make builder-up
```

To create and start new koji builder with specific NFS, run:
```shell
NFS_MOUNTPATH=192.168.11.127:/mnt/koji KOJIHUB_IP=192.168.0.200 make builder-up
```

To SSH into builder VM, run:
```shell
BUILDER_NAME=arirang make builder-ssh
```

To destroy builder VM, run:
```shell
BUILDER_NAME=arirang make builder-clean
```
