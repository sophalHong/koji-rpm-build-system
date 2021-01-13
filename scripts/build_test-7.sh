#!/bin/bash
set -eo pipefail

cd $HOME
# test building RPM pacakge from src
koji add-tag dist-centos7
koji add-tag --parent dist-centos7 --arches "x86_64" dist-centos7-build

koji add-external-repo -t dist-centos7-build dist-CentOS7-BaseOS http://mirror.kakao.com/centos/7.9.2009/os/x86_64/
koji add-external-repo -t dist-centos7-build dist-CentOS7-Extras http://mirror.kakao.com/centos/7.9.2009/extras/x86_64/
koji add-external-repo -t dist-centos7-build dist-CentOS7-Update http://mirror.kakao.com/centos/7.9.2009/updates/x86_64/
koji add-external-repo -t dist-centos7-build dist-CentOS7-Epel https://mirror.hoster.kz/fedora/epel/7/x86_64/
koji add-target dist-centos7 dist-centos7-build

koji add-group dist-centos7-build build
koji add-group dist-centos7-build srpm-build
koji add-group-pkg dist-centos7-build build bash bzip2 coreutils cpio diffutils findutils gawk gcc gcc-c++ gnupg2 grep gzip info make patchredhat-rpm-config rpm-build scl-utils-build sed shadow-utils tar unzip util-linux which
koji add-group-pkg dist-centos7-build srpm-build bash gnupg2 libedit make openssh-clients redhat-rpm-config rpm-build rpmdevtools scl-utils-build shadow-utils wget

koji regen-repo --nowait dist-centos7-build

# quick test building package
curl -LO https://vault.centos.org/7.7.1908/os/Source/SPackages/tree-1.6.0-10.el7.src.rpm
koji build --nowait --scratch dist-centos7 tree-1.6.0-10.el7.src.rpm
curl -LO  http://vault.centos.org/7.7.1908/os/Source/SPackages/tmux-1.8-4.el7.src.rpm 
koji build --nowait --scratch dist-centos7 tmux-1.8-4.el7.src.rpm

# permanently build and maintain with koji
#koji add-pkg --owner=admin dist-centos7 tree
#koji build --nowait dist-centos7 tree-1.6.0-10.el7.src.rpm
#koji add-pkg --owner=admin dist-centos7 tmux
#koji build --nowait dist-centos7 tmux-1.8-4.el7.src.rpm
#koji list-tasks
#koji list-builds --owner=admin
