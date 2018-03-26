#!/bin/bash

# Get a few of the basics
apt update; apt install procps vim wget unzip curl dnsutils jq -y

# Download the consul-template binary
echo "installing latest consul-template from hashicorp"
wget https://releases.hashicorp.com/consul-template/0.19.4/consul-template_0.19.4_linux_amd64.zip
unzip consul-template_0.19.4_linux_amd64.zip
mv consul-template /usr/local/bin/.
echo "...done"

# Grab the base64-encoded template and write it to disk.
# This is something you'd normally delegate to the consul client,
# (and would require an ACL token) but we're not installing it here.
echo "grabbing the nginx router template from consul..."
curl --silent consul-server:8500/v1/kv/nginx-router-template | jq .[].Value | cut -d'"' -f2 | base64 -d > nginx-router-template.tpl
echo "...done"

# Render the template and overwrite the default nginx config
echo "rendering nginx router template..."
consul-template -template "nginx-router-template.tpl:/etc/nginx/conf.d/default.conf" -once
echo "...done"

echo "starting nginx...."
exec nginx -g "daemon off;"

