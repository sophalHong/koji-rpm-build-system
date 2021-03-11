# How to create vagrant box (virtualbox)
## Getting prepared
- Download [vagrant installer](https://www.vagrantup.com/downloads) for your operating system, then install
- Download [Virtualbox installer](https://www.virtualbox.org/wiki/Downloads) for your operating system, then install
- Download ISO file you want to build the box

## Build a VirtualBox VM
- Configure virtual hardware (Name, Type, Version, CPU, Memory, Disk, Network)
- **Ensure Network Adapter 1 is set to NAT**
- Mount ISO and boot up the server
- Install the operating system

## Vagrant configuration
- Add vagrant welcome message (optional)
```shell
echo "Welcome to Vagrant virtual machine." > /etc/motd
date > /etc/vagrant_box_build_time
```

- Add vagrant user
```shell
/usr/sbin/groupadd vagrant
/usr/sbin/useradd -m vagrant -p vagrant -s /bin/bash
/usr/sbin/useradd vagrant -g vagrant -G wheel
echo "vagrant"|passwd --stdin vagrant
echo "vagrant        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/vagrant
chmod 0440 /etc/sudoers.d/vagrant
```

- Add vagrant SSH key
```shell
mkdir -pm 700 /home/vagrant/.ssh
wget --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O /home/vagrant/.ssh/authorized_keys
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant /home/vagrant/.ssh
```

- Install requirement packages for Virtualbox Guest additions
```shell
sudo yum install -y kernel-headers kernel-devel gcc make perl bzip2 wget tar elfutils-libelf-devel
```

- Install Virtualbox Guest Addition [Download](http://download.virtualbox.org/virtualbox/) 
```shell
# Devices -> Insert Virtualbox Guest Addition CD image
sudo mount /dev/cdrom /mnt
sudo bash /mnt/VBoxLinuxAdditions.run
sudo umount /mnt
```

- Cleanup
```shell
sudo yum clean all
```

## Build box
- packaging box
```shell
vagrant package --base <VM-NAME>
```

- adding box
```shell
vagrant box add <BOX-NAME> package.box
```

- testing
```shell
vagrant init <BOX-NAME>
vagrant up
vagrant ssh
```
