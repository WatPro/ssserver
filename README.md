## Run Shadowsocks Server on CentOS

Quick Setup for Shadowsocks Server 

```bash
bash COSrun.sh
```


## Run Shadowsocks Client on Raspbian

```bash
cat RASPrun.sh | sed "s/^SERVER_IP=.*$/SERVER_IP='10.10.10.1'/; s/^SERVER_PORT=.*$/SERVER_PORT='443'/; s/^PASSWORD=.*$/PASSWORD='password'/; s/^DEV=.*$/DEV='eth0'/" | sudo bash - 
```

