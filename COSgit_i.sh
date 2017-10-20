#!/bin/bash

################################################################################
##########     Install an up-to-date version of Git                   ##########
##########     on CentOS 7                                            ##########
################################################################################

yum -y install git
yum -y groupinstall "Development Tools" 
yum -y install openssl-devel libcurl-devel expat-devel perl-devel 
cd /usr/ 
git clone https://github.com/git/git
cd git
make 
make prefix=/usr install

git --version

git config --global user.name "Water Pro"
git config --global user.email 31579668+WatPro@users.noreply.github.com