# koji-rpm-build-system
This project is created to automatically deploy **koji** build system environment.

## Prerequisites

* Vagrant (>= `2.2.0`)  
* Vagrant Provider  
  * Virtualbox

## Quick start
To create 1-server and 1-builder host:
```shell
vagrant up
```

To view on web browser: HOST_IP:8080/koji

## Build RPM package
Change to 'admin' user:
```shell
vagrant ssh server
sudo bash
su - admin
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
