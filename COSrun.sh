#!/bin/bash 

################################################################################
##########     Run Shadowsocks Server                                 ##########
##########     Tested on CentOS 7                                     ##########
################################################################################

CONFIG_FILE=/etc/shadowsocks.json
CONFIG_XML=./ssserver.xml

cat << END_OF_FILE > $CONFIG_FILE
{
    "server": "0.0.0.0",
    "port_password": {
         "443": "password",
        "8381": "foobar1",
        "8382": "foobar2",
        "8383": "foobar3",
        "8384": "foobar4"
    },
    "timeout": 300,
    "method": "aes-256-cfb"
}                                 
END_OF_FILE

cat << EOF > $CONFIG_XML
<?xml version="1.0" encoding="utf-8"?>
<service>
    <short>SSServer</short>
    <description>Shadowsocks Server: TCP and UDP ports.</description>
EOF
cat $CONFIG_FILE | sed -rn \
's/.*"([0-9]+)": .*/    <port port="\1" protocol="tcp"\/> \
    <port port="\1" protocol="udp"\/> /p' >> $CONFIG_XML
cat << EOF >> $CONFIG_XML
</service>
EOF



if [ running = "$(firewall-cmd --state)" ]
then
    
FOUND_SS=$(firewall-cmd --permanent --get-services | grep --only-matching ssserver)
if [ ssserver = $FOUND_SS ]
then
    echo Deleting Old Port Settings
    firewall-cmd --permanent --delete-service=ssserver
fi
firewall-cmd --permanent --new-service-from-file=$CONFIG_XML --name=ssserver
firewall-cmd --permanent --add-service=ssserver
firewall-cmd --permanent --list-services
firewall-cmd --info-service=ssserver
firewall-cmd --reload

fi

rm -r $CONFIG_XML

if [ -e /var/run/shadowsocks.pid ] 
then 
    ssserver -c $CONFIG_FILE -d restart
else
    ssserver -c $CONFIG_FILE -d start
fi
