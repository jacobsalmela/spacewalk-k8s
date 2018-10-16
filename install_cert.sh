#!/bin/bash
# The following these steps will render all clients unable to connect
# until you redeploy the new ca cert ( RHN-ORG-TRUSTED-SSL-CERT)
# to EVERY client currently enrolled with the Spacewalk server.

# Recreate CA cert
# mv /root/ssl-build /root/ssl-build.bak
# cd /root
# rhn-ssl-tool --gen-ca
# rhn-ssl-tool --gen-server
#cp ./ssl-build/RHN-ORG-TRUSTED-SSL-CERT ./ssl-build/rhn-org-trusted-ssl-cert-1.0-1.noarch.rpm /var/www/html/pub
#rpm -e rhn-org-httpd-ssl-key-pair-HOSTNAME
#rpm -ivh ./ssl-build/HOSTNAME/rhn-org-httpd-ssl-key-pair-HOSTNAME-1.0-1.noarch.rpm
#rhn-ssl-dbstore -vvv --ca-cert /root/ssl-build/RHN-ORG-TRUSTED-SSL-CERT
#spacewalk-service restart
#Redeploy RHN-ORG-TRUSTED-SSL-CERT to clients (if needed)

# Generate a CSR
# openssl req -new \
#   -key /root/sat_cert/satellite_cert_key.pem \
#   -out /root/sat_cert/satellite_cert_csr.pem


# https://omg.dje.li/2017/04/using-lets-encrypt-ssl-certificates-with-spacewalk/
openssl verify -CAfile /root/ca-chain.pem /etc/letsencrypt/live/spacewalk.domain.com/fullchain.pem
save ca-ccommon.crt to /root/ca-chain.pem

# Back up the existing Spacewalk certs
tar -zcvf SSLconfig.tar.gz \
   /etc/httpd/conf/ssl.* \
   /etc/pki/spacewalk/jabberd/server.pem \
   /root/ssl-build \
   /var/www/html/pub

# Replace the self-signed certificates created by Spacewalk with links to the ones we want
cd /root/ssl-build/<hostname>/
mv server.crt server.crt.self-signed
mv server.key server.key.self-signed
ln -s /etc/letsencrypt/live/<fqdn>/fullchain.pem server.crt
ln -s /etc/letsencrypt/live/<fqdn>/privkey.pem server.key

# Replace the existing CA certificate with the Let’s Encrypt chain:
cp /root/ca-chain.pem /root/ssl-build/RHN-ORG-TRUSTED-SSL-CERT

# You should now be able to validate the certificate in-place using the same openssl command we used before
openssl verify -CAfile /root/ssl-build/RHN-ORG-TRUSTED-SSL-CERT /root/ssl-build/<hostname>/server.crt

# We need to add the CA certificate to the Spacewalk database so that it is automatically installed on provisioned systems during kickstart
rhn-ssl-dbstore -v --ca-cert=/root/ssl-build/RHN-ORG-TRUSTED-SSL-CERT

# Generate the web server SSL package
rhn-ssl-tool --gen-server --rpm-only --dir /root/ssl-build

# Then install it
rpm -Uvh /root/ssl-build/swksvr/rhn-org-httpd-ssl-key-pair-spacewalk-1.0-rev.noarch.rpm

# Generate the CA certificate package
rhn-ssl-tool --gen-ca --dir=/root/ssl-build --rpm-only


# We need to copy the CA certificate and the CA RPM to /var/www/html/pub so that they’re accessible to client machines
cp /root/ssl-build/rhn-org-trusted-ssl-cert-1.0-rev.noarch.rpm /var/www/html/pub
cp /root/ssl-build/RHN-ORG-TRUSTED-SSL-CERT /var/www/html/pub

# Create links in case we ever want to change
# First, move the old Apache/httpd certificates and keys out of the way
mv /etc/httpd/conf/ssl.key/server.key /etc/httpd/conf/ssl.key/server.key.self-signed
mv /etc/http/conf/ssl.crt/server.crt /etc/httpd/conf/ssl.crt/server.crt.self-signed

# Then, link the live Let’s Encrypt certificates in their place
ln -s /etc/letsencrypt/live/<fqdn>/privkey.pem /etc/httpd/conf/ssl.key/server.key
ln -s /etc/letsencrypt/live/<fqdn>/fullchain.pem /etc/http/conf/ssl.crt/server.crt

# Finally, move and link the jabberd certificate
mv /etc/pki/spacewalk/jabberd/server.pem /etc/pki/spacewalk/jabberd/server.pem.self-signed
ln -s /etc/letsencrypt/live/<fqdn>/fullchain.pem /etc/pki/spacewalk/jabberd/server.pem

spacewalk-service restart

# Install the updated CA on your clients
yum --noplugins -y localinstall http://spacewalk.domain.com/pub/rhn-org-trusted-ssl-cert-1.0-rev.noarch.rpm
# This will disable all plugins (including the Spacewalk client) to bypass the connection error.
# It will then grab the new RPM from your server and install it, replacing the old certificate. At this point, yum should resume working.
service osad restart
