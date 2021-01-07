#! /bin/bash
set -eo pipefail
[[ $EUID -ne 0 ]] && { echo "Please run as root! 'sudo'"; exit 1; }
[[ -z "$1" ]] && { echo "Usage: $0 <BUILDER_NAME>"; exit 1; }

builder=$1
echo "Add koji builder '${builder}' ..."
cd /etc/pki/koji
openssl genrsa -out certs/${builder}.key 2048 &> /dev/null
cat ssl.cnf | sed 's/YOUR_KOJI_HOSTNAME/'${builder}'/'> ssl2.cnf
openssl req -config ssl2.cnf -new -nodes -out certs/${builder}.csr -key certs/${builder}.key -subj "/C=KO/ST=Gyeonggi/O=TmaxA&C/CN=${builder}"
openssl ca -batch -config ssl2.cnf -keyfile private/koji_ca_cert.key -cert koji_ca_cert.crt -out certs/${builder}.crt -outdir certs -infiles certs/${builder}.csr
cat certs/${builder}.crt certs/${builder}.key > ${builder}.pem
mv ssl2.cnf config/${builder}-ssl.cnf

runuser -u admin -- koji add-host ${builder} x86_64
runuser -u admin -- koji add-host-to-channel ${builder} createrepo

dir=/vagrant/${builder}
mkdir -p ${dir}
cp -v ${builder}.pem ${dir}/
echo 
echo "Get builder's Certificate (${builder}.pem) from './data/${builder}/' directory."
echo "Done!"
