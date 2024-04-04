echo ":-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:"
echo "User Data script is started at $(date) $(uptime) for $EC2_INSTANCE_ID"
echo ":-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:"

# To avoid DNS issues on instances using ENA (i.e. m5.*, c5.* and may be others)
# Inserting default gateway IP of Docker bridge network before default hardcoded universal IP of Amazon DNS,
#   so containers will first use DNS caching server from the host instance and use Amazon's resolver (which has rate limits that are too tight for our usage) only if internal DNS cache fails.
# Without this change, containers will have only default Amazon resolver inside them in /etc/resolv.conf because Docker removes `127.0.0.1` from that file since it doesn't make sense inside containers.
# /etc/resolv.dnsmasq still needs to have Amazon IP as an upstream server for proper resolution from the host itself
# This method work as long as Bridge networking is used by containers (see container definitions of your task definitions).
# WARNING: This has not been tested for awsvpc mode.
# Default Bridge networking name is usually docker0
DOCKER_BRIDGE_NAME=$(docker network inspect bridge --format='{{json .Options}}' | jq -r '."com.docker.network.bridge.name"')
echo "interface=$DOCKER_BRIDGE_NAME">>/etc/dnsmasq.conf
# Restarting dnsmasq to pick up changes and to listen on additional IP
systemctl restart dnsmasq.service

# Default IP of Docker Bridge networking / docker0 interface is usually 172.17.0.1  (CIDR is /16)
DOCKER_BRIDGE_IP=$(docker network inspect bridge --format='{{(index .IPAM.Config 0).Gateway}}')
sed -i -e "s/169.254.169.253/$DOCKER_BRIDGE_IP, 169.254.169.253/g" /etc/dhcp/dhclient.conf
sed -i -e "s/169.254.169.253/$DOCKER_BRIDGE_IP\nnameserver 169.254.169.253/g" /etc/resolv.conf


# In order to use EFS
#systemctl enable rpcbind.service
#systemctl enable nfs.service
#systemctl start rpcbind.service
#systemctl start nfs.service
#systemctl status rpcbind.service
#systemctl status nfs.service
#
## Mount Worker EFS:
#sudo mkdir /local/worker/
#echo "${efs_volume_id}.efs.us-east-1.amazonaws.com:/  /local/worker nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2" >> /etc/fstab
#mount -a
#ls -la /local/worker/


echo ":-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:"
echo "User Data script is finished at  $(date) $(uptime) for $EC2_INSTANCE_ID"
echo ":-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:"
