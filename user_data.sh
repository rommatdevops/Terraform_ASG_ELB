#!/bin/bash
apt update -y
apt install apache2 -y

myip=`curl icanhazip.com`

cat <<EOF > /var/www/html/index.html
<html>
<body bgcolor="black>
<h2><font color="gold">Build by Power of Terraform</font> <font color="red">v.013</font></h2><br>
<h1 color="white">$myip</h1>
</body>
</html>
EOF

sudo service apache2 start
chkconfig apache2 on