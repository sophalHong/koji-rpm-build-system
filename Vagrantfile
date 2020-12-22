# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|
  config.vm.define "server" do |server|
    server.vm.box = "prolinux/koji-server"
    server.vm.network "forwarded_port", guest: 80, host: 8080
    server.vm.network "private_network", ip: "192.168.33.10"
    server.vm.provision "shell", inline: <<-SHELL
      # Setup NFS server
      dnf install nfs-utils -y
      echo '/mnt/koji	*(rw,sync,no_all_squash,root_squash)' >> /etc/exports
      echo '/etc/pki/koji	*(ro,sync,no_all_squash,root_squash)' >> /etc/exports
      exportfs -arv
      exportfs -s
      systemctl enable nfs-server.service
      systemctl start nfs-server.service
      systemctl status nfs-server.service --no-pager
      
      # Add koji builder (kojid) 
      cd /etc/pki/koji
      caname=koji
      builder=kojid-1
      openssl genrsa -out certs/${builder}.key 2048
      cat ssl.cnf | sed 's/YOUR_KOJI_HOSTNAME/'${builder}'/'> ssl2.cnf
      openssl req -config ssl2.cnf -new -nodes -out certs/${builder}.csr -key certs/${builder}.key -subj "/C=KO/ST=Gyeonggi/O=TmaxA&C/CN=${builder}"
      openssl ca -batch -config ssl2.cnf -keyfile private/${caname}_ca_cert.key -cert ${caname}_ca_cert.crt -out certs/${builder}.crt -outdir certs -infiles certs/${builder}.csr
      cat certs/${builder}.crt certs/${builder}.key > ${builder}.pem
      mv ssl2.cnf config/${builder}-ssl.cnf
      
      runuser -u admin -- koji add-host ${builder} x86_64
      runuser -u admin -- koji add-host-to-channel ${builder} createrepo
    SHELL
  end

  config.vm.define "builder" do |builder|
    builder.vm.box = "prolinux/koji-builder"
    builder.vm.network "private_network", ip: "192.168.33.11"
    builder.vm.provision "shell", inline: <<-SHELL
      echo '192.168.33.10	koji.tmax' >> /etc/hosts
      sed -i 's/KOJID_USER/kojid-1/g' /etc/kojid/kojid.conf
      
      mkdir -p /mnt/koji
      mount -t nfs koji.tmax:/mnt/koji /mnt/koji
      
      mkdir -p /etc/pki/koji
      mount -t nfs koji.tmax:/etc/pki/koji /etc/pki/koji
      
      systemctl enable kojid.service
      systemctl start kojid.service
      systemctl status kojid.service --no-pager
    SHELL
  end
end
