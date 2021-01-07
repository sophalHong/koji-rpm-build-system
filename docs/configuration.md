# Configuration

## Variables
| Variable Name                   | Default Value            | Description                                                             |
| ------------------------------- | ------------------------ | ------------------------------------------------------------------------|
| `VAGRANT_DEFAULT_PROVIDER`      | `virtualbox`             | Which Vagrant provider to use. Available are `virtualbox` and `libvirt`.|
| `VAGRANT`                       | `vagrant`                | Path to `vagrant` binary (needed when `vagrant` is no in your `PATH`)   |
| `SERVER_CPUS`                   | `2` Core                 | Amount of cores to use for the server VM.                               |
| `SERVER_MEMORY_SIZE_GB`         | `2` GB                   | Size of memory (in GB) to be allocated for the server VM.               |
| `BUILDER_COUNT`                 | `2`                      | How many worker builders should be spawned.                             |
| `BUILDER_CPUS`                  | `1` Core                 | Amount of cores to use for each builder VM.                             |
| `BUILDER_MEMORY_SIZE_GB`        | `2` GB                   | Size of memory (in GB) to be allocated for each builder VM.             |
| `DISK_COUNT`                    | `0`                      | Set how many additional disks will be added to the VMs.                 |
| `DISK_SIZE_GB`                  | `20` GB                  | Size of additional disks added to the VMs.                              |
| `FWD_PORT`                      | `8080`                   | Forwarding port number to enable access kojihub from host browser.      |
| `PRIVATE_IP`                    | `192.168.83.10`          | The Koji-hub server Private IP address. (builder IP = server IP ++)     |
| `PUBLIC_IP`                     | ``                       | The Koji-hub server Public IP address.  (builder IP = server IP ++)     |
| `PUBLIC_NW_NIC`                 | ``                       | Public Network Interface [eno1]. Not set mean using private network     |
| `NFS_MOUNTPATH`                 | ``                       | Public NFS server mountpath [ 192.168.11.127:/mnt/nfs-server ]          |
| `SCRIPT_FILE`                   | `./scripts/default.sh`   | Path to script file. Use with target `run-script` to execute on server  |
| `SCRIPT_USER`                   | `vagrant`                | Run script as USER. Use with target `run-script` to execute on server   |
| `SCRIPT_ARGS`                   | ``                       | Script arguments. Use with target `run-script` to execute on server     |
| `BUILDER_NAME`                  | `my-builder`             | Name of new koji builder. Use with target `add-builder`                 |
