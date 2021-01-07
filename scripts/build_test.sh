#!/bin/bash
set -eo pipefail

# Enable 'vagrant' user to control Koji by using admin certs
sudo cp -r /home/admin/.koji /home/vagrant/
sudo chown -R vagrant:vagrant /home/vagrant/.koji

# test building RPM pacakge from src
koji add-tag dist-centos8
koji add-tag --parent dist-centos8 --arches "x86_64" dist-centos8-build

koji add-external-repo -t dist-centos8-build dist-CentOS8-BaseOS http://mirror.kakao.com/centos/8.3.2011/BaseOS/x86_64/os/
koji add-external-repo -t dist-centos8-build dist-CentOS8-AppStream http://mirror.kakao.com/centos/8.3.2011/AppStream/x86_64/os/
koji add-external-repo -t dist-centos8-build dist-CentOS8powertools http://mirror.kakao.com/centos/8.3.2011/PowerTools/x86_64/os/
koji add-external-repo -t dist-centos8-build dist-Epel https://mirror.hoster.kz/fedora/epel/8/Everything/x86_64/
koji add-target dist-centos8 dist-centos8-build

koji add-group dist-centos8-build build
koji add-group dist-centos8-build srpm-build
koji add-group-pkg dist-centos8-build build bash bzip2 coreutils cpio diffutils findutils gawk gcc gcc-c++ gnupg2 grep gzip info make patchredhat-rpm-config rpm-build scl-utils-build sed shadow-utils tar unzip util-linux which
koji add-group-pkg dist-centos8-build srpm-build bash gnupg2 libedit make openssh-clients redhat-rpm-config rpm-build rpmdevtools scl-utils-build shadow-utils wget

koji regen-repo --nowait dist-centos8-build

# quick test building package
curl -LO https://vault.centos.org/8.1.1911/BaseOS/Source/SPackages/tree-1.7.0-15.el8.src.rpm
koji build --nowait --scratch dist-centos8 tree-1.7.0-15.el8.src.rpm
curl -LO  http://vault.centos.org/8.1.1911/BaseOS/Source/SPackages/tmux-2.7-1.el8.src.rpm
koji build --nowait --scratch dist-centos8 tmux-2.7-1.el8.src.rpm

# permanently build and maintain with koji
#koji add-pkg --owner=admin dist-centos8 tree
#koji build --nowait dist-centos8 tree-1.7.0-15.el8.src.rpm
#koji add-pkg --owner=admin dist-centos8 tmux
#koji build dist-centos8 tmux-2.7-1.el8.src.rpm
#koji list-tasks
#koji list-builds --owner=admin
