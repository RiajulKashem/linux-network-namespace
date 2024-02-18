# Create two network namespace
sudo ip netns add nms1
sudo ip netns add nms2

#Make them up.
sudo ip netns exec nms1 ip link set lo up
sudo ip netns exec nms2 ip link set lo up

# create bridge network on the host
sudo ip link add br0 type bridge

# up the created bridge and check whether it is created and in UP/UNKNOWN state
sudo ip link set br0 up

# Configure IP to the bridge network
sudo ip addr add 192.168.1.1/24 dev br0

# check whether the ip is configured and also ping to ensure
sudo ip addr
ping -c 2 192.168.1.1

# Create two veth interface for two network netns, then attach to the bridge and netns

# For nms1
sudo ip link add veth0 type veth peer name ceth0
sudo ip link set veth0 master br0
sudo ip link set veth0 up 
sudo ip link set ceth0 netns nms1
sudo ip netns exec nms1 ip link set ceth0 up

# For nms2;
sudo ip link add veth1 type veth peer name ceth1
sudo ip link set veth1 master br0
sudo ip link set veth1 up
sudo ip link set ceth1 netns nms2
sudo ip netns exec nms2 ip link set ceth1 up

# add ip address to the netns veth interfaces
sudo ip netns exec nms1 ip addr add 192.168.1.10/24 dev ceth0
sudo ip netns exec nms2 ip addr add 192.168.1.11/24 dev ceth1

# Verify connectivity between two netns

# For nms1
sudo nsenter --net=/var/run/netns/nms1
ping -c 2 192.168.1.11
exit

# For nms2
sudo nsenter --net=/var/run/netns/nms2
ping -c 2 192.168.1.10
exit

# Connect to the Internet

# add default getway
sudo ip netns exec nms1 ip route add default via 192.168.1.1
sudo ip netns exec nms2 ip route add default via 192.168.1.1

#check ping from nms1 to host IP (eth0)
sudo ip netns exec nms1 ping -c 2 192.168.184.131

# enabling ip forwarding by change value 0 to 1
sudo sysctl -w net.ipv4.ip_forward=1

# add iptables rule in the POSTROUTING chain of the nat table.
sudo iptables -t nat -A POSTROUTING  -s 192.168.1.0/24 ! -o br0  -j MASQUERADE

# define the destination
sudo iptables -t nat -A PREROUTING -d 192.168.184.131 -p tcp -m tcp --dport 3000 -j DNAT --to-destination 192.168.1.10:3000

# Now let's open a service in one of the namespaces and try to get response from the browser with URL http://192.168.1.10:3000
sudo nsenter --net=/var/run/netns/nms1
python3 -m http.server --bind 192.168.1.10 3000

