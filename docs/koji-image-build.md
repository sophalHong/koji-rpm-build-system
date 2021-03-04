# Koji image-build guide
## Add host to channel build image
- login as koji admin
```shell
koji add-host <KOJI-BUILDER> x86_64
koji add-host-to-channel <KOJI-BUILDER> imgae
```

- Koji-builder host: restart kojid service
```shell
sudo systemctl restart kojid.service
```

## Create image-build config
```shell
cat > prolinux-image-build.cfg << EOF
[image-build]
name = ProLinux-8-x86_64-GenericCloud
version = 8.2
target = dist-centos8
install_tree = http://pldev-repo-21.tk/prolinux/8.2/os/x86_64/
arches = x86_64

format = qcow2,rhevm-ova,vsphere-ova,vagrant-virtualbox
distro = Fedora-29
repo = http://pldev-repo-21.tk/prolinux/8.2/os/x86_64/BaseOS/,http://pldev-repo-21.tk/prolinux/8.2/os/x86_64/AppStream
disk_size = 20

ksversion = RHEL8
kickstart = ProLinux-8-GenericCloud.ks
EOF
```

## Create or Download ProLinux kickstart
```shell
wget https://raw.githubusercontent.com/sophalHong/koji-rpm-build-system/main/docs/ProLinux-8-GenericCloud.ks
```

## Execute image-build
```shell
koji image-build --config=prolinux-image-build.cfg
```
