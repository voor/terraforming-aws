#!/bin/bash
set -eux

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
export DEBIAN_FRONTEND=noninteractive 
add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
apt update
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    docker-ce

mkdir -p /etc/squid4/certificates/ /var/cache/squid4 

cat > /etc/systemd/system/squid4.service << '_END'
[Unit]
Description=Squid4 Docker Container
Documentation=http://wiki.squid.org
After=network.target docker.service
Requires=docker.service

[Service]
ExecStartPre=-/usr/bin/docker kill squid4
ExecStartPre=-/usr/bin/docker rm squid4
ExecStart=/usr/bin/docker run --net=host --rm \
    -v /var/cache/squid4:/var/cache/squid4 \
    -v /etc/ssl/certs:/etc/ssl/certs:ro \
    -v /etc/squid4/certificates/:/etc/squid4/certificates/ \
    -v /etc/squid4/squid.conf:/etc/squid4/squid.conf:ro \
    --name squid4 ${squid_docker_image}

[Install]
WantedBy=multi-user.target
_END
cat > /etc/ssl/certs/ca.pem <<'_END'
${ssl_ca_cert}
_END
cat > /etc/squid4/certificates/ca.key <<'_END'
${ssl_ca_private_key}
_END
cat > /etc/squid4/squid.conf <<'_END'
# Default all logs to stdout and stderr
logfile_rotate 0
access_log stdio:/dev/stdout combined
cache_store_log stdio:/dev/stdout
cache_log /dev/stderr
netdb_filename stdio:/var/cache/squid4/netdb.state

visible_hostname squid4

cache_dir aufs /var/cache/squid4 40000 16 256

maximum_object_size 1536 MB
cache_mem 128 MB

acl SSL port 443
acl CONNECT method CONNECT
http_access allow CONNECT SSL

acl Safe_ports port 80 #http
acl Safe_ports port 443 #https

http_access deny !Safe_ports


# Handling HTTPS requests
https_port 443 cert=/etc/ssl/certs/ca.pem key=/etc/squid4/certificates/ca.key ssl-bump intercept

ssl_bump bump all

# EC2 Instances
acl allowed_https_sites ssl::server_name ec2.us-east-2.amazonaws.com
acl allowed_https_sites ssl::server_name ec2.us-east-1.amazonaws.com
acl allowed_https_sites ssl::server_name ec2.us-west-1.amazonaws.com
acl allowed_https_sites ssl::server_name ec2.us-west-2.amazonaws.com
acl allowed_https_sites ssl::server_name ec2.us-gov-east-1.amazonaws.com
acl allowed_https_sites ssl::server_name ec2.us-gov-west-1.amazonaws.com

# Elastic Load Balancing
acl allowed_https_sites ssl::server_name elasticloadbalancing.us-east-2.amazonaws.com
acl allowed_https_sites ssl::server_name elasticloadbalancing.us-east-1.amazonaws.com
acl allowed_https_sites ssl::server_name elasticloadbalancing.us-west-1.amazonaws.com
acl allowed_https_sites ssl::server_name elasticloadbalancing.us-west-2.amazonaws.com
acl allowed_https_sites ssl::server_name elasticloadbalancing.us-gov-east-1.amazonaws.com
acl allowed_https_sites ssl::server_name elasticloadbalancing.us-gov-west-1.amazonaws.com

# IAM 
acl allowed_https_sites ssl::server_name iam.amazonaws.com
acl allowed_https_sites ssl::server_name iam.us-gov.amazonaws.com

http_access allow allowed_https_sites

http_port 80

# Handling HTTP requests
http_port 3129 intercept

_END
# \ tls-dh=/etc/ssl/certs/dhparam.pem

chmod 644 /etc/squid4/certificates/ca.key
chown 13:13 -R /etc/squid4 /var/cache/squid4
chmod 644 /etc/ssl/certs/ca.pem
chmod 644 /etc/systemd/system/squid4.service

# Ephemeral Diffie-Hellman
# openssl dhparam -outform PEM -out /etc/ssl/certs/dhparam.pem 4096

docker pull ${squid_docker_image}
systemctl daemon-reload
systemctl enable squid4
systemctl start squid4
systemctl status squid4
EOF