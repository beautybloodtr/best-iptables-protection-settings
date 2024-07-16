#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "You must be root user to run this script."
    exit 1
fi

# Determine the OS and install packages accordingly
if [ -f /etc/redhat-release ]; then
    OS="centos"
    yum install epel-release -y
    yum install vnstat -y
    yum install iptables -y
elif [ -f /etc/debian_version ]; then
    OS="ubuntu"
    apt-get update
    apt-get install vnstat -y
    apt-get install iptables -y
else
    echo "This script only works on CentOS and Ubuntu."
    exit 1
fi

# Function to set iptables rules
set_iptables_rules() {
    local port=$1

    iptables -A INPUT -p tcp --dport $port -m hashlimit --hashlimit-upto 50/min \
        --hashlimit-burst 500 --hashlimit-mode srcip --hashlimit-name http -j ACCEPT

    iptables -I INPUT -p tcp --syn --dport $port -m connlimit --connlimit-above 4 -j DROP 
    iptables -I INPUT -p tcp --dport $port -m state --state NEW -m limit --limit 50/s -j ACCEPT
    iptables -A INPUT -p tcp --dport $port -m conntrack --ctstate NEW -m recent --set
    iptables -A INPUT -p tcp --dport $port -m conntrack --ctstate NEW -m recent --update --seconds 10 --hitcount 5 -j DROP

    iptables-save > /etc/iptables/rules.v4
}

# Apply iptables rules for HTTP and HTTPS
set_iptables_rules 80
set_iptables_rules 443

# Restart iptables service if on CentOS
if [ "$OS" == "centos" ]; then
    systemctl restart iptables
fi

echo "Installation and configuration completed."
echo "These settings have been configured and edited by BeautyBloodTR. Have a good use."
