# ProLinux image build guide
## Install packages
- Add repository (/etc/yum.repos.d/imagefactory.repo)
```shell
[imagefactory]
name=ProLinux imagefactory
baseurl=http://pldev-repo-21.tk/prolinux-dev/sophal/imagefactory/
gpgcheck=0
enabled=1
```
- Dependency packages
```shell
sudo yum install -y pykickstart VMDKstream virt-install
```
- Imagefactory packages
```shell
sudo yum install -y imagefactory imagefactory-plugins \
  imagefactory-plugins-Docker \
  imagefactory-plugins-GCE \
  imagefactory-plugins-HyperV \
  imagefactory-plugins-IndirectionCloud \
  imagefactory-plugins-OVA \
  imagefactory-plugins-RHEVM \
  imagefactory-plugins-TinMan \
  imagefactory-plugins-ovfcommon \
  imagefactory-plugins-vSphere
```

## Create template
```shell
cat > prolinux-8.2.tdl << EOF
<template>
  <name>ProLinux-8.2</name>
  <os>
    <name>ProLinux</name>
    <version>8</version>
    <arch>x86_64</arch>
    <install type='url'>
      <url>http://pldev-repo-21.tk/prolinux/8.2/os/x86_64/</url>
    </install>
    <rootpw>root</rootpw>
  </os>
</template>
EOF
```

## Create or Download ProLinux kickstart
```shell
wget https://raw.githubusercontent.com/sophalHong/koji-rpm-build-system/main/docs/ProLinux-8-GenericCloud.ks
```

## Build images
- Base image
```shell
sudo imagefactory --debug --timeout 12000 base_image --file-parameter install_script \
  ./ProLinux-8-GenericCloud.ks --parameter offline_icicle true ./prolinux-8.2.tdl
```

- Build VMware Fusion image from base image
```shell
sudo ./imagefactory --debug target_image --parameter vsphere_vmdk_format standard --id ${BASE-IMAGE-ID} vsphere
```
- Build Virtualbox image from base image
```shell
sudo ./imagefactory --debug target_image --id ${BASE-IMAGE-ID} vsphere
```
- Build libvirt image from base image
```shell
sudo ./imagefactory --debug target_image --id ${BASE-IMAGE-ID} rhevm
```
- Build Docker image
```shell
sudo imagefactory --debug target_image --id ${BASE-IMAGE-ID} docker --parameter compress xz
docker load -i full/path/to/compressed/image/filename
```
