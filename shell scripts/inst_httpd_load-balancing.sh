#!/bin/bash
apt update -y
apt install apache2 -y
systemctl start apache2
systemctl enable apache2

# Simple page with hostname
echo "<h1>Server: $(hostname)</h1>" > /var/www/html/index.html
echo "<h2>Instance ID: $(ec2-metadata --instance-id | cut -d ' ' -f 2)</h2>" >> /var/www/html/index.html
echo "<h2>Private IP: $(ec2-metadata --local-ipv4 | cut -d ' ' -f 2)</h2>" >> /var/www/html/index.html
