#!/bin/bash

SERVER_IP='server_ip'
SERVER_PORT='8388'
PASSWORD='password'
DEV='eth0'
LOCALHOST=`ip address show lo | sed --silent 's/^.*inet \([0-9\.]\+\).*$/\1/p'`
LAN_ADDRESS=`ip address show ${DEV} | sed --silent 's/^.*inet \([0-9\.]\+\(\/[0-9]\+\)\?\).*$/\1/p' | head --lines=1`
 
SS_REDIR=`which ss-redir | head --lines=1`
if [ ! -n "$SS_REDIR" ]
then
   sudo apt-get --assume-yes install shadowsocks-libev 
fi
SS_REDIR=`which ss-redir | head --lines=1`
if [ ! -n "$SS_REDIR" ]
then
   exit 1 
fi

SS_CONFIG='/etc/config/shadowsocks.json'
sudo mkdir --parents "${SS_CONFIG%/*}/"
sudo touch ${SS_CONFIG} 
sudo chmod a+w ${SS_CONFIG} 
sudo cat <<END_OF_FILE > ${SS_CONFIG} 
{
    "server":"${SERVER_IP}",
    "server_port":${SERVER_PORT},
    "local_address":"0.0.0.0",
    "local_port":1080,
    "password":"${PASSWORD}",
    "timeout":300,
    "method":"aes-256-cfb",
    "fast_open": false
}
END_OF_FILE

function delete_shadowsocks {
TABLE="$1"
if [ ! -n "$TABLE" ] 
then
    return
fi
while true
do
DELETE_RULE=`sudo iptables --table ${TABLE} --list-rules | grep '^\-A.*SHADOWSOCKS.*$' | tail --lines=1 | sed 's/^\-A\(.*SHADOWSOCKS.*\)$/-D\1/'`
if [ -n "$DELETE_RULE" ] 
then
    sudo iptables --table ${TABLE} ${DELETE_RULE}
else
    break
fi
done
DELETE_RULE=`sudo iptables --table ${TABLE} --list-rules | grep '^.*SHADOWSOCKS$' | tail --lines=1`
if [ -n "$DELETE_RULE" ]
then
    sudo iptables --table ${TABLE} --delete-chain SHADOWSOCKS
fi
}

delete_shadowsocks nat
delete_shadowsocks mangle

sudo iptables --table nat --new SHADOWSOCKS
sudo iptables --table mangle --new SHADOWSOCKS
 
# Addresses to bypass the proxy 
sudo iptables --table nat --append SHADOWSOCKS --destination ${SERVER_IP} --jump RETURN
sudo iptables --table nat --append SHADOWSOCKS --destination ${LAN_ADDRESS} --jump RETURN
sudo iptables --table nat --append SHADOWSOCKS --destination 0.0.0.0/8 --jump RETURN
sudo iptables --table nat --append SHADOWSOCKS --destination 10.0.0.0/8 --jump RETURN
sudo iptables --table nat --append SHADOWSOCKS --destination 127.0.0.0/8 --jump RETURN
sudo iptables --table nat --append SHADOWSOCKS --destination 169.254.0.0/16 --jump RETURN
sudo iptables --table nat --append SHADOWSOCKS --destination 172.16.0.0/12 --jump RETURN
sudo iptables --table nat --append SHADOWSOCKS --destination 192.168.0.0/16 --jump RETURN
sudo iptables --table nat --append SHADOWSOCKS --destination 224.0.0.0/4 --jump RETURN
sudo iptables --table nat --append SHADOWSOCKS --destination 240.0.0.0/4 --jump RETURN
sudo iptables --table nat --append SHADOWSOCKS --protocol tcp --jump REDIRECT --to-ports 1080
sudo iptables --table nat --append OUTPUT --protocol tcp --jump SHADOWSOCKS
 
# Add any UDP rules
if [ ! -n "`ip route show table 100`" ] 
then
sudo ip route add local default dev lo table 100
fi
if [ ! -n "`ip rule | grep 'fwmark 0x1 lookup 100'`" ]
then
sudo ip rule add fwmark 0x1 lookup 100
fi
sudo iptables -t mangle --append SHADOWSOCKS --protocol udp --dport 53 --jump TPROXY --on-port 1080 --tproxy-mark 0x01/0x01

# Apply the rules
sudo iptables --table nat --append PREROUTING --protocol tcp --jump SHADOWSOCKS
sudo iptables --table mangle --append PREROUTING --jump SHADOWSOCKS

PID_FILE='/var/run/shadowsocks.pid'
if [ -f ${PID_FILE} ]
then
    sudo kill `cat ${PID_FILE}` 
    sudo rm --force "$PID_FILE"
fi

# Start the shadowsocks-redir
sudo ss-redir -u -c ${SS_CONFIG} -f "$PID_FILE" 

echo proxy is running: PID `cat ${PID_FILE}`
 
