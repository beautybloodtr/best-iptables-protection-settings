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
    # Network incoming TCP MIX//UDP PPS
    iptables -A INPUT -s 51.38.230.69 -j ACCEPT
    iptables -A INPUT -s 51.38.230.103 -j ACCEPT
    iptables -A INPUT -s 51.38.230.92 -j ACCEPT
    iptables -A INPUT -s 193.164.7.250 -j ACCEPT
    iptables -A INPUT -s 193.164.7.245 -j ACCEPT
    iptables -A INPUT -s 162.243.41.44 -j ACCEPT
    iptables -A INPUT -s 198.27.83.92 -j ACCEPT
    iptables -A INPUT -s 139.162.177.160 -j ACCEPT
    iptables -A INPUT -s 54.172.127.174 -j ACCEPT
    iptables -A INPUT -s 209.97.131.201 -j ACCEPT
    iptables -A INPUT -s 138.201.82.93 -j ACCEPT
    iptables -A INPUT -s 18.205.222.128 -j ACCEPT
    iptables -I INPUT -p tcp --syn --dport 25565 -m length --length 60 -m string --string "8@" -m limit --limit 20/s --algo bm -j ACCEPT
    iptables -I INPUT -p tcp --syn --dport 25565 -m length --length 60 -m string --string "8@" --algo bm -j DROP
    iptables -I INPUT -p tcp --syn --dport 25565 -m length --length 60 -m string --string "9" -m limit --limit 20/s --algo bm -j ACCEPT
    iptables -I INPUT -p tcp --syn --dport 25565 -m length --length 60 -m string --string "9" --algo bm -j DROP
    iptables -I INPUT -p tcp --syn --dport 25565 -m length --length 60 -m string --string "7d" -m limit --limit 20/s --algo bm -j ACCEPT
    iptables -I INPUT -p tcp --syn --dport 25565 -m length --length 60 -m string --string "7d" --algo bm -j DROP
    iptables -I INPUT -p udp --dport 25565 -j DROP
    iptables -A INPUT -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
    iptables -A INPUT -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN -j DROP
    iptables -A INPUT -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,PSH,URG -j DROP
    iptables -A INPUT -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,PSH,ACK,URG -j DROP
    iptables -A INPUT -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
    iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
    iptables -A INPUT -p tcp -m tcp --syn --tcp-option 8 --dport 25565 -j REJECT
    iptables -I INPUT -p tcp --syn --dport 25565 -m connlimit --connlimit-above 3 -j DROP 
    iptables -I INPUT -p tcp --dport 25565 -m state --state NEW -m limit --limit 50/s -j ACCEPT
    iptables --new-chain RATE-LIMIT
    iptables --append INPUT --match conntrack --ctstate NEW --jump RATE-LIMIT
    iptables --append RATE-LIMIT --match limit --limit 300/sec --limit-burst 20 --jump ACCEPT 
    iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP
    iptables -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP
    iptables-save > /etc/iptables/rules.v4

    # Limits TCP-based attacks
    iptables -A INPUT -p tcp --dport 25565 -m hashlimit --hashlimit-upto 50/min \
        --hashlimit-burst 500 --hashlimit-mode srcip --hashlimit-name http -j ACCEPT
    iptables-save > /etc/iptables/rules.v4

    # Network incoming UDP PPS
    iptables -A INPUT -i eth0 -p udp --sport 25565 -m limit --limit 1/s --limit-burst 1000 -j ACCEPT 
    iptables-save > /etc/iptables/rules.v4
}

# Apply iptables rules
set_iptables_rules

# Restart iptables service if on CentOS
if [ "$OS" == "centos" ]; then
    systemctl restart iptables
fi

echo "Installation and configuration completed."
echo "These settings have been configured and edited by BeautyBloodTR. Have a good use."
