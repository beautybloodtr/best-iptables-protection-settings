#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "You must run this script as root."
    exit 1
fi

# Define your variables
BUNGEECORD_IP="127.0.0.1"  # BungeeCord IP address
START_PORT=25565  # Starting port
END_PORT=25575    # Ending port

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
    # Block all traffic to Minecraft server ports except from BungeeCord IP
    # This rule drops all incoming connections to the specified port range unless they are from the BungeeCord IP
    # Replace $BUNGEECORD_IP with the IP of the server running BungeeCord. If your Minecraft server(s) and BungeeCord are on the same physical server, this IP will be 127.0.0.1
    # Replace $START_PORT:$END_PORT with the port of your Minecraft server or a range of ports
    iptables -I INPUT ! -s $BUNGEECORD_IP -p tcp --dport $START_PORT:$END_PORT -j DROP

    # Create a new chain for port protection
    iptables -N port-protection
    iptables -A port-protection -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
    iptables -A port-protection -j DROP

    # Protect SSH port (port 22) from brute force attacks
    iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set
    iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 10 -j DROP

    # Save iptables rules
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
