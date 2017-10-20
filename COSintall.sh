#!/bin/bash

################################################################################
########## Install Shadowsocks Server                                 ##########
########## Tested on CentOS 7                                         ##########
################################################################################

yum -y install python-setuptools git && easy_install pip
pip install git+https://github.com/shadowsocks/shadowsocks.git@master
